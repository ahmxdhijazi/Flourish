import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import 'user_service.dart';

class PlantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'plants';
  final UserService _userService = UserService(); // <-- add this line

  // Get all plants for a user
  Stream<List<Plant>> getUserPlants(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Sort in memory instead of requiring a composite index
      final plants =
          snapshot.docs.map((doc) => Plant.fromFirestore(doc)).toList();
      plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return plants;
    });
  }

  // Get all plants (for testing/admin)
  Stream<List<Plant>> getAllPlants() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Plant.fromFirestore(doc)).toList());
  }

  // Get a single plant by ID
  Future<Plant?> getPlant(String plantId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(plantId).get();

      if (doc.exists) {
        return Plant.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting plant: $e');
      return null;
    }
  }

  // Add a new plant
  Future<String?> addPlant(Plant plant, String userId) async {
    try {
      print("🌱 Adding new plant for user $userId...");

      DocumentReference docRef = await _firestore.collection(_collection).add({
        ...plant.toFirestore(),
        'userId': userId,
      });

      print("✅ Plant added successfully with ID: ${docRef.id}");

      // Now update the user's plant count
      await _userService.updatePlantCount(userId);

      print("📊 User $userId plant count updated after adding plant.");

      return docRef.id;
    } catch (e) {
      print('❌ Error adding plant: $e');
      return null;
    }
  }

  // Update a plant
  Future<bool> updatePlant(Plant plant) async {
    try {
      if (plant.id == null) return false;

      await _firestore.collection(_collection).doc(plant.id!).update({
        ...plant.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating plant: $e');
      return false;
    }
  }

  // Water a plant (updates water level and last watered time)
  Future<bool> waterPlant(String plantId) async {
    try {
      await _firestore.collection(_collection).doc(plantId).update({
        'waterLevel': 1.0,
        'lastWatered': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error watering plant: $e');
      return false;
    }
  }

  // Add XP to a plant
  Future<bool> addXP(String plantId, int xpToAdd) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(plantId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int currentXP = data['xp'] ?? 0;
        int currentLevel = data['level'] ?? 1;
        int newXP = currentXP + xpToAdd;

        // Simple level up logic (every 100 XP = 1 level)
        int newLevel = currentLevel + (newXP ~/ 100);
        newXP = newXP % 100;

        await _firestore.collection(_collection).doc(plantId).update({
          'xp': newXP,
          'level': newLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding XP: $e');
      return false;
    }
  }

  // Delete a plant
  Future<bool> deletePlant(String plantId) async {
    try {
      await _firestore.collection(_collection).doc(plantId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting plant: $e');
      return false;
    }
  }

  // Create sample plants for testing
  Future<void> createSamplePlants(String userId) async {
    final samplePlants = [
      Plant(
        name: 'Tomato Plant',
        description: 'A healthy tomato plant',
        level: 3,
        xp: 45,
        growthProgress: 0.65,
        waterLevel: 0.80,
        iconName: 'local_florist',
        colorHex: '#FF5722',
        careInstructions:
            'Water daily and ensure plenty of sunlight. Fertilize weekly.',
      ),
      Plant(
        name: 'Basil',
        description: 'Fresh basil for cooking',
        level: 2,
        xp: 30,
        growthProgress: 0.45,
        waterLevel: 0.90,
        iconName: 'local_florist',
        colorHex: '#4CAF50',
        careInstructions: 'Keep soil moist. Prefers indirect sunlight.',
      ),
      Plant(
        name: 'Strawberry',
        description: 'Sweet strawberry plant',
        level: 4,
        xp: 75,
        growthProgress: 0.85,
        waterLevel: 0.70,
        iconName: 'local_florist',
        colorHex: '#E91E63',
        careInstructions: 'Water regularly. Needs full sun exposure.',
      ),
    ];

    for (var plant in samplePlants) {
      await addPlant(plant, userId);
    }
  }
}
