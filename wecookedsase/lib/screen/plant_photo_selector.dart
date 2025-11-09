import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/plant_service.dart';
import '../models/plant_model.dart';
import 'camera_screen.dart';

class PlantPhotoSelector extends StatefulWidget {
  const PlantPhotoSelector({super.key});

  @override
  State<PlantPhotoSelector> createState() => _PlantPhotoSelectorState();
}

class _PlantPhotoSelectorState extends State<PlantPhotoSelector> {
  final PlantService _plantService = PlantService();
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Select Plant',
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to take plant photos'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Plant to Photograph',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Plant>>(
        stream: _plantService.getUserPlants(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading plants',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${snapshot.error}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 80.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No plants yet!',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Add a plant first before taking photos',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(
                      'Go Back',
                      style: GoogleFonts.poppins(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final plants = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              final color = Color(
                int.parse(plant.colorHex.replaceFirst('#', '0xFF')),
              );
              
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: InkWell(
                  onTap: () {
                    // Navigate to camera with plant context
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraScreen(
                          plantId: plant.id,
                          plantName: plant.name,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        // Plant Icon
                        Container(
                          width: 70.w,
                          height: 70.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color,
                                color.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.local_florist,
                            size: 36.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        
                        // Plant Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Level ${plant.level} • ${plant.xp} XP',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.water_drop,
                                    size: 14.sp,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${(plant.waterLevel * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Icon(
                                    Icons.wb_sunny,
                                    size: 14.sp,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    plant.sunlight,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Camera Icon
                        Icon(
                          Icons.camera_alt,
                          size: 28.sp,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
