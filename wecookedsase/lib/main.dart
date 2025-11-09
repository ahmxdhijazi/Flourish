import 'package:flutter/material.dart';
import 'screen/camera_screen.dart';
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
    LeaderBoard(),
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
    } else {
      // User is signed in, open camera
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onCameraButtonPressed(context),
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
          "WeCooked",
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Button to create sample plants for testing
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await _plantService.createSamplePlants(_userId!);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Sample plants created!')),
              );
            },
          ),
        ],
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
                        int.parse(plant.colorHex.replaceFirst('#', '0xFF'))
                      );
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
                    onPress: () async {
                      // Add a new plant
                      await _plantService.addPlant(
                        Plant(
                          name: 'New Plant ${DateTime.now().millisecond}',
                          description: 'A newly added plant',
                          colorHex: '#2196F3',
                        ),
                        _userId!,
                      );
                    },
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
              plantName: plant.name,
              plantIcon: Icons.local_florist,
              plantColor: color,
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
      ], alignment: MainAxisAlignment.center, crossAlignment: CrossAxisAlignment.center)
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

// LeaderBoard Screen
class LeaderBoard extends StatelessWidget {
  const LeaderBoard({super.key});

  // Placeholder data
  final List<Map<String, dynamic>> leaderboardData = const [
    {'rank': 1, 'name': 'Alice Johnson', 'score': 2850, 'avatar': '🥇'},
    {'rank': 2, 'name': 'Bob Smith', 'score': 2720, 'avatar': '🥈'},
    {'rank': 3, 'name': 'Carol Davis', 'score': 2580, 'avatar': '🥉'},
    {'rank': 4, 'name': 'David Wilson', 'score': 2340, 'avatar': '👤'},
    {'rank': 5, 'name': 'Emma Brown', 'score': 2190, 'avatar': '👤'},
    {'rank': 6, 'name': 'Frank Miller', 'score': 2050, 'avatar': '👤'},
    {'rank': 7, 'name': 'Grace Lee', 'score': 1920, 'avatar': '👤'},
    {'rank': 8, 'name': 'Henry Chen', 'score': 1780, 'avatar': '👤'},
    {'rank': 9, 'name': 'Ivy Martinez', 'score': 1650, 'avatar': '👤'},
    {'rank': 10, 'name': 'Jack Taylor', 'score': 1520, 'avatar': '👤'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Leaderboard",
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
          children: [
            // Top 3 Podium Section
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.deepPurple,
                    Colors.purple.shade300,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPodiumCard(leaderboardData[1], 2),
                  SizedBox(width: 10.w),
                  _buildPodiumCard(leaderboardData[0], 1),
                  SizedBox(width: 10.w),
                  _buildPodiumCard(leaderboardData[2], 3),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Rest of the leaderboard
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: leaderboardData
                    .skip(3)
                    .map((entry) => _buildLeaderboardTile(entry))
                    .toList(),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> entry, int rank) {
    final height = rank == 1 ? 120.h : rank == 2 ? 100.h : 90.h;
    final medalColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey.shade300
            : Colors.orange.shade300;

    return Column(
      children: [
        Container(
          width: 80.w,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                entry['avatar'],
                style: TextStyle(fontSize: 32.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                entry['name'].toString().split(' ')[0],
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                '${entry['score']} pts',
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 80.w,
          height: height,
          decoration: BoxDecoration(
            color: medalColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry['rank']}',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Avatar & Name
          Expanded(
            child: Row(
              children: [
                Text(
                  entry['avatar'],
                  style: TextStyle(fontSize: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${entry['score']} points',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Trophy icon for top 10
          if (entry['rank'] <= 10)
            Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 24.sp,
            ),
        ],
      ),
    );
  }
}

// Garden Screen
class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "All Plants",
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(8.w),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                ),
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plant ${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Plant Details go here',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Plant Details",
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FButton(
                            label: const Text('View'),
                            style: FButtonStyle.outline,
                            onPress: () {},
                          ),
                          SizedBox(width: 8.w),
                          FButton(
                            label: const Text('Favorite'),
                            prefix: const Icon(Icons.favorite_border),
                            style: FButtonStyle.primary,
                            onPress: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}