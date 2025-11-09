import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart';
import '../services/friend_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _friendService = FriendService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadCurrentUserData() {
    final user = Auth().currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _confirmAccountDeletion(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This action cannot be undone. All your data will be permanently deleted. '
            'Are you sure you want to delete your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // Get password for reauthentication
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(passwordController.text),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (password == null || password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Auth().currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Reauthenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete account
      await user.delete();

      if (mounted) {
        // Pop all routes and go back to login
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          switch (e.code) {
            case 'wrong-password':
              _errorMessage = 'Incorrect password. Please try again.';
              break;
            case 'requires-recent-login':
              _errorMessage = 'Please enter your password to continue.';
              break;
            default:
              _errorMessage = 'Failed to delete account: ${e.message}';
          }
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Failed to delete account')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDisplayNameDialog(BuildContext context) async {
    final nameController =
        TextEditingController(text: _displayNameController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Display Name'),
          content: FTextField(
            controller: nameController,
            label: const Text('Display Name'),
            maxLines: 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = Auth().currentUser;
        if (user == null) {
          throw Exception('No user is currently signed in');
        }

        await user.updateDisplayName(result.trim());
        await user.reload();
        _displayNameController.text = result.trim();

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Display name updated successfully')),
          );
        }
      } catch (e) {
        debugPrint('Error updating display name: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to update display name: ${e.toString()}';
          });
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(_errorMessage!)),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showChangeEmailDialog(BuildContext context) async {
    final emailController = TextEditingController(text: _emailController.text);
    final passwordController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FTextField(
                controller: emailController,
                label: const Text('New Email'),
                maxLines: 1,
              ),
              16.h.heightBox,
              FTextField(
                controller: passwordController,
                label: const Text('Current Password'),
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
              onPressed: () => Navigator.pop(context, {
                'email': emailController.text,
                'password': passwordController.text,
              }),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = Auth().currentUser;
        if (user == null) {
          throw Exception('No user is currently signed in');
        }

        // Validate new email
        if (!result['email']!.contains('@') ||
            !result['email']!.contains('.')) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Please enter a valid email address',
          );
        }

        // Reauthenticate first
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: result['password']!,
        );
        await user.reauthenticateWithCredential(credential);

        // Update email directly with Firebase
        await user.verifyBeforeUpdateEmail(result['email']!.trim());

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
                content: Text(
                    'Verification email sent. Please check your new email and click the verification link to complete the change.')),
          );
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
        if (mounted) {
          setState(() {
            switch (e.code) {
              case 'wrong-password':
                _errorMessage = 'Current password is incorrect';
                break;
              case 'invalid-email':
                _errorMessage = 'Invalid email format';
                break;
              case 'email-already-in-use':
                _errorMessage = 'This email is already in use';
                break;
              default:
                _errorMessage = 'Failed to update email: ${e.message}';
            }
          });
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(_errorMessage!)),
          );
        }
      } catch (e) {
        debugPrint('Error updating email: $e');
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
          });
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(_errorMessage!)),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FTextField(
                controller: currentPasswordController,
                label: const Text('Current Password'),
                obscureText: true,
                maxLines: 1,
              ),
              8.h.heightBox,
              FTextField(
                controller: newPasswordController,
                label: const Text('New Password'),
                obscureText: true,
                maxLines: 1,
              ),
              8.h.heightBox,
              FTextField(
                controller: confirmPasswordController,
                label: const Text('Confirm New Password'),
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
              onPressed: () {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'currentPassword': currentPasswordController.text,
                  'newPassword': newPasswordController.text,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = Auth().currentUser;
        if (user == null) {
          throw Exception('No user is currently signed in');
        }

        // Validate new password
        if (result['newPassword']!.length < 6) {
          throw Exception('New password must be at least 6 characters long');
        }

        // Reauthenticate
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: result['currentPassword']!,
        );
        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(result['newPassword']!);

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
        if (mounted) {
          setState(() {
            switch (e.code) {
              case 'wrong-password':
                _errorMessage = 'Current password is incorrect';
                break;
              case 'requires-recent-login':
                _errorMessage =
                    'Please enter your current password to continue';
                break;
              default:
                _errorMessage = 'Failed to update password: ${e.message}';
            }
          });
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(_errorMessage!)),
          );
        }
      } catch (e) {
        debugPrint('Error updating password: $e');
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
          });
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(_errorMessage!)),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Account Settings",
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

              // Display Name Row
              FCard(
                child: ListTile(
                  title: const Text("Display Name"),
                  subtitle: Text(
                    _displayNameController.text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14.sp,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _isLoading
                        ? null
                        : () => _showDisplayNameDialog(context),
                  ),
                ),
              ),

              16.h.heightBox,

              // Email Row
              FCard(
                child: ListTile(
                  title: const Text("Email"),
                  subtitle: Text(
                    _emailController.text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14.sp,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _isLoading
                        ? null
                        : () => _showChangeEmailDialog(context),
                  ),
                ),
              ),

              16.h.heightBox,

              // Change Password Button
              FButton(
                label: const Text('Change Password'),
                prefix: const Icon(Icons.lock_outline),
                style: FButtonStyle.outline,
                onPress: _isLoading
                    ? null
                    : () => _showChangePasswordDialog(context),
              ),

              30.h.heightBox,

              Text(
                'Account',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Delete Account Button
              FButton(
                label: Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                prefix: const Icon(Icons.delete_outline, color: Colors.red),
                style: FButtonStyle.outline,
                onPress:
                    _isLoading ? null : () => _confirmAccountDeletion(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
