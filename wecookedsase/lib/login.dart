import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Auth().signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(); // Return to previous screen after login
      }
    } catch (e) {
      setState(() {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = 'No user found with this email';
              break;
            case 'wrong-password':
              _errorMessage = 'Wrong password provided';
              break;
            case 'invalid-email':
              _errorMessage = 'Invalid email address';
              break;
            case 'user-disabled':
              _errorMessage = 'This account has been disabled';
              break;
            default:
              _errorMessage = 'Failed to sign in: ${e.message}';
          }
        } else {
          _errorMessage = 'An error occurred while signing in';
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
          "Sign In",
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
                "Welcome Back!",
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              10.h.heightBox,
              
              Text(
                "Sign in to grow your garden",
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
              
              20.h.heightBox,
              
              // Sign in button
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
                  : const Text('Sign In'),
                style: FButtonStyle.outline,
                onPress: _isLoading ? null : _signIn,
              ),
              
              20.h.heightBox,
              
              // Sign up section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14.sp,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              20.h.heightBox,
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      "or continue with",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              
              20.h.heightBox,
              
              // Social sign in buttons
              FButton(
                label: const Text('Sign in with Google'),
                prefix: const Icon(Icons.g_mobiledata),  // Using a Material icon as placeholder
                style: FButtonStyle.outline,
                onPress: () {
                  // TODO: Implement Google sign in
                },
              ),
              
              16.h.heightBox,
              
              FButton(
                label: const Text('Sign in with Apple'),
                prefix: const Icon(Icons.apple),
                style: FButtonStyle.outline,
                onPress: () {
                  // TODO: Implement Apple sign in
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}