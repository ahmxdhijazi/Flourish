import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                FTextField(
                  controller: emailController,
                  label: const Text('Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await Auth().sendPasswordResetEmail(emailController.text.trim());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent. Please check your email.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = 'No account exists with this email address';
              break;
            case 'invalid-email':
              _errorMessage = 'Please enter a valid email address';
              break;
            default:
              _errorMessage = e.message ?? 'Failed to send reset email';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Basic validation
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter both email and password';
        });
        return;
      }

      await Auth().signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // No need to navigate - AuthWrapper will handle it automatically
      // when it detects the auth state change
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception details:');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      
      setState(() {
        switch (e.code.toLowerCase()) {
          case 'too-many-requests':
            _errorMessage = 'Too many unsuccessful attempts. Please try again later.';
            break;
          case 'network-request-failed':
            _errorMessage = 'Network error. Please check your internet connection.';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled. Please contact support.';
            break;
          default:
            // For most auth errors, just show a generic message
            _errorMessage = 'Invalid email or password.';
        }
      });
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
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

              12.h.heightBox,
              
              // Forgot password button
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _isLoading ? null : () => _showForgotPasswordDialog(context),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}