import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_model.dart';
import '../pages/plants_page.dart';
import '../utils/calculateScores.dart';

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
          builder: (context) => DisplayPictureScreen(
            imagePath: image.path,
            plantId: widget.plantId,
            plantName: widget.plantName,
          ),
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
  final String? plantId;
  final String? plantName;
  
  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    this.plantId,
    this.plantName,
  });

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool _isUploading = false;
  bool _uploadSuccess = false;
  String? _downloadUrl;
  String? _errorMessage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult; // Raw API response (kept for debugging)
  PlantAnalysisResult? _plantScores;

  Future<void> _saveScoresToFirestore(PlantAnalysisResult scores) async {
    if (widget.plantId == null) {
      debugPrint('Cannot save scores: plantId is null');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Cannot save scores: user not logged in');
        return;
      }

      debugPrint('Saving scores to Firestore...');
      debugPrint('  PlantId: ${widget.plantId}');
      debugPrint('  UserId: ${user.uid}');
      debugPrint('  Overall Score: ${scores.overallScore}');
      debugPrint('  Health Score: ${scores.healthScore}');
      debugPrint('  Growth Score: ${scores.growthScore}');
      debugPrint('  Stage: ${scores.stage}');

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance.collection('plant_analysis').add({
        'userId': user.uid,
        'plantId': widget.plantId,
        'timestamp': DateTime.now(),
        'healthScore': scores.healthScore,
        'growthScore': scores.growthScore,
        'overallScore': scores.overallScore,
        'stage': scores.stage,
        'confidence': scores.confidence,
        'recommendations': scores.recommendations,
        'rawData': scores.rawData,
      });

      debugPrint('Scores saved to Firestore successfully! Doc ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error saving scores to Firestore: $e');
    }
  }

  Future<void> _callBackendAPI(String imageUrl) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Backend host. Provide your own at build/run time with:
      //   flutter run --dart-define=BACKEND_HOST=<host:port>
      // Do not commit machine-specific or public IP addresses here.
      const String backendHost =
          String.fromEnvironment('BACKEND_HOST', defaultValue: 'localhost:5000');

      String baseUrl = backendHost;
      if (Platform.isAndroid && backendHost == 'localhost:5000') {
        baseUrl = '10.0.2.2:5000'; // Android emulator -> host loopback
      }
      
      final apiUrl = 'http://$baseUrl/analyze-dual-model';
      
      debugPrint('=== Starting Backend API Call ===');
      debugPrint('Image URL: $imageUrl');
      debugPrint('API Endpoint: $apiUrl');
      debugPrint('Platform: ${Platform.operatingSystem}');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageURL': imageUrl}),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timed out after 60 seconds');
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // Calculate plant scores from the API response
        final scores = PlantScoreCalculator.calculateScores(result);
        
        setState(() {
          _analysisResult = result;
          _plantScores = scores;
          _isAnalyzing = false;
        });

        debugPrint('=== Plant Scores ===');
        debugPrint('Overall Score: ${scores.overallScore.toStringAsFixed(1)}');
        debugPrint('Health Score: ${scores.healthScore.toStringAsFixed(1)}');
        debugPrint('Growth Score: ${scores.growthScore.toStringAsFixed(1)}');
        debugPrint('Stage: ${scores.stage}');
        debugPrint('Recommendations: ${scores.recommendations.length}');

        // Save scores to Firestore
        await _saveScoresToFirestore(scores);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Analysis complete! Score: ${scores.overallScore.toStringAsFixed(0)}/100'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Wait a moment for user to see the success message, then navigate to plant page
          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted && widget.plantId != null) {
              try {
                // Fetch the plant data from Firestore
                final plantDoc = await FirebaseFirestore.instance
                    .collection('plants')
                    .doc(widget.plantId)
                    .get();
                
                if (plantDoc.exists && mounted) {
                  final plant = Plant.fromFirestore(plantDoc);
                  
                  // Pop all camera screens back to homepage
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  
                  // Navigate to the plant page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantsPage(
                        plantId: plant.id,
                        plantName: plant.name,
                        plantIcon: Icons.local_florist,
                        plantColor: Color(int.parse(plant.colorHex.replaceFirst('#', '0xFF'))),
                        plantDescription: plant.description,
                        plantLevel: plant.level,
                        plantXp: plant.xp,
                        plantGrowthProgress: plant.growthProgress,
                        plantWaterLevel: plant.waterLevel,
                        plantSunlight: plant.sunlight,
                        plantLastWatered: plant.lastWatered,
                        plantCareInstructions: plant.careInstructions,
                        latestImageUrl: plant.latestImageUrl,
                        plantCreatedAt: plant.createdAt,
                        plantUpdatedAt: plant.updatedAt,
                      ),
                    ),
                  );
                } else if (mounted) {
                  // Plant not found, just go back to homepage
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                debugPrint('Error fetching plant data: $e');
                if (mounted) {
                  // On error, just go back to homepage
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            } else if (mounted) {
              // No plantId, just go back to homepage
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      } else {
        throw Exception('API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('=== Backend API Error ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

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
      final timestamp = DateTime.now();
      final fileName = 'plant_${timestamp.toIso8601String()}.jpg';
      
      // Create reference to Firebase Storage location
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_plants/${user.uid}/${widget.plantId}/$fileName');

      // Upload the file
      final uploadTask = await storageRef.putFile(File(widget.imagePath));
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
        _uploadSuccess = true;
        _downloadUrl = downloadUrl;
      });

      // Update the plant's latestImageUrl in Firestore
      if (widget.plantId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('plants')
              .doc(widget.plantId)
              .update({
            'latestImageUrl': downloadUrl,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
          debugPrint('Updated plant latestImageUrl in Firestore');
        } catch (e) {
          debugPrint('Failed to update plant latestImageUrl: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully! Analyzing...'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Call backend API with the download URL
      await _callBackendAPI(downloadUrl);
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

  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
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
                    child: Column(
                      children: [
                        const Text(
                          'Uploaded successfully!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isAnalyzing)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Analyzing image...'),
                              ],
                            ),
                          ),
                        if (_plantScores != null && !_isAnalyzing)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade300, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(_plantScores!.overallScore),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Analysis Complete!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Score: ${_plantScores!.overallScore.toStringAsFixed(0)}/100 • ${_plantScores!.stage}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
