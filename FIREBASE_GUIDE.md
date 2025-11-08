# Firebase Integration Guide for WeCooked Plant App

## Overview
This guide explains how the app fetches plant data from Firebase Firestore and displays it in real-time.

## Architecture

### 1. **Plant Model** (`lib/models/plant_model.dart`)
Represents a plant object with all its properties:
- `id`: Unique identifier
- `name`: Plant name
- `description`: Plant description
- `level`: Current level
- `xp`: Experience points
- `growthProgress`: 0.0 to 1.0 (0% to 100%)
- `waterLevel`: 0.0 to 1.0
- `sunlight`: String ("Optimal", "Low", "High")
- `lastWatered`: DateTime
- `iconName`: String for icon
- `colorHex`: Hex color string (e.g., "#FF5722")
- `careInstructions`: Care text
- `createdAt`, `updatedAt`: Timestamps

### 2. **Plant Service** (`lib/services/plant_service.dart`)
Handles all Firebase Firestore operations:

#### Methods:
- `getUserPlants(userId)`: Stream of user's plants (real-time updates)
- `getAllPlants()`: Stream of all plants
- `getPlant(plantId)`: Get single plant
- `addPlant(plant, userId)`: Add new plant
- `updatePlant(plant)`: Update existing plant
- `waterPlant(plantId)`: Update water level and last watered time
- `addXP(plantId, xpToAdd)`: Add XP with auto-leveling
- `deletePlant(plantId)`: Remove plant
- `createSamplePlants(userId)`: Create test data

### 3. **Home Screen Integration**
The HomeScreen now uses `StreamBuilder` to:
1. Listen to real-time plant data from Firebase
2. Automatically update UI when database changes
3. Display loading state while fetching
4. Show empty state when no plants exist
5. Handle errors gracefully

## Firebase Firestore Structure

### Collection: `plants`
```json
{
  "plantId": {
    "userId": "user123",
    "name": "Tomato Plant",
    "description": "A healthy tomato plant",
    "level": 3,
    "xp": 45,
    "growthProgress": 0.65,
    "waterLevel": 0.80,
    "sunlight": "Optimal",
    "lastWatered": Timestamp,
    "iconName": "local_florist",
    "colorHex": "#FF5722",
    "careInstructions": "Water daily...",
    "createdAt": Timestamp,
    "updatedAt": Timestamp
  }
}
```

## How to Use

### 1. **Setup Firebase**
Make sure you've already run:
```bash
flutterfire configure
```

### 2. **Create Sample Plants**
In the app, tap the "+" button in the top-right of the Home screen to create sample plants.

### 3. **Add a Plant Programmatically**
```dart
final plantService = PlantService();
await plantService.addPlant(
  Plant(
    id: '',
    name: 'My Plant',
    description: 'Description',
    colorHex: '#4CAF50',
  ),
  'userId123'
);
```

### 4. **Water a Plant**
```dart
await plantService.waterPlant(plantId);
```

### 5. **Add XP**
```dart
await plantService.addXP(plantId, 25);
```

### 6. **Listen to Real-time Updates**
```dart
StreamBuilder<List<Plant>>(
  stream: plantService.getUserPlants(userId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final plants = snapshot.data!;
      // Use plants data
    }
    return CircularProgressIndicator();
  },
)
```

## Key Features

### ✅ Real-time Updates
- Uses Firestore streams
- UI updates automatically when data changes
- No need to manually refresh

### ✅ User Isolation
- Each plant has a `userId` field
- Query filters by userId
- Users only see their own plants

### ✅ Auto-leveling System
- Every 100 XP = 1 level up
- XP automatically wraps to next level
- Level displayed on plant cards

### ✅ Error Handling
- Connection errors handled gracefully
- Empty states for no data
- Loading indicators during fetch

## Next Steps

### Add User Authentication
Replace the hardcoded `_userId = 'demo_user'` with:
```dart
final user = FirebaseAuth.instance.currentUser;
final userId = user?.uid ?? 'demo_user';
```

### Update PlantsPage
Modify `pages/plants_page.dart` to accept a Plant object and display real data:
```dart
class PlantsPage extends StatelessWidget {
  final Plant plant;
  const PlantsPage({super.key, required this.plant});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plant.name)),
      body: Column(
        children: [
          Text('Level ${plant.level}'),
          Text('XP: ${plant.xp}'),
          LinearProgressIndicator(value: plant.growthProgress),
          // Add water button
          ElevatedButton(
            onPressed: () async {
              await PlantService().waterPlant(plant.id);
            },
            child: Text('Water Plant'),
          ),
        ],
      ),
    );
  }
}
```

### Add Plant CRUD UI
Create screens for:
- Adding new plants (form)
- Editing plants (form)
- Deleting plants (confirmation dialog)

### Implement Achievements
Track:
- Total plants grown
- Days streak maintained
- Total XP earned
- Plants reached max level

## Testing

### Test in Firestore Console
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Find "plants" collection
4. Manually add/edit/delete documents
5. Watch UI update in real-time!

### Test Sample Data Creation
1. Tap "+" button in app
2. Check Firestore console for new documents
3. Verify data structure matches schema

## Common Issues

### Issue: "Permission denied"
**Solution**: Update Firestore security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /plants/{plantId} {
      allow read, write: if true; // For testing only!
      // In production, use proper authentication:
      // allow read, write: if request.auth != null && 
      //   resource.data.userId == request.auth.uid;
    }
  }
}
```

### Issue: "No data showing"
**Solution**:
1. Check Firestore console for documents
2. Verify userId matches
3. Check console for errors
4. Ensure Firebase is initialized

## Performance Tips

1. **Use Pagination**: Limit queries with `.limit(10)`
2. **Index Fields**: Create indexes for userId, createdAt
3. **Cache Data**: Firestore automatically caches
4. **Optimize Reads**: Use `get()` for one-time reads instead of streams

## Cost Optimization

- **Reads**: Each document read counts as 1 read
- **Streams**: Updates trigger new reads
- **Free Tier**: 50,000 reads/day
- **Tip**: Use `get()` for static data, streams for real-time

## Summary

Your app now has:
✅ Real-time Firebase integration
✅ CRUD operations for plants
✅ Automatic UI updates
✅ Proper error handling
✅ Sample data for testing
✅ Scalable architecture

The frontend fetches data using `StreamBuilder`, which listens to the Firebase collection and automatically updates the UI whenever the database changes!
