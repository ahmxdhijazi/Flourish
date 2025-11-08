import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

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
          home: const MainNavigation(),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Camera action
          debugPrint('Camera button pressed');
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
            height: 60.h,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSelected ? 12.sp : 11.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.deepPurple : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

            // Featured Cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                "Your Plants",
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10.h),

            SizedBox(
              height: 160.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _buildFeatureCard("Plant 1", Icons.local_florist, Colors.orange),
                  _buildFeatureCard("Plant 2", Icons.local_florist, Colors.red),
                  _buildFeatureCard("Plant 3", Icons.local_florist, Colors.green),
                ],
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
                    label: const Text('Quick Action 1'),
                    prefix: const Icon(Icons.add),
                    style: FButtonStyle.outline,
                    onPress: () {},
                  ),
                  SizedBox(height: 12.h),
                  FButton(
                    label: const Text('Quick Action 2'),
                    prefix: const Icon(Icons.favorite),
                    style: FButtonStyle.outline,
                    onPress: () {},
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

  Widget _buildFeatureCard(String title, IconData icon, Color color) {
    return VStack([
      Icon(icon, size: 50.sp, color: Colors.white),
      10.h.heightBox,
      Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
        textAlign: TextAlign.center,
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
        .pOnly(right: 12.w);
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