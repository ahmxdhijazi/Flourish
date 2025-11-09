import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // We need this for date formatting

/**
 * This class holds all the logic for checking and updating the user's login streak.
 */
class StreakService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /**
   * Checks and updates the user's login streak.
   * This should be called once every time the app is opened.
   */
  Future<void> checkLoginStreak() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print("Streak Check: No user logged in.");
      return; // Not logged in
    }

    // 1. Get today's date in 'yyyy-MM-dd' format
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 2. Get the user's document
    final DocumentReference userRef =
        _firestore.collection('users').doc(user.uid);
    final DocumentSnapshot doc = await userRef.get();

    if (!doc.exists) {
      // 3. This is a new user or first login with streak logic
      print("Streak Check: New user. Creating streak fields.");
      await userRef.set({
        'streakCount': 1,
        'lastLoginDate': todayStr,
      }, SetOptions(merge: true)); // merge: true won't overwrite other user data
      return;
    }

    // 4. Get the data from the existing document
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    int currentStreak = data['streakCount'] ?? 0;
    String lastLoginStr = data['lastLoginDate'] ?? '';

    if (lastLoginStr.isEmpty) {
      // User exists but has no streak data yet
      print("Streak Check: User has no streak data. Starting new streak.");
      await userRef.update({
        'streakCount': 1,
        'lastLoginDate': todayStr,
      });
      return;
    }

    if (lastLoginStr == todayStr) {
      // User has already logged in today. Do nothing.
      print("Streak Check: Already logged in today. Current streak: $currentStreak");
      return;
    }

    // 5. Calculate the difference in days
    try {
      DateTime lastLoginDate = DateTime.parse(lastLoginStr);
      // Use UTC to avoid timezone issues messing up the "day" calculation
      DateTime todayDate = DateTime.parse(todayStr); 
      int dayDifference = todayDate.difference(lastLoginDate).inDays;

      // 6. Update the streak based on the logic
      if (dayDifference == 1) {
        // It's a consecutive day! Increment the streak.
        int newStreak = currentStreak + 1;
        print("Streak Check: Consecutive day! New streak: $newStreak");
        await userRef.update({
          'streakCount': newStreak,
          'lastLoginDate': todayStr,
        });
      } else if (dayDifference > 1) {
        // The streak is broken. Reset to 1.
        print("Streak Check: Streak broken. Resetting to 1.");
        await userRef.update({
          'streakCount': 1, // Set to 1, not 0 (today counts)
          'lastLoginDate': todayStr,
        });
      }
      // Note: if dayDifference is 0 or less, we already handled it.
    } catch (e) {
      print("Streak Check Error parsing date: $e. Resetting streak.");
      // Date format is wrong for some reason, let's just reset it
      await userRef.update({
        'streakCount': 1,
        'lastLoginDate': todayStr,
      });
    }
  }
}