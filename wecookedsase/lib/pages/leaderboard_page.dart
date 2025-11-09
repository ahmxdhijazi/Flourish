import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/friend_service.dart';
import 'friend_popup.dart';

class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({super.key});

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  final _friendService = FriendService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    if (_currentUserId == null) return;

    try {
      // 1️⃣ Get current user’s friends list
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
      friends.add(_currentUserId!); // include self

      if (friends.isEmpty) return;

      // 2️⃣ Fetch plants and analyses for these users
      final plantsQuery = await _firestore
          .collection('plants')
          .where('userId',
              whereIn: friends.length > 10 ? friends.sublist(0, 10) : friends)
          .get();

      final analysisQuery = await _firestore.collection('plant_analysis').get();

      // 3️⃣ Build map of plantId → overallScore
      final Map<String, double> plantScores = {};
      for (var doc in analysisQuery.docs) {
        final data = doc.data();
        final plantId = data['plantId'];
        final score = (data['overallScore'] ?? 0).toDouble();
        if (plantId != null) plantScores[plantId] = score;
      }

      // 4️⃣ Group scores by userId
      final Map<String, List<double>> userScores = {};
      for (var plant in plantsQuery.docs) {
        final data = plant.data();
        final userId = data['userId'];
        final plantId = plant.id;

        final score = plantScores[plantId] ?? 0.0;
        userScores.putIfAbsent(userId, () => []).add(score);
      }

      // 5️⃣ Calculate Flourish Score
      final leaderboard = <Map<String, dynamic>>[];

      for (var entry in userScores.entries) {
        final userId = entry.key;
        final scores = entry.value;

        // Fetch the user's name
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final name = userDoc.data()?['displayName'] ?? 'Unknown';

        final plantCount = scores.length;
        final avgScore =
            plantCount > 0 ? scores.reduce((a, b) => a + b) / plantCount : 0.0;

        // Weighted system: 70% quality (avg), 30% quantity
        final flourishScore = ((avgScore * 0.7) + (plantCount * 0.3)) * 10;
        final roundedScore = flourishScore.round();

        // Update user points in Firestore
        await _firestore.collection('users').doc(userId).set({
          'points': roundedScore,
        }, SetOptions(merge: true));

        // Check if this user already exists in leaderboard
        final existingIndex =
            leaderboard.indexWhere((entry) => entry['name'] == name);

        if (existingIndex != -1) {
          // If user already exists, keep the higher score
          final existingScore = int.parse(leaderboard[existingIndex]['score']);
          if (roundedScore > existingScore) {
            leaderboard[existingIndex]['score'] = roundedScore.toString();
          }
        } else {
          leaderboard.add({
            'name': name,
            'score': roundedScore.toString(),
            'avatar': '👤',
          });
        }
      }

      // 6️⃣ Sort by Flourish Score descending
      leaderboard.sort((a, b) =>
          double.parse(b['score']).compareTo(double.parse(a['score'])));

      // 7️⃣ Assign ranks + medals
      for (int i = 0; i < leaderboard.length; i++) {
        leaderboard[i]['rank'] = i + 1;
        leaderboard[i]['avatar'] = i == 0
            ? '🥇'
            : i == 1
                ? '🥈'
                : i == 2
                    ? '🥉'
                    : '👤';
      }

      setState(() {
        leaderboardData = leaderboard;
      });
    } catch (e) {
      debugPrint("❌ Error loading leaderboard: $e");
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Friends',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendPopup()),
              );
            },
          ),
        ],
      ),
      body: leaderboardData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (leaderboardData.length >= 3) _buildPodiumSection(),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: leaderboardData
                          .skip(3)
                          .map((entry) => _buildLeaderboardTile(entry))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPodiumSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade300],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (leaderboardData.length > 1)
            _buildPodiumCard(leaderboardData[1], 2),
          SizedBox(width: 10.w),
          _buildPodiumCard(leaderboardData[0], 1),
          SizedBox(width: 10.w),
          if (leaderboardData.length > 2)
            _buildPodiumCard(leaderboardData[2], 3),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> entry, int rank) {
    final height = rank == 1
        ? 120.h
        : rank == 2
            ? 100.h
            : 90.h;
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
              Text(entry['avatar'], style: TextStyle(fontSize: 32.sp)),
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
          Expanded(
            child: Row(
              children: [
                Text(entry['avatar'], style: TextStyle(fontSize: 24.sp)),
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
          if (entry['rank'] <= 10)
            Icon(Icons.emoji_events, color: Colors.amber, size: 24.sp),
        ],
      ),
    );
  }
}
