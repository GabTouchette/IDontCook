import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/pages/recipe_detail_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/recipe_form/camera_preview_screen.dart';
import 'package:mobile/api/ai_chatbot_api.dart';

class CameraCaptureWidget extends StatefulWidget {
  const CameraCaptureWidget({Key? key}) : super(key: key);

  @override
  _CameraCaptureWidgetState createState() => _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState extends State<CameraCaptureWidget> {
  File? _image;
  bool isLoading = false;

  Future<void> _takePicture() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print("No cameras available!");
      return;
    }
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPreviewScreen(camera: cameras.first),
      ),
    );

    if (imagePath != null) {
      setState(() {
        _image = File(imagePath);
      });
    }
  }

  Future<void> _sendImage() async {
    if (_image == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await AiChatbotApi().uploadRecipeImage(_image!);
      print(response);

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(
            recipe: Recipe.fromJson(response['response']),
          ),
        ),
      );
    } catch (e) {
      print("Error during API call: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load recipe. Please try again.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorPalette.offBlack,
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        "Capture Recipe Image",
        style: TextStyle(
          color: ColorPalette.offWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Please take a picture of the recipe so that we can translate it into the site. The clearer the image, the better the result!",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_image == null)
            ElevatedButton(
              onPressed: _takePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.offWhite,
              ),
              child: const Text(
                "Take Picture",
                style: TextStyle(
                  fontSize: 16,
                  color: ColorPalette.offBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else ...[
            Image.file(_image!, height: 350),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    "Retake",
                    style: TextStyle(
                        fontSize: 16,
                        color: ColorPalette.offBlack,
                        fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.offWhite,
                    iconColor: ColorPalette.offBlack,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _sendImage,
                  icon: const Icon(Icons.upload),
                  label: const Text(
                    "Send",
                    style: TextStyle(
                        fontSize: 16,
                        color: ColorPalette.offWhite,
                        fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.offBlack,
                    iconColor: ColorPalette.offWhite,
                  ),
                ),
              ],
            ),
          ],
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(
                color: ColorPalette.offWhite,
              ),
            ),
        ],
      ),
    );
  }
}
