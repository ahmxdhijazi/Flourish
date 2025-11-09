import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'services/streak_service.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final _streakService = StreakService();
  
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();



  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to sign in user: $email');
      
      // Validate email and password
      if (email.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email address cannot be empty',
        );
      }
      
      if (password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-password',
          message: 'Password cannot be empty',
        );
      }

      // Attempt sign in
      try {
        await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(), 
          password: password,
        );
        debugPrint('Sign in successful for user: $email');
        // Check and update login streak after successful sign-in
        await _streakService.checkLoginStreak();
        debugPrint('Login streak checked/updated for user: $email');
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Exception during sign in:');
        debugPrint('Code: ${e.code}');
        debugPrint('Message: ${e.message}');
        throw FirebaseAuthException(
          code: e.code,
          message: e.message,
        );
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      if (e is! FirebaseAuthException) {
        // Convert other errors to FirebaseAuthException
        throw FirebaseAuthException(
          code: 'unknown',
          message: e.toString(),
        );
      }
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Starting user creation for email: $email');
      
      // Create the user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      debugPrint('User created successfully with UID: ${userCredential.user?.uid}');
      //await _streakService.checkLoginStreak();
      debugPrint('Login streak initialized for new user: $email');
      
      if (userCredential.user == null) {
        throw Exception('User creation successful but user is null');
      }
      
      // Wait a short moment to ensure Firebase is ready
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Waited for Firebase initialization');
      
      // Reload the user to ensure we have the latest data
      await userCredential.user!.reload();
      debugPrint('User reloaded after creation');
      
      // Get the latest user instance
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is null after reload');
      }
      
      // Print user state before sending verification
      debugPrint('User state before verification:');
      debugPrint('- Email: ${user.email}');
      debugPrint('- EmailVerified: ${user.emailVerified}');
      debugPrint('- isAnonymous: ${user.isAnonymous}');
      
      // Send verification email
      await user.sendEmailVerification();
      debugPrint('Verification email sent during account creation to ${user.email}');
      
      // Verify the action
      await user.reload();
      debugPrint('Final user state:');
      debugPrint('- EmailVerified: ${user.emailVerified}');
      debugPrint('- User metadata: Created at ${user.metadata.creationTime}');
      
    } catch (e, stackTrace) {
      debugPrint('Error during account creation or verification:');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      debugPrint('Starting manual verification email send process');
      
      // Get current user and reload to ensure we have latest data
      var user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      
      debugPrint('Current user state before reload:');
      debugPrint('- Email: ${user.email}');
      debugPrint('- EmailVerified: ${user.emailVerified}');
      debugPrint('- UID: ${user.uid}');
      
      // Reload user to get fresh data
      await user.reload();
      debugPrint('User reloaded');
      
      user = _firebaseAuth.currentUser; // Get fresh instance after reload
      
      if (user == null) {
        throw Exception('User is null after reload');
      }
      
      debugPrint('User state after reload:');
      debugPrint('- Email: ${user.email}');
      debugPrint('- EmailVerified: ${user.emailVerified}');
      
      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }

      // Ensure we're not sending too many verification emails
      final metadataTime = user.metadata.creationTime;
      if (metadataTime != null) {
        final timeSinceCreation = DateTime.now().difference(metadataTime);
        debugPrint('Time since account creation: ${timeSinceCreation.inSeconds} seconds');
        
        if (timeSinceCreation < const Duration(seconds: 5)) {
          debugPrint('Account recently created, adding small delay');
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      debugPrint('Attempting to send verification email');
      await user.sendEmailVerification();
      debugPrint('Verification email successfully sent to ${user.email}');
      
      // Final state check
      await user.reload();
      debugPrint('Final user state:');
      debugPrint('- EmailVerified: ${user.emailVerified}');
      
    } catch (e, stackTrace) {
      debugPrint('Error sending verification email:');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> refreshUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        debugPrint('User data refreshed successfully');
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      rethrow;
    }
  }

  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No user is currently signed in',
        );
      }

      // Create credentials
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Reauthenticate
      await user.reauthenticateWithCredential(credential);
      debugPrint('User successfully reauthenticated');
    } catch (e) {
      debugPrint('Error during reauthentication: $e');
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      debugPrint('Attempting to update email to: $newEmail');
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No user is currently signed in',
        );
      }

      try {
        await user.verifyBeforeUpdateEmail(newEmail);
        debugPrint('Verification email sent to new address: $newEmail');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          rethrow; // Let the UI handle the reauthentication flow
        }
        throw e;
      }
    } catch (e) {
      debugPrint('Error updating email: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('Attempting to send password reset email to: $email');
      
      if (email.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email address cannot be empty',
        );
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      debugPrint('Password reset email sent successfully to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception sending reset email:');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
}