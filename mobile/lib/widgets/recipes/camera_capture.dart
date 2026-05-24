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
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      surfaceTintColor: Colors.transparent,
      backgroundColor: cs.surface,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outline, width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DIGITIZE A RECIPE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(
              "Take a picture of a recipe and we'll digitize it for you. The clearer the image, the better the result!",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (_image != null) ...[
              Image.file(_image!, height: 300),
              const SizedBox(height: 16),
            ],
            if (isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(
                    color: cs.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            Row(
              children: [
                if (_image != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _takePicture,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.onSurface,
                        side: BorderSide(color: cs.outlineVariant, width: 1),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'RETAKE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _sendImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'DIGITIZE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _takePicture,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'TAKE PICTURE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
