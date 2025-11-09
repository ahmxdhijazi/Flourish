import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/plant_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createUserProfile({
    required String userId,
    required String displayName,
    File? profileImage,
  }) async {
    String? profileImageUrl;

    // Upload profile image if provided
    if (profileImage != null) {
      final storageRef =
          _storage.ref().child('user_profiles/$userId/profile.jpg');
      await storageRef.putFile(profileImage);
      profileImageUrl = await storageRef.getDownloadURL();
    }

    // Create user profile document
    await _firestore.collection('users').doc(userId).set({
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'plants': 0,
      'daysActive': 0,
      'favorites': [],
    });

    // Update Firebase Auth user profile
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.updateProfile(
        displayName: displayName,
        photoURL: profileImageUrl,
      );
      // Reload the user to ensure we have the latest data
      await currentUser.reload();
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> updatePlantCount(String userId) async {
    try {
      print("🔍 Starting updatePlantCount for userId: $userId");

      // Step 1: Fetch all plants with this userId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('plants')
          .where('userId', isEqualTo: userId)
          .get();

      print("📊 Found ${querySnapshot.docs.length} plants for userId: $userId");

      // Step 2: Log all plant IDs for verification
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          print("🌱 Plant ID: ${doc.id}, Data: ${doc.data()}");
        }
      } else {
        print(
            "⚠️ No plants found for this user. Check the 'userId' field in Firestore.");
      }

      // Step 3: Update user's plant count
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'plants': querySnapshot.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          "✅ Successfully updated plant count to ${querySnapshot.docs.length} for user $userId");
    } catch (e) {
      print("❌ Error updating plant count for user $userId: $e");
    }
  }

  // Add plant to favorites
  Future<void> addToFavorites(String userId, String plantId) async {
    print('UserService.addToFavorites - UserId: $userId, PlantId: $plantId');
    // Use set with merge to create favorites field if it doesn't exist
    await _firestore.collection('users').doc(userId).set({
      'favorites': FieldValue.arrayUnion([plantId]),
    }, SetOptions(merge: true));
    print('UserService.addToFavorites - Success');
  }

  // Remove plant from favorites
  Future<void> removeFromFavorites(String userId, String plantId) async {
    print(
        'UserService.removeFromFavorites - UserId: $userId, PlantId: $plantId');
    // Use set with merge to handle the case where favorites field might not exist
    await _firestore.collection('users').doc(userId).set({
      'favorites': FieldValue.arrayRemove([plantId]),
    }, SetOptions(merge: true));
    print('UserService.removeFromFavorites - Success');
  }

  // Check if plant is in favorites
  Future<bool> isFavorite(String userId, String plantId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return false;

    final favorites = data['favorites'] as List<dynamic>?;
    return favorites?.contains(plantId) ?? false;
  }

  // Get list of favorite plant IDs
  Future<List<String>> getFavorites(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return [];

    final favorites = data['favorites'] as List<dynamic>?;
    return favorites?.map((e) => e.toString()).toList() ?? [];
  }

  // Stream of favorite plant IDs
  Stream<List<String>> streamFavorites(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <String>[];

      final favorites = data['favorites'] as List<dynamic>?;
      return favorites?.map((e) => e.toString()).toList() ?? <String>[];
    });
  }
}
