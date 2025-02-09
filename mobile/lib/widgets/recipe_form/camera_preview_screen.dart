import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
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
                  child: IconButton(
                    icon: Icon(Icons.camera, size: 60, color: Colors.white),
                    onPressed: _isCapturing ? null : _captureImage,
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
