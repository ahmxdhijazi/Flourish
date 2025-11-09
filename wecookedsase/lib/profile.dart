import 'dart:io';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'pages/account_settings.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'auth.dart';
import 'login.dart';
import 'services/user_service.dart';

// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _showImagePickerOptions(BuildContext context, User user) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(context, ImageSource.camera, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(context, ImageSource.gallery, user);
                },
              ),
              if (user.photoURL != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove photo', 
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _removePhoto(context, user);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source, User user) async {
    try {
      setState(() => _isLoading = true);
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _userService.createUserProfile(
          userId: user.uid,
          displayName: user.displayName ?? "Anonymous User",
          profileImage: File(pickedFile.path),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removePhoto(BuildContext context, User user) async {
    try {
      setState(() => _isLoading = true);
      await _userService.createUserProfile(
        userId: user.uid,
        displayName: user.displayName ?? "Anonymous User",
        profileImage: null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      body: RefreshIndicator(
        onRefresh: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          try {
            await Auth().refreshUser();
            // Also refresh Firestore data if needed
            final userDoc = await _userService.getUserProfile(user.uid);
            if (userDoc != null && mounted) {
              setState(() {
                // Any local state updates if needed
              });
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to refresh: ${e.toString()}'),
                ),
              );
            }
          }
        },
        color: Colors.deepPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              30.h.heightBox,
        
              // Profile Info Section
              Center(
          child: Column(
            children: [
              // Profile Avatar
              GestureDetector(
                onTap: _isLoading ? null : () => _showImagePickerOptions(context, user),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: user.photoURL != null 
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepPurple.withOpacity(0.7),
                              ),
                            )
                          : user.photoURL == null
                              ? Icon(
                                  Icons.person,
                                  size: 50.r,
                                  color: Colors.grey.shade400,
                                )
                              : null,
                    ),
                    if (!_isLoading)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: const BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              16.h.heightBox,
              
              Text(
                user.displayName ?? "Anonymous User",
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                user.email ?? "",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              8.h.heightBox,
              if (!user.emailVerified) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16.sp,
                      color: Colors.orange,
                    ),
                    4.w.widthBox,
                    Text(
                      'Email not verified',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                8.h.heightBox,
                TextButton(
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await Auth().sendEmailVerification();
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Verification email sent'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Failed to send verification email. Please try again later.'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Resend verification email',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                8.h.heightBox,
                TextButton(
                  onPressed: () async {
                    final newEmail = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        final emailController = TextEditingController();
                        return AlertDialog(
                          title: const Text('Change Email'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Enter your new email address. You will need to verify the new email before the change takes effect.',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              FTextField(
                                controller: emailController,
                                label: const Text('New Email'),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, emailController.text.trim()),
                              child: const Text('Change'),
                            ),
                          ],
                        );
                      },
                    );

                    if (newEmail != null && newEmail.isNotEmpty && mounted) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        await Auth().updateEmail(newEmail);
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Verification email sent to new address. Please check your email to complete the change.',
                              ),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'requires-recent-login' && mounted) {
                          // Show reauthentication dialog
                          final password = await showDialog<String>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              final passwordController = TextEditingController();
                              return AlertDialog(
                                title: const Text('Confirm Password'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'For security reasons, please enter your password to continue.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 16),
                                    FTextField(
                                      controller: passwordController,
                                      label: const Text('Password'),
                                      obscureText: true,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, passwordController.text),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (password != null && password.isNotEmpty && mounted) {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            try {
                              // Reauthenticate and retry email update
                              await Auth().reauthenticateWithPassword(password);
                              await Auth().updateEmail(newEmail);
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Verification email sent to new address. Please check your email to complete the change.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e is FirebaseAuthException && e.code == 'wrong-password'
                                          ? 'Incorrect password. Please try again.'
                                          : 'Failed to change email: ${e.toString()}'
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        } else if (mounted) {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to change email: ${e.message}'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to change email: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    'Change email address',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ).px16(),
        
        30.h.heightBox,
        
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
                label: const Text('Account Settings'),
                prefix: const Icon(Icons.settings),
                style: FButtonStyle.outline,
                onPress: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen(),
                    ),
                  );
                },
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
            ],
          ),
        ),
      ),
    );
  }  Widget _buildUnauthenticatedProfile(BuildContext context) {
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
        child: VStack(
          [
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
          ],
          crossAlignment: CrossAxisAlignment.center,
        ).p16(),
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return VStack(
      [
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
      ],
      crossAlignment: CrossAxisAlignment.center,
    );
  }
}
