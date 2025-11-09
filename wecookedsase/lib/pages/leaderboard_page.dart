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

  Future<void> _addFriendDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final friendName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Enter friend’s display name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (friendName == null || friendName.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final query = await firestore
        .collection('users')
        .where('displayName', isEqualTo: friendName)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found with that name')),
      );
      return;
    }

    final friendDoc = query.docs.first;
    final friendId = friendDoc.id;

    await _friendService.sendFriendRequest(_currentUserId!, friendId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to $friendName!')),
    );
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
            tooltip: 'Add Friend',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendPopup()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top 3 podium & leaderboard list stay the same
            _buildPodiumSection(),
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
          _buildPodiumCard(leaderboardData[1], 2),
          SizedBox(width: 10.w),
          _buildPodiumCard(leaderboardData[0], 1),
          SizedBox(width: 10.w),
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
