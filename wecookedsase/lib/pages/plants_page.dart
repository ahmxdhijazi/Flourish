import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/calculateScores.dart';

class PlantsPage extends StatefulWidget {
  // Plant identification
  final String? plantId;
  final String plantName;
  final IconData plantIcon;
  final Color plantColor;
  
  // Plant stats
  final String plantDescription;
  final int plantLevel;
  final int plantXp;
  final double plantGrowthProgress;
  final double plantWaterLevel;
  final String plantSunlight;
  final DateTime plantLastWatered;
  final String plantCareInstructions;
  final DateTime plantCreatedAt;
  final DateTime plantUpdatedAt;

  const PlantsPage({
    super.key,
    this.plantId,
    required this.plantName,
    required this.plantIcon,
    required this.plantColor,
    required this.plantDescription,
    required this.plantLevel,
    required this.plantXp,
    required this.plantGrowthProgress,
    required this.plantWaterLevel,
    required this.plantSunlight,
    required this.plantLastWatered,
    required this.plantCareInstructions,
    required this.plantCreatedAt,
    required this.plantUpdatedAt,
  });

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  String? _todayImageUrl;
  bool _isLoadingImage = true;
  bool _hasImageToday = false;
  PlantAnalysisResult? _todayScores;
  bool _isLoadingScores = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayImage();
    _fetchTodayScores();
  }

  Future<void> _fetchTodayImage() async {
    if (widget.plantId == null) {
      setState(() {
        _isLoadingImage = false;
        _hasImageToday = false;
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingImage = false;
          _hasImageToday = false;
        });
        return;
      }

      // Get reference to the plant's folder
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_plants/${user.uid}/${widget.plantId}');

      // List all files in the folder
      final listResult = await storageRef.listAll();

      if (listResult.items.isEmpty) {
        setState(() {
          _isLoadingImage = false;
          _hasImageToday = false;
        });
        return;
      }

      // Get today's date in the format used in the filename
      final now = DateTime.now();
      final todayPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Find all images taken today and sort by timestamp (most recent first)
      final todayImages = listResult.items.where((item) {
        // Extract timestamp from filename: plant_2024-01-15T10:30:45.123.jpg
        final filename = item.name;
        return filename.startsWith('plant_$todayPrefix');
      }).toList();

      if (todayImages.isEmpty) {
        setState(() {
          _isLoadingImage = false;
          _hasImageToday = false;
        });
        return;
      }

      // Sort by filename (timestamp) in descending order to get most recent
      todayImages.sort((a, b) => b.name.compareTo(a.name));

      // Get the download URL for the most recent image
      final mostRecentImage = todayImages.first;
      final downloadUrl = await mostRecentImage.getDownloadURL();

      setState(() {
        _todayImageUrl = downloadUrl;
        _hasImageToday = true;
        _isLoadingImage = false;
      });
    } catch (e) {
      debugPrint('Error fetching today\'s image: $e');
      setState(() {
        _isLoadingImage = false;
        _hasImageToday = false;
      });
    }
  }

  Future<void> _fetchTodayScores() async {
    if (widget.plantId == null) {
      setState(() {
        _isLoadingScores = false;
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingScores = false;
        });
        return;
      }

      // Get today's date
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Query Firestore for today's analysis results
      final analysisSnapshot = await FirebaseFirestore.instance
          .collection('plant_analysis')
          .where('userId', isEqualTo: user.uid)
          .where('plantId', isEqualTo: widget.plantId)
          .where('timestamp', isGreaterThanOrEqualTo: todayStart)
          .where('timestamp', isLessThan: todayEnd)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (analysisSnapshot.docs.isNotEmpty) {
        final data = analysisSnapshot.docs.first.data();
        
        // Reconstruct PlantAnalysisResult from Firestore data
        final scores = PlantAnalysisResult(
          healthScore: (data['healthScore'] as num?)?.toDouble() ?? 0.0,
          growthScore: (data['growthScore'] as num?)?.toDouble() ?? 0.0,
          overallScore: (data['overallScore'] as num?)?.toDouble() ?? 0.0,
          stage: data['stage'] as String? ?? 'Unknown',
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
          recommendations: List<String>.from(data['recommendations'] as List? ?? []),
          rawData: data['rawData'] as Map<String, dynamic>? ?? {},
        );

        setState(() {
          _todayScores = scores;
          _isLoadingScores = false;
        });

        debugPrint('Loaded today\'s scores - Overall: ${scores.overallScore.toStringAsFixed(1)}');
      } else {
        setState(() {
          _isLoadingScores = false;
        });
        debugPrint('No analysis found for today');
      }
    } catch (e) {
      debugPrint('Error fetching today\'s scores: $e');
      setState(() {
        _isLoadingScores = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plantName,
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.plantColor,
                    widget.plantColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Display image or icon/message
                  _isLoadingImage
                      ? SizedBox(
                          width: 80.sp,
                          height: 80.sp,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : _hasImageToday && _todayImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: Image.network(
                                _todayImageUrl!,
                                width: 200.w,
                                height: 200.w,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: 200.w,
                                    height: 200.w,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80.sp,
                                    height: 80.sp,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      widget.plantIcon,
                                      size: 60.sp,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 200.w,
                              height: 200.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 60.sp,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'No photo today',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Take a photo to track growth!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.sp,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  SizedBox(height: 16.h),
                  Text(
                    widget.plantName,
                    style: GoogleFonts.poppins(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Level ${widget.plantLevel} • ${widget.plantXp} XP',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Plant Description
            if (widget.plantDescription.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.plantDescription,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),

            // Plant Stats
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plant Stats',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildStatRow('Growth Progress', '${(widget.plantGrowthProgress * 100).toStringAsFixed(0)}%', Icons.trending_up),
                  SizedBox(height: 12.h),
                  _buildStatRow('Water Level', '${(widget.plantWaterLevel * 100).toStringAsFixed(0)}%', Icons.water_drop),
                  SizedBox(height: 12.h),
                  _buildStatRow('Sunlight', widget.plantSunlight, Icons.wb_sunny),
                  SizedBox(height: 12.h),
                  _buildStatRow('Last Watered', _formatDate(widget.plantLastWatered), Icons.schedule),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Today's Analysis Scores
            if (_todayScores != null || _isLoadingScores)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Analysis',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _isLoadingScores
                        ? Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _todayScores != null
                            ? _buildScoresCard()
                            : Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        'No analysis yet today. Take a photo to get plant health insights!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),

            // Care Instructions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Care Instructions',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      widget.plantCareInstructions,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Water plant action
                      },
                      icon: const Icon(Icons.water_drop),
                      label: Text(
                        'Water Plant',
                        style: GoogleFonts.poppins(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Add note action
                      },
                      icon: const Icon(Icons.edit_note),
                      label: Text(
                        'Add Note',
                        style: GoogleFonts.poppins(fontSize: 14.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: widget.plantColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: widget.plantColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: widget.plantColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Widget _buildScoresCard() {
    if (_todayScores == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🌱 Overall Health',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: _getScoreColor(_todayScores!.overallScore),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: _getScoreColor(_todayScores!.overallScore).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_todayScores!.overallScore.toStringAsFixed(0)}/100',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Growth Stage
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(Icons.eco, size: 20.sp, color: Colors.green),
                SizedBox(width: 8.w),
                Text(
                  'Stage: ${_todayScores!.stage}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(_todayScores!.confidence * 100).toStringAsFixed(0)}% confident',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Health and Growth Mini Scores
          Row(
            children: [
              Expanded(
                child: _buildMiniScoreCard(
                  '💚 Health',
                  _todayScores!.healthScore,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildMiniScoreCard(
                  '📈 Growth',
                  _todayScores!.growthScore,
                ),
              ),
            ],
          ),
          
          // Recommendations
          if (_todayScores!.recommendations.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Divider(color: Colors.grey.shade300, thickness: 1),
            SizedBox(height: 12.h),
            Text(
              '💡 Recommendations:',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            ...(_todayScores!.recommendations.take(4).map(
              (rec) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rec,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniScoreCard(String label, double score) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            score.toStringAsFixed(0),
            style: GoogleFonts.poppins(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
        ],
      ),
    );
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
}
