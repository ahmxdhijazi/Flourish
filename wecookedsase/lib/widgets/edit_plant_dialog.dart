import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/plant_service.dart';
import '../models/plant_model.dart';

// Available colors for plant cards
final List<Map<String, dynamic>> availablePlantColors = [
  {'name': 'Purple', 'hex': '#9C27B0', 'color': Colors.purple},
  {'name': 'Blue', 'hex': '#2196F3', 'color': Colors.blue},
  {'name': 'Green', 'hex': '#4CAF50', 'color': Colors.green},
  {'name': 'Orange', 'hex': '#FF9800', 'color': Colors.orange},
  {'name': 'Pink', 'hex': '#E91E63', 'color': Colors.pink},
  {'name': 'Teal', 'hex': '#009688', 'color': Colors.teal},
  {'name': 'Red', 'hex': '#F44336', 'color': Colors.red},
  {'name': 'Indigo', 'hex': '#3F51B5', 'color': Colors.indigo},
];

Future<void> showEditPlantDialog(
  BuildContext context,
  Plant plant,
  String userId,
) async {
  final plantService = PlantService();
  final nameController = TextEditingController(text: plant.name);
  final descriptionController = TextEditingController(text: plant.description);
  final careInstructionsController = TextEditingController(
    text: plant.careInstructions == 'No specific care instructions provided.'
        ? ''
        : plant.careInstructions,
  );
  String selectedColorHex = plant.colorHex;

  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.deepPurple, size: 28.sp),
                SizedBox(width: 8.w),
                Text(
                  'Edit Plant',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant Name
                  Text(
                    'Plant Name *',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter plant name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Description
                  Text(
                    'Description *',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe your plant...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Care Instructions (Optional)
                  Text(
                    'Care Instructions (Optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: careInstructionsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., Water weekly, needs bright indirect light...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Color Selection
                  Text(
                    'Card Color *',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: availablePlantColors.map((colorData) {
                      final isSelected = selectedColorHex == colorData['hex'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColorHex = colorData['hex'];
                          });
                        },
                        child: Container(
                          width: 50.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: colorData['color'],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24.sp,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a plant name',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a description',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == true && context.mounted) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'Updating plant...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Update the plant in Firebase
      final updatedPlant = Plant(
        id: plant.id,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        colorHex: selectedColorHex,
        careInstructions: careInstructionsController.text.trim().isEmpty
            ? 'No specific care instructions provided.'
            : careInstructionsController.text.trim(),
        level: plant.level,
        xp: plant.xp,
        growthProgress: plant.growthProgress,
        waterLevel: plant.waterLevel,
        sunlight: plant.sunlight,
        lastWatered: plant.lastWatered,
        createdAt: plant.createdAt,
        updatedAt: DateTime.now(),
      );

      await plantService.updatePlant(updatedPlant);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success message and pop back to refresh
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  'Plant updated successfully!',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop back to trigger refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Failed to update plant: $e',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Clean up controllers
    nameController.dispose();
    descriptionController.dispose();
    careInstructionsController.dispose();
  }
}
