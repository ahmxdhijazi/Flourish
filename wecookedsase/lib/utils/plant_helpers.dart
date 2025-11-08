import 'package:flutter/material.dart';

class PlantHelpers {
  // Convert icon name string to IconData
  static IconData getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'local_florist':
        return Icons.local_florist;
      case 'eco':
        return Icons.eco;
      case 'park':
        return Icons.park;
      case 'grass':
        return Icons.grass;
      case 'spa':
        return Icons.spa;
      case 'yard':
        return Icons.yard;
      case 'forest':
        return Icons.forest;
      default:
        return Icons.local_florist;
    }
  }

  // Convert hex color string to Color
  static Color getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.green; // Default color
    }
  }

  // Get color based on plant health/water level
  static Color getHealthColor(double waterLevel) {
    if (waterLevel > 0.7) {
      return Colors.green;
    } else if (waterLevel > 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Format progress percentage
  static String formatProgress(double progress) {
    return '${(progress * 100).toInt()}%';
  }
}
