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
      final model1 = apiResponse['model_1'] as Map<String, dynamic>?;
      final model2 = apiResponse['model_2'] as Map<String, dynamic>?;

      // Initialize scores
      double healthScore = 0.0;
      double growthScore = 0.0;
      double overallScore = 0.0;
      String stage = 'Unknown';
      double confidence = 0.0;
      List<String> recommendations = [];

      // Process Model 1 results (primary detection)
      if (model1 != null && model1['predictions'] != null) {
        final predictions = model1['predictions'] as List<dynamic>;
        
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

      // Process Model 2 results (secondary analysis)
      if (model2 != null && model2['predictions'] != null) {
        final predictions = model2['predictions'] as List<dynamic>;
        
        if (predictions.isNotEmpty) {
          final topPrediction = predictions[0] as Map<String, dynamic>;
          
          final detectedClass = topPrediction['class'] as String? ?? 'Unknown';
          final model2Confidence = (topPrediction['confidence'] as num?)?.toDouble() ?? 0.0;
          
          debugPrint('Model 2 - Class: $detectedClass, Confidence: $model2Confidence');
          
          // Calculate health score based on model 2 results
          healthScore = _calculateHealthScore(detectedClass, model2Confidence);
          
          // Add health-based recommendations
          recommendations.addAll(_getHealthRecommendations(detectedClass, healthScore));
        }
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
        healthScore: 50.0,
        growthScore: 50.0,
        overallScore: 50.0,
        stage: 'Unknown',
        confidence: 0.0,
        recommendations: ['Unable to analyze image. Please try again.'],
        rawData: apiResponse,
      );
    }
  }

  /// Normalize growth stage names to consistent format
  static String _normalizeGrowthStage(String detectedClass) {
    final lowerClass = detectedClass.toLowerCase();
    
    if (lowerClass.contains('seed') || lowerClass.contains('germination')) {
      return 'Seedling';
    } else if (lowerClass.contains('vegetative') || lowerClass.contains('growth')) {
      return 'Vegetative';
    } else if (lowerClass.contains('flowering') || lowerClass.contains('flower')) {
      return 'Flowering';
    } else if (lowerClass.contains('fruiting') || lowerClass.contains('fruit')) {
      return 'Fruiting';
    } else if (lowerClass.contains('mature') || lowerClass.contains('harvest')) {
      return 'Mature';
    }
    
    return detectedClass;
  }

  /// Calculate growth score based on stage and confidence
  static double _calculateGrowthScore(String stage, double confidence) {
    // Base score from confidence
    double baseScore = confidence * 100;
    
    // Adjust based on growth stage (later stages = higher score)
    double stageMultiplier = 1.0;
    switch (stage.toLowerCase()) {
      case 'seedling':
        stageMultiplier = 0.6;
        break;
      case 'vegetative':
        stageMultiplier = 0.75;
        break;
      case 'flowering':
        stageMultiplier = 0.9;
        break;
      case 'fruiting':
        stageMultiplier = 0.95;
        break;
      case 'mature':
        stageMultiplier = 1.0;
        break;
      default:
        stageMultiplier = 0.5;
    }
    
    return (baseScore * stageMultiplier).clamp(0.0, 100.0);
  }

  /// Calculate health score based on detected class and confidence
  static double _calculateHealthScore(String detectedClass, double confidence) {
    final lowerClass = detectedClass.toLowerCase();
    
    // Check for health indicators in the class name
    if (lowerClass.contains('healthy') || lowerClass.contains('good')) {
      return (confidence * 100).clamp(70.0, 100.0);
    } else if (lowerClass.contains('disease') || lowerClass.contains('pest') || 
               lowerClass.contains('damage')) {
      return (50.0 - (confidence * 30)).clamp(20.0, 50.0);
    } else if (lowerClass.contains('stress') || lowerClass.contains('nutrient')) {
      return (60.0 - (confidence * 20)).clamp(40.0, 60.0);
    }
    
    // Default: calculate based on confidence
    return (confidence * 85).clamp(50.0, 85.0);
  }

  /// Calculate overall score (weighted average of health and growth)
  static double _calculateOverallScore(double healthScore, double growthScore, double confidence) {
    // Weighted average: 50% health, 40% growth, 10% confidence
    final score = (healthScore * 0.5) + (growthScore * 0.4) + (confidence * 100 * 0.1);
    return score.clamp(0.0, 100.0);
  }

  /// Get recommendations based on growth stage
  static List<String> _getStageRecommendations(String stage) {
    switch (stage.toLowerCase()) {
      case 'seedling':
        return [
          'Provide consistent moisture for seedling development',
          'Ensure adequate light but avoid direct harsh sunlight',
          'Maintain stable temperature between 65-75°F',
        ];
      case 'vegetative':
        return [
          'Increase watering frequency as plant grows',
          'Consider fertilizing with nitrogen-rich nutrients',
          'Prune to encourage bushier growth',
        ];
      case 'flowering':
        return [
          'Switch to bloom-boosting fertilizer',
          'Maintain consistent watering schedule',
          'Ensure 12+ hours of light daily',
        ];
      case 'fruiting':
        return [
          'Support heavy branches with stakes',
          'Continue bloom fertilizer application',
          'Monitor for pests attracted to fruits',
        ];
      case 'mature':
        return [
          'Prepare for harvest when ready',
          'Reduce fertilizer as plant matures',
          'Monitor for signs of over-ripening',
        ];
      default:
        return ['Continue regular plant care routine'];
    }
  }

  /// Get recommendations based on health analysis
  static List<String> _getHealthRecommendations(String detectedClass, double healthScore) {
    final recommendations = <String>[];
    
    if (healthScore < 50) {
      recommendations.add('⚠️ Plant health needs attention');
      recommendations.add('Check for pests, diseases, or nutrient deficiencies');
      recommendations.add('Consider adjusting watering or light conditions');
    } else if (healthScore < 70) {
      recommendations.add('Plant health is moderate - monitor closely');
      recommendations.add('Ensure proper care routine is maintained');
    } else {
      recommendations.add('✅ Plant appears healthy!');
      recommendations.add('Continue current care routine');
    }
    
    return recommendations;
  }

  /// Get general recommendations based on overall score
  static List<String> _getGeneralRecommendations(double overallScore) {
    if (overallScore >= 80) {
      return ['🌟 Excellent progress! Keep up the great work!'];
    } else if (overallScore >= 60) {
      return ['📈 Good progress - minor improvements possible'];
    } else {
      return ['💡 Consider reviewing care instructions for optimal growth'];
    }
  }
}
