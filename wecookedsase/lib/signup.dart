import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'profile_setup.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Auth().createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        // Navigate to profile setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
      }
    } catch (e) {
      setState(() {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'weak-password':
              _errorMessage = 'The password provided is too weak';
              break;
            case 'email-already-in-use':
              _errorMessage = 'An account already exists for this email';
              break;
            case 'invalid-email':
              _errorMessage = 'Invalid email address';
              break;
            case 'operation-not-allowed':
              _errorMessage = 'Email/password accounts are not enabled';
              break;
            default:
              _errorMessage = 'Failed to create account: ${e.message}';
          }
        } else {
          _errorMessage = 'An error occurred while creating your account';
        }
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
          "Create Account",
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
              
              // App Logo or Icon
              Icon(
                Icons.eco_rounded,
                size: 80.sp,
                color: Colors.deepPurple,
              ),
              
              20.h.heightBox,
              
              Text(
                "Join Our Garden!",
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              10.h.heightBox,
              
              Text(
                "Create an account to start your garden journey",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              
              30.h.heightBox,

              // Error message if any
              if (_errorMessage != null)
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

              if (_errorMessage != null) 20.h.heightBox,
              
              // Email field
              FTextField(
                controller: _emailController,
                label: const Text("Email"),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              
              16.h.heightBox,
              
              // Password field
              FTextField(
                controller: _passwordController,
                label: const Text("Password"),
                obscureText: true,
                enabled: !_isLoading,
                maxLines: 1,
              ),
              
              16.h.heightBox,
              
              // Confirm Password field
              FTextField(
                controller: _confirmPasswordController,
                label: const Text("Confirm Password"),
                obscureText: true,
                enabled: !_isLoading,
                maxLines: 1,
              ),
              
              20.h.heightBox,
              
              // Sign up button
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
                  : const Text('Create Account'),
                style: FButtonStyle.outline,
                onPress: _isLoading ? null : _signUp,
              ),
              
              20.h.heightBox,
              
              // Sign in section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14.sp,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Return to sign in screen
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}