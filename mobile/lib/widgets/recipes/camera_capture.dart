import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/recipes/camera_preview_screen.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

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
      InformationToast.show(
        context: context,
        message: "No cameras available!",
        type: ToastType.error,
      );
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
      InformationToast.show(
        context: context,
        message: "Failed to load recipe. Please try again.",
        type: ToastType.error,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        "Digitize a Recipe",
        style: GoogleFonts.nunito(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Please take a picture of the recipe so that we can digitize it. The clearer the image, the better the result!",
            style: GoogleFonts.nunito(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_image == null)
            ElevatedButton(
              onPressed: _takePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Take Picture",
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
                  icon: Icon(Icons.refresh),
                  label: Text(
                    "Retake",
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _sendImage,
                  icon: Icon(Icons.upload),
                  label: Text(
                    "Send",
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ],
          if (isLoading)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
