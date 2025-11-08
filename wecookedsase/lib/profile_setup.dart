import 'dart:io';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _userService = UserService();
  File? _profileImage;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _completeSetup() async {
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userService.createUserProfile(
          userId: user.uid,
          displayName: _nameController.text,
          profileImage: _profileImage,
        );
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to complete profile setup. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Set Up Profile",
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
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              30.h.heightBox,
              
              // Profile Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60.r,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _profileImage != null 
                      ? FileImage(_profileImage!) 
                      : null,
                  child: _profileImage == null
                      ? Icon(
                          Icons.add_a_photo,
                          size: 40.sp,
                          color: Colors.grey.shade600,
                        )
                      : null,
                ),
              ),
              
              16.h.heightBox,
              
              Text(
                "Add Profile Picture",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              
              30.h.heightBox,

              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                20.h.heightBox,
              ],
              
              // Name field
              FTextField(
                controller: _nameController,
                label: const Text("Display Name"),
                enabled: !_isLoading,
              ),
              
              30.h.heightBox,
              
              // Complete button
              FButton(
                label: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Complete Setup'),
                style: FButtonStyle.outline,
                onPress: _isLoading ? null : _completeSetup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}