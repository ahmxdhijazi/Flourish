import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/plant_service.dart';
import 'services/user_service.dart';
import 'models/plant_model.dart';
import 'pages/plants_page.dart';
import 'widgets/add_plant_dialog.dart';

// Garden Screen
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PlantService _plantService = PlantService();
  final UserService _userService = UserService();
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  
  // Get current user ID from Firebase Auth
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Plant> _filterPlants(List<Plant> plants, List<String> favorites) {
    return plants.where((plant) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          plant.name.toLowerCase().contains(_searchQuery);
      
      // Filter by favorites
      final matchesFavorites = !_showFavoritesOnly || favorites.contains(plant.id);
      
      return matchesSearch && matchesFavorites;
    }).toList();
  }

  Future<void> _toggleFavorite(String plantId, bool isFavorite) async {
    // Get fresh userId from FirebaseAuth to ensure we're using the current user
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to use favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Debug: Print the userId being used
    print('Toggle favorite - UserId: $currentUserId, PlantId: $plantId, IsFavorite: $isFavorite');

    try {
      if (isFavorite) {
        await _userService.removeFromFavorites(currentUserId, plantId);
      } else {
        await _userService.addToFavorites(currentUserId, plantId);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Fetch the latest analysis data for a specific plant
  Future<Map<String, dynamic>?> _fetchLatestAnalysis(String plantId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in, cannot fetch analysis');
        return null;
      }

      debugPrint('Fetching analysis for plant: $plantId, user: ${user.uid}');

      // Simplified query without composite index requirement
      // Just filter by plantId and userId, then sort in memory
      final analysisSnapshot = await FirebaseFirestore.instance
          .collection('plant_analysis')
          .where('plantId', isEqualTo: plantId)
          .where('userId', isEqualTo: user.uid)
          .get();

      debugPrint('Found ${analysisSnapshot.docs.length} analysis documents for plant $plantId');

      if (analysisSnapshot.docs.isNotEmpty) {
        // Sort by timestamp in memory (client-side)
        final sortedDocs = analysisSnapshot.docs
          ..sort((a, b) {
            final aTime = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
            final bTime = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
            return bTime.compareTo(aTime); // Descending order
          });
        
        final data = sortedDocs.first.data();
        final score = (data['overallScore'] as num?)?.toDouble();
        final stage = data['stage'] as String?;
        debugPrint('Latest analysis for plant $plantId: score=$score, stage=$stage');
        return {
          'overallScore': score,
          'stage': stage,
        };
      }
      debugPrint('No analysis found for plant $plantId');
      return null;
    } catch (e) {
      debugPrint('Error fetching latest analysis for plant $plantId: $e');
      return null;
    }
  }

  Future<void> _showCreatePlantDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Create New Plant',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Plant Name',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a plant name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (_userId != null) {
                  try {
                    await _plantService.addPlant(
                      Plant(
                        name: name,
                        description: description,
                        colorHex: '#2196F3',
                      ),
                      _userId!,
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Plant "$name" created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create plant: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Create',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Garden",
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddPlantDialog(context, _userId!),
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        heroTag: 'gardenAddPlant', // Unique hero tag to avoid conflicts
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search plants...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Favorites Toggle Button
                Container(
                  decoration: BoxDecoration(
                    color: _showFavoritesOnly 
                        ? Colors.deepPurple 
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showFavoritesOnly ? Icons.star : Icons.star_border,
                      color: _showFavoritesOnly 
                          ? Colors.white 
                          : Colors.deepPurple,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                      });
                    },
                    iconSize: 24.sp,
                  ),
                ),
              ],
            ),
          ),
          // Plants List
          Expanded(
            child: _userId == null
                ? const Center(
                    child: Text('Please log in to view your plants'),
                  )
                : StreamBuilder<List<String>>(
                    stream: _userService.streamFavorites(_userId!),
                    builder: (context, favoritesSnapshot) {
                      return StreamBuilder<List<Plant>>(
                        stream: _plantService.getUserPlants(_userId!),
                        builder: (context, plantsSnapshot) {
                          if (plantsSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (plantsSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${plantsSnapshot.error}',
                                style: GoogleFonts.poppins(color: Colors.red),
                              ),
                            );
                          }

                          if (!plantsSnapshot.hasData || plantsSnapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.eco, size: 64.sp, color: Colors.grey),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'No plants yet!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Press the + button to add your first plant',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final plants = plantsSnapshot.data!;
                          final favorites = favoritesSnapshot.data ?? [];
                          final filteredPlants = _filterPlants(plants, favorites);

                          if (filteredPlants.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64.sp, color: Colors.grey),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'No plants found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Try adjusting your search or filters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: filteredPlants.length,
                            itemBuilder: (context, index) {
                              final plant = filteredPlants[index];
                              final color = Color(
                                int.parse(plant.colorHex.replaceFirst('#', '0xFF'))
                              );
                              final isFavorite = favorites.contains(plant.id);
                              
                              // Use FutureBuilder to fetch the latest analysis
                              return FutureBuilder<Map<String, dynamic>?>(
                                future: plant.id != null ? _fetchLatestAnalysis(plant.id!) : null,
                                builder: (context, analysisSnapshot) {
                                  final analysis = analysisSnapshot.data;
                                  return _buildPlantCard(plant, color, isFavorite, analysis);
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(Plant plant, Color color, bool isFavorite, Map<String, dynamic>? analysis) {
    final score = analysis?['overallScore'] as double?;
    final stage = analysis?['stage'] as String?;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantsPage(
             plantId: plant.id,
              plantName: plant.name,
              plantIcon: Icons.local_florist,
              plantColor: color,
              plantDescription: plant.description,
              plantLevel: plant.level,
              plantXp: plant.xp,
              plantGrowthProgress: plant.growthProgress,
              plantWaterLevel: plant.waterLevel,
              plantSunlight: plant.sunlight,
              plantLastWatered: plant.lastWatered,
              plantCareInstructions: plant.careInstructions,
              latestImageUrl: plant.latestImageUrl,
              plantCreatedAt: plant.createdAt,
              plantUpdatedAt: plant.updatedAt,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16.h),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon, Name, and Favorite Button
              Row(
                children: [
                  // Plant Icon or Image
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: plant.latestImageUrl != null && plant.latestImageUrl!.isNotEmpty
                          ? Image.network(
                              plant.latestImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: Icon(
                                    Icons.local_florist,
                                    color: Colors.white,
                                    size: 28.sp,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            )
                          : Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Icon(
                                Icons.local_florist,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Plant Name and Level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Level ${plant.level}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${plant.xp} XP',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28.sp,
                    ),
                    onPressed: plant.id == null ? null : () async {
                      await _toggleFavorite(plant.id!, isFavorite);
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Description
              if (plant.description.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(
                    plant.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Stats Row
              Row(
                children: [
                  // Time since last watered
                  _buildStatItem(
                    Icons.water_drop,
                    _formatTimeSinceWatered(plant.lastWatered),
                    Colors.blue,
                  ),
                  SizedBox(width: 16.w),
                  // Growth stage from analysis
                  _buildStatItem(
                    Icons.eco,
                    stage != null ? _toTitleCase(stage) : 'Unknown',
                    Colors.green,
                  ),
                  SizedBox(width: 16.w),
                  // Health score
                  _buildStatItem(
                    Icons.favorite,
                    score != null ? '${score.toStringAsFixed(0)}' : '--',
                    score != null ? _getScoreColor(score) : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: color,
        ),
        SizedBox(width: 4.w),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// Get color based on score value
  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Format time since last watered
  String _formatTimeSinceWatered(DateTime lastWatered) {
    final now = DateTime.now();
    final difference = now.difference(lastWatered);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return '1d ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Convert string to title case
  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}