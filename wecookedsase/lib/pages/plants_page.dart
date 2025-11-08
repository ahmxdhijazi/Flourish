import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantsPage extends StatelessWidget {
  final String plantName;
  final IconData plantIcon;
  final Color plantColor;

  const PlantsPage({
    super.key,
    required this.plantName,
    required this.plantIcon,
    required this.plantColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          plantName,
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
                    plantColor,
                    plantColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    plantIcon,
                    size: 80.sp,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    plantName,
                    style: GoogleFonts.poppins(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Level 5 • 150 XP',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

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
                  _buildStatRow('Growth Progress', '75%', Icons.trending_up),
                  SizedBox(height: 12.h),
                  _buildStatRow('Water Level', '90%', Icons.water_drop),
                  SizedBox(height: 12.h),
                  _buildStatRow('Sunlight', 'Optimal', Icons.wb_sunny),
                  SizedBox(height: 12.h),
                  _buildStatRow('Last Watered', '2 hours ago', Icons.schedule),
                ],
              ),
            ),

            SizedBox(height: 24.h),

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
                      'This plant needs regular watering and moderate sunlight. '
                      'Keep the soil moist but not waterlogged. '
                      'Fertilize monthly during growing season.',
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
              color: plantColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: plantColor,
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
              color: plantColor,
            ),
          ),
        ],
      ),
    );
  }
}
