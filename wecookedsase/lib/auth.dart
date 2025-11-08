import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();



  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to sign in user: $email');
      
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
        print('Sign in successful for user: $email');
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth Exception during sign in:');
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        throw FirebaseAuthException(
          code: e.code,
          message: e.message,
        );
      }
    } catch (e) {
      print('Sign in error: $e');
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
      print('Starting user creation for email: $email');
      
      // Create the user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      print('User created successfully with UID: ${userCredential.user?.uid}');
      
      if (userCredential.user == null) {
        throw Exception('User creation successful but user is null');
      }
      
      // Wait a short moment to ensure Firebase is ready
      await Future.delayed(const Duration(seconds: 1));
      print('Waited for Firebase initialization');
      
      // Reload the user to ensure we have the latest data
      await userCredential.user!.reload();
      print('User reloaded after creation');
      
      // Get the latest user instance
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is null after reload');
      }
      
      // Print user state before sending verification
      print('User state before verification:');
      print('- Email: ${user.email}');
      print('- EmailVerified: ${user.emailVerified}');
      print('- isAnonymous: ${user.isAnonymous}');
      
      // Send verification email
      await user.sendEmailVerification();
      print('Verification email sent during account creation to ${user.email}');
      
      // Verify the action
      await user.reload();
      print('Final user state:');
      print('- EmailVerified: ${user.emailVerified}');
      print('- User metadata: Created at ${user.metadata.creationTime}');
      
    } catch (e, stackTrace) {
      print('Error during account creation or verification:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      print('Starting manual verification email send process');
      
      // Get current user and reload to ensure we have latest data
      var user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      
      print('Current user state before reload:');
      print('- Email: ${user.email}');
      print('- EmailVerified: ${user.emailVerified}');
      print('- UID: ${user.uid}');
      
      // Reload user to get fresh data
      await user.reload();
      print('User reloaded');
      
      user = _firebaseAuth.currentUser; // Get fresh instance after reload
      
      if (user == null) {
        throw Exception('User is null after reload');
      }
      
      print('User state after reload:');
      print('- Email: ${user.email}');
      print('- EmailVerified: ${user.emailVerified}');
      
      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }

      // Ensure we're not sending too many verification emails
      final metadataTime = user.metadata.creationTime;
      if (metadataTime != null) {
        final timeSinceCreation = DateTime.now().difference(metadataTime);
        print('Time since account creation: ${timeSinceCreation.inSeconds} seconds');
        
        if (timeSinceCreation < const Duration(seconds: 5)) {
          print('Account recently created, adding small delay');
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      print('Attempting to send verification email');
      await user.sendEmailVerification();
      print('Verification email successfully sent to ${user.email}');
      
      // Final state check
      await user.reload();
      print('Final user state:');
      print('- EmailVerified: ${user.emailVerified}');
      
    } catch (e, stackTrace) {
      print('Error sending verification email:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
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
        print('User data refreshed successfully');
      }
    } catch (e) {
      print('Error refreshing user data: $e');
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
      print('User successfully reauthenticated');
    } catch (e) {
      print('Error during reauthentication: $e');
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      print('Attempting to update email to: $newEmail');
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No user is currently signed in',
        );
      }

      try {
        await user.verifyBeforeUpdateEmail(newEmail);
        print('Verification email sent to new address: $newEmail');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          rethrow; // Let the UI handle the reauthentication flow
        }
        throw e;
      }
    } catch (e) {
      print('Error updating email: $e');
      rethrow;
    }
  }
}