# User Authentication & Plant Data System Guide

## How It Works

### Overview
Your app now implements a complete user authentication system where each user's plants are stored separately and only visible to them after signing in through Firebase Authentication.

---

## System Architecture

### 1. **Authentication Flow**

#### On App Launch:
```
App Start → AuthWrapper checks Firebase Auth State
   ├─ User Logged In? → Show MainNavigation (Home, Leaderboard, Garden, Profile)
   └─ User Not Logged In? → Show LoginScreen
```

#### Key Components:
- **`AuthWrapper`** (in `main.dart`): 
  - Listens to Firebase Authentication state changes
  - Automatically redirects users based on login status
  - Shows loading indicator while checking auth state

```dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.hasData) return MainNavigation();
    return LoginScreen();
  }
)
```

---

### 2. **User-Specific Plant Data**

#### How Plants Are Tied to Users:

**When a plant is created:**
```dart
await _plantService.addPlant(
  Plant(name: 'Tomato', description: '...'),
  _userId!  // ← Current user's unique ID from Firebase Auth
);
```

**Firebase stores it like this:**
```json
{
  "plants": {
    "plant123": {
      "name": "Tomato",
      "description": "A fresh tomato plant",
      "userId": "abc123xyz",  // ← Links plant to specific user
      "createdAt": "2025-11-08T10:30:00Z"
    }
  }
}
```

#### How Plants Are Retrieved:

**Firestore Query:**
```dart
Stream<List<Plant>> getUserPlants(String userId) {
  return _firestore
    .collection('plants')
    .where('userId', isEqualTo: userId)  // ← Only gets THIS user's plants
    .snapshots()
}
```

**In HomeScreen:**
```dart
String? get _userId => FirebaseAuth.instance.currentUser?.uid;

StreamBuilder<List<Plant>>(
  stream: _plantService.getUserPlants(_userId!),
  // Only shows plants where userId matches current user
)
```

---

## Complete User Journey

### **First-Time User:**
1. Opens app → Sees **LoginScreen**
2. Taps "Create Account" → Goes to **SignupScreen**
3. Enters email, password, confirms password → Taps "Create Account"
4. Firebase creates account with unique User ID (UID)
5. Redirected to **ProfileSetupScreen** to set display name
6. **AuthWrapper** detects login → Shows **MainNavigation**
7. User sees empty plant list (no plants created yet)
8. User taps "+" to add plants → Plants are saved with their UID

### **Returning User:**
1. Opens app → Sees **LoginScreen**
2. Enters credentials → Taps "Sign In"
3. Firebase validates credentials
4. **AuthWrapper** detects login → Shows **MainNavigation**
5. **HomeScreen** automatically fetches plants WHERE `userId == currentUser.uid`
6. User sees ONLY their own plants

---

## Security Features

### 1. **Data Isolation**
- Each user's `userId` (Firebase UID) is unique and unchangeable
- Plants are filtered by `userId` on EVERY query
- User A cannot see User B's plants (enforced by Firestore queries)

### 2. **Authentication State Management**
```dart
// In HomeScreen
if (_userId == null) {
  return Text('Please log in to view your plants');
}
```
- Prevents unauthorized access even if navigation fails
- Double-checks user is authenticated before showing data

### 3. **Automatic Logout Protection**
- If user signs out, `authStateChanges()` triggers immediately
- **AuthWrapper** detects logout → Returns to **LoginScreen**
- All user data is cleared from memory

---

## Database Structure

### Firestore Collection: `plants`
```
plants/
  ├─ plantId1/
  │   ├─ name: "Tomato"
  │   ├─ userId: "user123"      ← Links to Firebase Auth UID
  │   ├─ description: "..."
  │   ├─ level: 5
  │   ├─ colorHex: "#4CAF50"
  │   ├─ createdAt: Timestamp
  │   └─ updatedAt: Timestamp
  │
  ├─ plantId2/
  │   ├─ name: "Basil"
  │   ├─ userId: "user456"      ← Different user's plant
  │   └─ ...
  │
  └─ plantId3/
      ├─ name: "Carrot"
      ├─ userId: "user123"      ← Same as plantId1, same user
      └─ ...
```

**Query Examples:**
- User123 logs in → Sees plantId1 and plantId3 only
- User456 logs in → Sees plantId2 only
- No cross-user data leakage!

---

## Key Code Locations

### Main Authentication Logic:
- **`lib/main.dart`**: 
  - `AuthWrapper` class (lines ~55-80)
  - `_HomeScreenState._userId` getter (line ~182)

### User Sign-In/Sign-Up:
- **`lib/login.dart`**: Login screen and authentication
- **`lib/signup.dart`**: Account creation
- **`lib/auth.dart`**: Firebase Auth service methods

### Plant Data Management:
- **`lib/services/plant_service.dart`**: 
  - `getUserPlants(userId)` - Fetches user-specific plants
  - `addPlant(plant, userId)` - Creates plant with userId

### Profile & Logout:
- **`lib/profile.dart`**: Shows user info and sign-out button

---

## Testing the System

### Test User Isolation:
1. **Create User A:**
   - Sign up as `userA@test.com`
   - Add plants: "Tomato", "Basil"
   - Sign out

2. **Create User B:**
   - Sign up as `userB@test.com`
   - Add plants: "Carrot", "Lettuce"
   - **Verify:** You should NOT see Tomato or Basil

3. **Sign back in as User A:**
   - **Verify:** You see Tomato and Basil
   - **Verify:** You do NOT see Carrot or Lettuce

---

## Important Notes

### Current User ID Retrieval:
```dart
// This returns the currently authenticated user's unique ID
String? userId = FirebaseAuth.instance.currentUser?.uid;
```

### Why Use `!` (Non-null assertion)?
```dart
_plantService.getUserPlants(_userId!)
```
- We check `if (_userId == null)` earlier
- If code reaches this point, `_userId` is guaranteed to exist
- `!` tells Dart "I promise this won't be null"

### Automatic Updates:
- Uses `StreamBuilder` with Firebase streams
- When plants change in database → UI updates automatically
- Real-time sync across all user's devices

---

## Future Enhancements

### Recommended Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /plants/{plantId} {
      // Only allow users to read/write their own plants
      allow read, write: if request.auth != null 
                         && resource.data.userId == request.auth.uid;
      
      // Allow creating plants if authenticated
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

This adds **server-side security** to prevent malicious clients from bypassing the app's logic.

---

## Troubleshooting

### "No plants showing after login"
- Check Firebase Console → Firestore Database
- Verify plants have `userId` field matching your user's UID
- Check console for errors: `flutter run -v`

### "User stays logged in after closing app"
- This is INTENTIONAL behavior
- Firebase Auth persists login state
- To test fresh login, use Sign Out button

### "Can see other users' plants"
- Check plant creation code includes `userId` parameter
- Verify `getUserPlants()` uses `.where('userId', isEqualTo: userId)`
- Check Firestore data for correct `userId` values

---

## Summary

Your app now has:
- **Firebase Authentication** with email/password
- **Automatic login state detection** with AuthWrapper
- **User-specific plant data** (plants tied to user ID)
- **Data isolation** (users only see their own plants)
- **Persistent login** (stays logged in across app restarts)
- **Secure logout** (clears data and returns to login screen)

Each user's plants are completely separate, stored in Firestore with their unique `userId`, and only visible when they're logged in!
