import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/recipe_form/camera_preview_screen.dart';

class CameraCaptureWidget extends StatefulWidget {
  final Function(File) onImageCaptured;

  const CameraCaptureWidget({Key? key, required this.onImageCaptured})
      : super(key: key);

  @override
  _CameraCaptureWidgetState createState() => _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState extends State<CameraCaptureWidget> {
  File? _image;

  Future<void> _takePicture() async {
    print("Opening camera preview...");

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorPalette.offBlack,
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_image == null)
            ElevatedButton(
              onPressed: _takePicture,
              child: const Text("Take Picture"),
            )
          else ...[
            Image.file(_image!, height: 250),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => widget.onImageCaptured(_image!),
                  icon: const Icon(Icons.upload),
                  label: const Text("Send"),
                ),
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retake"),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
