import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _ready = false;
  XFile? _lastPicture;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      // back camera if available, else first
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (!(_controller?.value.isInitialized ?? false)) return;
    final file = await _controller!.takePicture();
    setState(() => _lastPicture = file);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved: ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          if (_lastPicture != null)
            Positioned(
              top: 50,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  // quick preview using Image.file on device; for web/emulator this is fine to omit
                  // you can swap to Image.memory if needed later
                  _lastPicture!.path,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          Positioned(
            bottom: 32,
            child: FloatingActionButton(
              onPressed: _capture,
              backgroundColor: Colors.green[600],
              child: const Icon(Icons.camera_alt, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
