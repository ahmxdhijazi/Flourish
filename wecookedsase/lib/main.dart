import 'package:flutter/material.dart';
import 'screen/plant_photo_selector.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'profile.dart';
import 'pages/plants_page.dart';
import 'services/plant_service.dart';
import 'models/plant_model.dart';
import 'login.dart';
import '../services/friend_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/leaderboard_page.dart';
import 'garden.dart';
import 'widgets/add_plant_dialog.dart';

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
          return const MainNavigation();
        }

        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}

// Main Navigation with Bottom Bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LeaderBoardPage(), // imported from leaderboard_page.dart
    GardenScreen(),
    ProfileScreen(),
  ];

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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlantService _plantService = PlantService();

  // Get current user ID from Firebase Auth
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  final _friendService = FriendService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    // If user is not logged in, show error
    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your plants'),
        ),
      );
    }

    int streakCount = 5; //tmp variable for streak count
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
                    "Daily Streak $streakCount",
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
              height: 160.h,
              child: StreamBuilder<List<Plant>>(
                stream: _plantService.getUserPlants(_userId!),
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
                    onPress: () => showAddPlantDialog(context, _userId!),
                  ),
                  SizedBox(height: 12.h),
                  FButton(
                    label: const Text('View All Plants'),
                    prefix: const Icon(Icons.list),
                    style: FButtonStyle.outline,
                    onPress: () {
                      // Navigate to garden screen
                      setState(() {});
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
              plantCreatedAt: plant.createdAt,
              plantUpdatedAt: plant.updatedAt,
            ),
          ),
        );
      },
      child: VStack([
        Icon(Icons.local_florist, size: 50.sp, color: Colors.white),
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
          .width(140.w)
          .height(140.h)
          .shadowMd
          .make()
          .pOnly(right: 12.w),
    );
  }
}
