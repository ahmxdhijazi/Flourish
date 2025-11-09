import 'package:flutter/foundation.dart';

class PlantAnalysisResult {
  final double healthScore;
  final double growthScore;
  final double overallScore;
  final String stage;
  final double confidence;
  final List<String> recommendations;
  final Map<String, dynamic> rawData;

  PlantAnalysisResult({
    required this.healthScore,
    required this.growthScore,
    required this.overallScore,
    required this.stage,
    required this.confidence,
    required this.recommendations,
    required this.rawData,
  });

  Map<String, dynamic> toJson() {
    return {
      'healthScore': healthScore,
      'growthScore': growthScore,
      'overallScore': overallScore,
      'stage': stage,
      'confidence': confidence,
      'recommendations': recommendations,
      'rawData': rawData,
    };
  }
}

class PlantScoreCalculator {
  /// Calculate plant scores based on API response from analyze-dual-model endpoint
  static PlantAnalysisResult calculateScores(Map<String, dynamic> apiResponse) {
    debugPrint('=== Calculating Plant Scores ===');
    debugPrint('API Response: $apiResponse');

    try {
      // Extract data from the dual model response
      // API returns: { "model1": { "result": { "predictions": [...] } } }
      final model1Data = apiResponse['model1'] as Map<String, dynamic>?;
      final model2Data = apiResponse['model2'] as Map<String, dynamic>?;
      
      final model1Result = model1Data?['result'] as Map<String, dynamic>?;
      final model2Result = model2Data?['result'] as Map<String, dynamic>?;

      // Initialize scores
      double healthScore = 0.0;
      double growthScore = 0.0;
      double overallScore = 0.0;
      String stage = 'Unknown';
      double confidence = 0.0;
      List<String> recommendations = [];

      // Process Model 1 results (primary detection - growth stage)
      if (model1Result != null && model1Result['predictions'] != null) {
        final predictions = model1Result['predictions'] as List<dynamic>;
        
        if (predictions.isNotEmpty) {
          final topPrediction = predictions[0] as Map<String, dynamic>;
          
          // Extract class and confidence
          final detectedClass = topPrediction['class'] as String? ?? 'Unknown';
          confidence = (topPrediction['confidence'] as num?)?.toDouble() ?? 0.0;
          
          debugPrint('Model 1 - Class: $detectedClass, Confidence: $confidence');
          
          // Determine growth stage and calculate growth score
          stage = _normalizeGrowthStage(detectedClass);
          growthScore = _calculateGrowthScore(stage, confidence);
          
          // Add recommendations based on stage
          recommendations.addAll(_getStageRecommendations(stage));
        }
      }

      // Process Model 2 results (secondary analysis - disease/health detection)
      if (model2Result != null && model2Result['predictions'] != null) {
        final predictions = model2Result['predictions'] as List<dynamic>;
        
        if (predictions.isNotEmpty) {
          // Disease detected - deduct from health score based on confidence
          final topPrediction = predictions[0] as Map<String, dynamic>;
          
          final detectedClass = topPrediction['class'] as String? ?? 'Unknown';
          final model2Confidence = (topPrediction['confidence'] as num?)?.toDouble() ?? 0.0;
          
          debugPrint('Model 2 - Disease Detected: $detectedClass, Confidence: $model2Confidence');
          
          // Calculate health score with disease penalty
          healthScore = _calculateHealthScoreWithDisease(detectedClass, model2Confidence);
          
          // Add health-based recommendations
          recommendations.addAll(_getHealthRecommendations(detectedClass, healthScore));
        } else {
          // No disease detected - plant is healthy
          debugPrint('Model 2 - No disease detected, plant is healthy');
          healthScore = 90.0; // High base health score when no disease
          recommendations.add('No diseases detected - plant appears healthy!');
        }
      } else {
        // Model 2 data not available - assume healthy
        healthScore = 90.0;
      }

      // Calculate overall score (weighted average)
      overallScore = _calculateOverallScore(healthScore, growthScore, confidence);

      // Add general recommendations based on overall score
      recommendations.addAll(_getGeneralRecommendations(overallScore));

      final result = PlantAnalysisResult(
        healthScore: healthScore,
        growthScore: growthScore,
        overallScore: overallScore,
        stage: stage,
        confidence: confidence,
        recommendations: recommendations,
        rawData: apiResponse,
      );

      debugPrint('=== Scores Calculated ===');
      debugPrint('Health Score: ${healthScore.toStringAsFixed(2)}');
      debugPrint('Growth Score: ${growthScore.toStringAsFixed(2)}');
      debugPrint('Overall Score: ${overallScore.toStringAsFixed(2)}');
      debugPrint('Stage: $stage');
      debugPrint('Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
      debugPrint('Recommendations: ${recommendations.length}');

      return result;
    } catch (e, stackTrace) {
      debugPrint('Error calculating scores: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return default values on error
      return PlantAnalysisResult(
        healthScore: 0.0,
        growthScore: 0.0,
        overallScore: 0.0,
        stage: 'Unknown',
        confidence: 0.0,
        recommendations: ['Unable to analyze image. Please try again.'],
        rawData: apiResponse,
      );
    }
  }

  /// Normalize growth stage names to consistent format
  static String _normalizeGrowthStage(String detectedClass) {
    final lowerClass = detectedClass.toLowerCase().trim();
    
    // Map Model 1 specific classes to display names
    if (lowerClass == '0') {
      return 'germination';
    } else if (lowerClass == 'germination') {
      return 'germination';
    } else if (lowerClass == 'growing') {
      return 'growing';
    } else if (lowerClass == 'flowering') {
      return 'flowering';
    }
    
    // Fallback for any unexpected classes
    return detectedClass;
  }

  /// Calculate growth score based on stage and confidence
  static double _calculateGrowthScore(String stage, double confidence) {
    // Base score from confidence
    double baseScore = confidence * 100;
    
    // Adjust based on growth stage (later stages = higher score)
    double stageMultiplier = 1.0;
    switch (stage.toLowerCase()) {
      case 'germination':
        stageMultiplier = 0.6;
        break;
      case 'growing':
        stageMultiplier = 0.8;
        break;
      case 'flowering':
        stageMultiplier = 1.0;
        break;
      default:
        stageMultiplier = 0.5;
    }
    
    return (baseScore * stageMultiplier).clamp(0.0, 100.0);
  }

  /// Calculate health score when disease is detected (model2 has predictions)
  /// The presence of predictions means disease was detected, so we deduct points
  static double _calculateHealthScoreWithDisease(String detectedClass, double confidence) {
    final lowerClass = detectedClass.toLowerCase();
    
    // Check for specific diseases (lower scores based on severity)
    if (lowerClass.contains('early blight')) {
      // Early blight - moderate severity, treatable
      return (45.0 - (confidence * 15)).clamp(25.0, 45.0);
    } else if (lowerClass.contains('late blight')) {
      // Late blight - severe, spreads quickly
      return (35.0 - (confidence * 15)).clamp(15.0, 35.0);
    } else if (lowerClass.contains('leaf spot')) {
      // Leaf spot - moderate severity
      return (50.0 - (confidence * 20)).clamp(25.0, 50.0);
    } else if (lowerClass.contains('mosaic virus')) {
      // Mosaic virus - severe, no cure
      return (30.0 - (confidence * 10)).clamp(15.0, 30.0);
    } else if (lowerClass.contains('rust')) {
      // Rust - moderate severity, treatable
      return (48.0 - (confidence * 18)).clamp(25.0, 48.0);
    } else if (lowerClass.contains('disease') || lowerClass.contains('pest') || 
               lowerClass.contains('damage')) {
      // Generic disease/pest/damage
      return (50.0 - (confidence * 30)).clamp(20.0, 50.0);
    }
    
    // Default: if disease detected but not recognized, apply moderate penalty
    return (60.0 - (confidence * 25)).clamp(30.0, 60.0);
  }

  /// Calculate overall score (weighted average of health and growth)
  static double _calculateOverallScore(double healthScore, double growthScore, double confidence) {
    // Weighted average: 55% health, 40% growth, 5% confidence
    // Reduced confidence weight to have less impact on final score
    final score = (healthScore * 0.55) + (growthScore * 0.40) + (confidence * 100 * 0.05);
    return score.clamp(0.0, 100.0);
  }

  /// Get recommendations based on growth stage
  static List<String> _getStageRecommendations(String stage) {
    switch (stage.toLowerCase()) {
      case 'germination':
        return [
          'Germination Stage - Handle with care',
          'Provide consistent moisture without overwatering',
          'Ensure adequate light but avoid direct harsh sunlight',
          'Maintain stable temperature between 65-75°F',
          'Avoid fertilizing until first true leaves appear',
        ];
      case 'growing':
        return [
          'Growing Stage - Time to nurture',
          'Increase watering frequency as plant grows',
          'Apply nitrogen-rich fertilizer for leaf development',
          'Prune lower leaves to encourage upward growth',
          'Ensure proper spacing for air circulation',
        ];
      case 'flowering':
        return [
          'Flowering Stage - Support bloom development',
          'Switch to phosphorus-rich bloom fertilizer',
          'Maintain consistent watering schedule',
          'Ensure 12+ hours of light daily for optimal flowering',
          'Support stems if flowers become heavy',
        ];
      default:
        return ['Continue monitoring plant growth and maintain regular care routine'];
    }
  }

  /// Get recommendations based on health analysis
  static List<String> _getHealthRecommendations(String detectedClass, double healthScore) {
    final recommendations = <String>[];
    final lowerClass = detectedClass.toLowerCase();
    
    // Specific recommendations for each disease
    if (lowerClass.contains('early blight')) {
      recommendations.add('Early Blight Detected');
      recommendations.add('Remove affected leaves immediately');
      recommendations.add('Apply copper-based fungicide');
      recommendations.add('Improve air circulation around plant');
      recommendations.add('Avoid overhead watering to reduce leaf wetness');
    } else if (lowerClass.contains('late blight')) {
      recommendations.add('Late Blight Detected - Act Quickly!');
      recommendations.add('Isolate plant immediately to prevent spread');
      recommendations.add('Remove all infected parts');
      recommendations.add('Apply systemic fungicide treatment');
      recommendations.add('Monitor nearby plants closely for symptoms');
    } else if (lowerClass.contains('leaf spot')) {
      recommendations.add('Leaf Spot Detected');
      recommendations.add('Remove infected leaves and dispose properly');
      recommendations.add('Apply fungicide spray as directed');
      recommendations.add('Ensure proper spacing for air circulation');
      recommendations.add('Water at base to keep foliage dry');
    } else if (lowerClass.contains('rust')) {
      recommendations.add('Rust Disease Detected');
      recommendations.add('Remove infected leaves carefully');
      recommendations.add('Apply sulfur or copper-based fungicide');
      recommendations.add('Increase spacing between plants');
      recommendations.add('Water in morning to allow foliage to dry');
    } else if (healthScore < 50) {
      recommendations.add('Plant health needs attention');
      recommendations.add('Check for pests, diseases, or nutrient deficiencies');
      recommendations.add('Consider adjusting watering or light conditions');
    } else if (healthScore < 70) {
      recommendations.add('Plant health is moderate - monitor closely');
      recommendations.add('Ensure proper care routine is maintained');
    } else {
      recommendations.add('Plant appears healthy!');
      recommendations.add('Continue current care routine');
    }
    
    return recommendations;
  }

  /// Get general recommendations based on overall score
  static List<String> _getGeneralRecommendations(double overallScore) {
    if (overallScore >= 80) {
      return ['Excellent progress! Keep up the great work!'];
    } else if (overallScore >= 60) {
      return ['Good progress - minor improvements possible'];
    } else {
      return ['Consider reviewing care instructions for optimal growth'];
    }
  }
}
