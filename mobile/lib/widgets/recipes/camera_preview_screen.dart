import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile/theme/colors.dart';
import 'package:path_provider/path_provider.dart';

class CameraPreviewScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraPreviewScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Initialize the camera asynchronously
  Future<void> _initializeCamera() async {
    try {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller.initialize().timeout(
            Duration(seconds: 10), // Timeout after 10 seconds
          );
      await _initializeControllerFuture;
    } catch (e) {
      print("Error during camera initialization: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;
      final XFile image = await _controller.takePicture();

      final directory = await getApplicationDocumentsDirectory();
      final savedImagePath =
          "${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
      final File savedImage = File(savedImagePath);
      await savedImage.writeAsBytes(await image.readAsBytes());

      // Pop the current screen and return the image path
      Navigator.pop(context, savedImagePath);
    } catch (e) {
      print("Error capturing image: $e");
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.chevron_left,
            size: 32,
            color: ColorPalette.offWhite,
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _captureImage,
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(20),
                        backgroundColor:
                            Colors.white, // Background color for the button
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.black, // Icon color
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Failed to initialize camera"));
          }
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: ColorPalette.offBlack,
              color: ColorPalette.offWhite,
            ),
          );
        },
      ),
    );
  }
}
