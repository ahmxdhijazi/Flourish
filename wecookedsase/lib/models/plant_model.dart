import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String? id; // Nullable for new plants, will be set by Firestore
  final String name;
  final String description;
  final int level;
  final int xp;
  final double growthProgress; // 0.0 to 1.0
  final double waterLevel; // 0.0 to 1.0
  final String sunlight; // e.g., "Optimal", "Low", "High"
  final DateTime lastWatered;
  final String iconName; // Store as string, map to IconData in UI
  final String colorHex; // Store color as hex string
  final String careInstructions;
  final String? latestImageUrl; // URL to the most recent uploaded image
  final DateTime createdAt;
  final DateTime updatedAt;

  Plant({
    this.id,
    required this.name,
    this.description = '',
    this.level = 1,
    this.xp = 0,
    this.growthProgress = 0.0,
    this.waterLevel = 1.0,
    this.sunlight = 'Optimal',
    DateTime? lastWatered,
    this.iconName = 'local_florist',
    this.colorHex = '#FF9800', // Default orange
    this.careInstructions = 'Default care instructions',
    this.latestImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : lastWatered = lastWatered ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create Plant from Firestore document
  factory Plant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Plant(
      id: doc.id,
      name: data['name'] ?? 'Unknown Plant',
      description: data['description'] ?? '',
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      growthProgress: (data['growthProgress'] ?? 0.0).toDouble(),
      waterLevel: (data['waterLevel'] ?? 1.0).toDouble(),
      sunlight: data['sunlight'] ?? 'Optimal',
      lastWatered: (data['lastWatered'] as Timestamp?)?.toDate() ?? DateTime.now(),
      iconName: data['iconName'] ?? 'local_florist',
      colorHex: data['colorHex'] ?? '#FF9800',
      careInstructions: data['careInstructions'] ?? 'No instructions available',
      latestImageUrl: data['latestImageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Plant to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'level': level,
      'xp': xp,
      'growthProgress': growthProgress,
      'waterLevel': waterLevel,
      'sunlight': sunlight,
      'lastWatered': Timestamp.fromDate(lastWatered),
      'iconName': iconName,
      'colorHex': colorHex,
      'careInstructions': careInstructions,
      'latestImageUrl': latestImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper method to get time since last watered
  String getTimeSinceWatered() {
    final difference = DateTime.now().difference(lastWatered);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Copy with method for updates
  Plant copyWith({
    String? id,
    String? name,
    String? description,
    int? level,
    int? xp,
    double? growthProgress,
    double? waterLevel,
    String? sunlight,
    DateTime? lastWatered,
    String? iconName,
    String? colorHex,
    String? careInstructions,
    String? latestImageUrl,
    DateTime? updatedAt,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      growthProgress: growthProgress ?? this.growthProgress,
      waterLevel: waterLevel ?? this.waterLevel,
      sunlight: sunlight ?? this.sunlight,
      lastWatered: lastWatered ?? this.lastWatered,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      careInstructions: careInstructions ?? this.careInstructions,
      latestImageUrl: latestImageUrl ?? this.latestImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
