import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'login.dart';

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildAuthenticatedProfile(context, snapshot.data!);
        } else {
          return _buildUnauthenticatedProfile(context);
        }
      },
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, User user) {
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
          backgroundImage: const NetworkImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSfqwLFS00jntBFK3NiZMvuJZs8Uo3q1zOZVZ4rWNuJUgbpHBUKQmEBvSUSoDKJydUu-3MB&s'),
        ),
        
        10.h.heightBox,
        
          Text(
          user.displayName ?? "Anonymous User",
          style: GoogleFonts.poppins(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          user.email ?? "",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14.sp,
          ),
        ),        30.h.heightBox,
        
        // Stats Section
        FCard(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("15", "Plants"),
                _buildStatCard("8", "Gardens"),
                _buildStatCard("120", "Days Active"),
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
                label: const Text('My Plants'),
                prefix: const Icon(Icons.local_florist),
                style: FButtonStyle.outline,
                onPress: () {},
              ),
              SizedBox(height: 12.h),
              FButton(
                label: const Text('Garden Calendar'),
                prefix: const Icon(Icons.calendar_month),
                style: FButtonStyle.outline,
                onPress: () {},
              ),
              SizedBox(height: 12.h),
              FButton(
                label: const Text('Plant Care Tips'),
                prefix: const Icon(Icons.lightbulb_outline),
                style: FButtonStyle.outline,
                onPress: () {},
              ),
              SizedBox(height: 12.h),
              FButton(
                label: const Text('Logout'),
                prefix: const Icon(Icons.logout),
                style: FButtonStyle.outline,
                onPress: () async {
                  await Auth().signOut();
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ]).scrollVertical(),
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context) {
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
      body: Center(
        child: VStack([
          const Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.deepPurple,
          ),
          20.h.heightBox,
          Text(
            "Sign in to view your profile",
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          20.h.heightBox,
          FButton(
            label: const Text('Sign In'),
            style: FButtonStyle.outline,
            prefix: const Icon(Icons.login),
            onPress: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ]).p16(),
      ),
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
