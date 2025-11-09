import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CameraScreen extends StatefulWidget {
  final String? plantId;
  final String? plantName;
  
  const CameraScreen({
    super.key,
    this.plantId,
    this.plantName,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      _controller = CameraController(firstCamera, ResolutionPreset.high);
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null) return;
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plantName != null 
          ? "Photo for ${widget.plantName}" 
          : "Camera"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool _isUploading = false;
  bool _uploadSuccess = false;
  String? _downloadUrl;
  String? _errorMessage;

  Future<void> _uploadImageToFirebase() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'plant_$timestamp.jpg';
      
      // Create reference to Firebase Storage location
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_plants/${user.uid}/tmp/$fileName');

      // Upload the file
      final uploadTask = await storageRef.putFile(File(widget.imagePath));
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
        _uploadSuccess = true;
        _downloadUrl = downloadUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadSuccess = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Captured Photo"),
        actions: [
          if (_uploadSuccess)
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(File(widget.imagePath)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_downloadUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Uploaded successfully!',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading || _uploadSuccess
                        ? null
                        : _uploadImageToFirebase,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(_uploadSuccess ? Icons.check : Icons.cloud_upload),
                    label: Text(
                      _isUploading
                          ? 'Uploading...'
                          : _uploadSuccess
                              ? 'Uploaded'
                              : 'Save to Firebase',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _uploadSuccess ? Colors.green : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
