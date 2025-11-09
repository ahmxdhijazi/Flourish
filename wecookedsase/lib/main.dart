import 'package:flutter/material.dart';
import 'screen/plant_photo_selector.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'profile.dart'; // Make sure profile.dart can accept a userId
import 'pages/plants_page.dart';
import 'services/plant_service.dart';
import 'models/plant_model.dart';
import 'login.dart';
import '../services/friend_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/leaderboard_page.dart';
import 'garden.dart';
import 'widgets/add_plant_dialog.dart';
import 'services/streak_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Root widget that checks authentication state
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData.light().textTheme,
            ),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// Wrapper to check if user is logged in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show main navigation
        if (snapshot.hasData && snapshot.data != null) {
          // --- FIX: Pass the non-null user ID to MainNavigation ---
          return MainNavigation(userID: snapshot.data!.uid);
        }

        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}

// Main Navigation with Bottom Bar
class MainNavigation extends StatefulWidget {
  // --- FIX: This is the one, correct constructor ---
  final String userID; // The ID we get from AuthWrapper
  const MainNavigation({super.key, required this.userID});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final StreakService _streakService = StreakService();

  // --- FIX: Declare the list here, but build it in initState ---
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // This calculates/updates the streak *once* when the app is opened
    _streakService.checkLoginStreak();

    // --- FIX: Build the list using the guaranteed userID from the widget ---
    _screens = [
      HomeScreen(userId: widget.userID), // Pass the ID
      LeaderBoardPage(),
      GardenScreen(),
      ProfileScreen(userId: widget.userID), // Pass the ID to Profile too
    ];
  }

  void _onCameraButtonPressed(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is not signed in, show login screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlantPhotoSelector()),
          );
        },
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        child: Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          elevation: 0,
          child: SizedBox(
            height: 65.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.leaderboard, 'Leaderboard', 1),
                SizedBox(width: 40.w),
                _buildNavItem(Icons.grass, 'Garden', 2),
                _buildNavItem(Icons.person, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.deepPurple : Colors.grey,
                size: 20.sp,
              ),
              SizedBox(height: 2.h),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.deepPurple : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Home Screen with Firebase Integration
class HomeScreen extends StatefulWidget {
  // --- FIX: Accept the non-null userId from MainNavigation ---
  final String? userId; 
  const HomeScreen({super.key, required this.userId}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlantService _plantService = PlantService();
  final _friendService = FriendService();
  
  // --- FIX: Delete these confusing/unused variables ---
  // String? get _userId => FirebaseAuth.instance.currentUser?.uid; (DELETED)
  // final _currentUserId = FirebaseAuth.instance.currentUser?.uid; (DELETED)

  int _streakCount = 0;
  @override
  void initState() {
    super.initState();
    // When this screen loads, go get the real value
    _fetchStreakCount();
  }

  Future<void> _fetchStreakCount() async {
    // --- FIX: Use the guaranteed non-null widget.userId ---
    if (widget.userId == null) {
      print("HomeScreen: No user ID provided, can't fetch streak.");
      return;
    }
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId) // <-- Use the passed-in ID
          .get();

      if (doc.exists) {
        // Get the value from Firestore
        int fetchedStreak =
            (doc.data() as Map<String, dynamic>)['streakCount'] ?? 0;

        // This is the magic line that updates your UI
        if (mounted) { // Checks if the widget is still on screen
          setState(() {
            _streakCount = fetchedStreak;
          });
        }
      } else {
        // --- FIX: This handles the split-second race condition ---
        print("HomeScreen: User document doesn't exist yet, retrying in 1 sec...");
        // Wait for profile creation to finish, then try again
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _fetchStreakCount(); // Retry fetching
        }
      }
    } catch (e) {
      print("Error fetching streak count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- FIX: Use widget.userId for this check ---
    if (widget.userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your plants'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Flourish",
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180.h,
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple,
                    Colors.purple.shade300,
                  ],
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Daily Streak $_streakCount", // <-- This will now update
                    style: GoogleFonts.poppins(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Featured Cards - Firebase Stream
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your Plants",
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // StreamBuilder to fetch plants from Firebase
            SizedBox(
              height: 180.h,
              child: StreamBuilder<List<Plant>>(
                // --- FIX: Use the guaranteed non-null widget.userId ---
                stream: _plantService.getUserPlants(widget.userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco, size: 48.sp, color: Colors.grey),
                          SizedBox(height: 8.h),
                          Text(
                            'No plants yet!',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Tap + to add sample plants',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final plants = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: plants.length,
                    itemBuilder: (context, index) {
                      final plant = plants[index];
                      final color = Color(
                          int.parse(plant.colorHex.replaceFirst('#', '0xFF')));
                      return _buildFeatureCard(
                        plant,
                        color,
                        context,
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 20.h),

            // Quick Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                "Quick Actions",
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  FButton(
                    label: const Text('Add New Plant'),
                    prefix: const Icon(Icons.add),
                    style: FButtonStyle.outline,
                    // --- FIX: Use the guaranteed non-null widget.userId ---
                    onPress: () => showAddPlantDialog(context, widget.userId!),
                  ),
                  SizedBox(height: 12.h),
                  FButton(
                    label: const Text('View All Plants'),
                    prefix: const Icon(Icons.list),
                    style: FButtonStyle.outline,
                    onPress: () {
                      // Navigate to garden screen
                      // setState(() {}); // This setState did nothing, safe to remove
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(Plant plant, Color color, BuildContext context) {
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
      child: VStack([
        // Show plant image if available, otherwise show icon
        plant.latestImageUrl != null && plant.latestImageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  plant.latestImageUrl!,
                  width: 80.sp,
                  height: 80.sp,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.local_florist, size: 50.sp, color: Colors.white);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 50.sp,
                      height: 50.sp,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              )
            : Icon(Icons.local_florist, size: 50.sp, color: Colors.white),
        10.h.heightBox,
        Text(
          plant.name,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        4.h.heightBox,
        Text(
          'Level ${plant.level}',
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 11.sp,
          ),
        ),
      ],
              alignment: MainAxisAlignment.center,
              crossAlignment: CrossAxisAlignment.center)
          .p(16.w)
          .box
          .color(color)
          .roundedLg
          .width(160.w)
          .height(160.h)
          .shadowMd
          .make()
          .pOnly(right: 12.w),
    );
  }
}
