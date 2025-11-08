import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: VStack([
        20.h.heightBox,
        
        // Profile Avatar
        CircleAvatar(
          radius: 50.r,
          backgroundImage: const NetworkImage('https://via.placeholder.com/150'),
        ),
        
        10.h.heightBox,
        
        Text(
          "John Doe",
          style: GoogleFonts.poppins(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Food Enthusiast",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14.sp,
          ),
        ),
        
        30.h.heightBox,
        
        // Stats Section
        FCard(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("32", "Recipes"),
                _buildStatCard("128", "Followers"),
                _buildStatCard("256", "Following"),
              ],
            ),
          ),
        ).px(16.w),
        
        30.h.heightBox,
        
        // Menu Items
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              FButton(
                label: const Text('Settings'),
                prefix: const Icon(Icons.settings),
                style: FButtonStyle.outline,
                onPress: () {},
              ),
              SizedBox(height: 12.h),
              FButton(
                label: const Text('Notifications'),
                prefix: const Icon(Icons.notifications),
                style: FButtonStyle.outline,
                onPress: () {},
              ),
              SizedBox(height: 12.h),
              FButton(
                label: const Text('Help & Support'),
                prefix: const Icon(Icons.help),
                style: FButtonStyle.outline,
                onPress: () {},
              ),
              SizedBox(height: 12.h),
              FButton(
                label: const Text('Logout'),
                prefix: const Icon(Icons.logout),
                style: FButtonStyle.outline,
                onPress: () {},
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ]).scrollVertical(),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return VStack([
      Text(
        number,
        style: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12.sp,
        ),
      ),
    ], crossAlignment: CrossAxisAlignment.center);
  }
}
