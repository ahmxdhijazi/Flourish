import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlantsGalleryPage extends StatefulWidget {
  final String plantId;
  final String plantName;
  final Color plantColor;

  const PlantsGalleryPage({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.plantColor,
  });

  @override
  State<PlantsGalleryPage> createState() => _PlantsGalleryPageState();
}

class _PlantsGalleryPageState extends State<PlantsGalleryPage> {
  List<PlantImage> _images = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Get reference to the plant's folder
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_plants/${user.uid}/${widget.plantId}');

      // List all files in the folder
      final listResult = await storageRef.listAll();

      if (listResult.items.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Parse filenames and get download URLs
      List<PlantImage> images = [];
      for (var item in listResult.items) {
        try {
          // Extract timestamp from filename: plant_2025-11-09T04:01:12.707074.jpg
          final filename = item.name;
          if (filename.startsWith('plant_') && filename.contains('.jpg')) {
            final timestampStr = filename
                .substring(6, filename.length - 4); // Remove "plant_" and ".jpg"
            final timestamp = DateTime.parse(timestampStr);
            final downloadUrl = await item.getDownloadURL();
            
            images.add(PlantImage(
              url: downloadUrl,
              timestamp: timestamp,
              filename: filename,
            ));
          }
        } catch (e) {
          debugPrint('Error parsing image ${item.name}: $e');
        }
      }

      // Sort by timestamp in descending order (most recent first)
      images.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading images: $e');
      setState(() {
        _error = 'Failed to load images: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.plantName} Gallery',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: widget.plantColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _images.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64.sp,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No photos yet',
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Take a photo of your plant to see it here!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(8.w),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.w,
                          mainAxisSpacing: 8.h,
                          childAspectRatio: 1,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          return GestureDetector(
                            onTap: () => _openFullscreen(index),
                            child: Hero(
                              tag: image.url,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    image.url,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey.shade600,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _openFullscreen(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenGallery(
          images: _images,
          initialIndex: initialIndex,
          plantColor: widget.plantColor,
        ),
      ),
    );
  }
}

class PlantImage {
  final String url;
  final DateTime timestamp;
  final String filename;

  PlantImage({
    required this.url,
    required this.timestamp,
    required this.filename,
  });
}

class FullscreenGallery extends StatefulWidget {
  final List<PlantImage> images;
  final int initialIndex;
  final Color plantColor;

  const FullscreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.plantColor,
  });

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} of ${widget.images.length}',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return Center(
                child: Hero(
                  tag: image.url,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      image.url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 64.sp,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Failed to load image',
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          // Date overlay at bottom
          Positioned(
            bottom: 32.h,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _formatDateTime(widget.images[_currentIndex].timestamp),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (difference.inDays == 1) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Yesterday at $hour:$minute';
    } else if (difference.inDays < 7) {
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dateTime.weekday - 1];
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$weekday at $hour:$minute';
    } else {
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '${dateTime.year}-$month-$day at $hour:$minute';
    }
  }
}
