import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/friend_service.dart';

class FriendPopup extends StatefulWidget {
  const FriendPopup({super.key});

  @override
  State<FriendPopup> createState() => _FriendPopupState();
}

class _FriendPopupState extends State<FriendPopup> {
  final _auth = FirebaseAuth.instance;
  final _friendService = FriendService();
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friends',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Friend',
            onPressed: () => _showAddFriendDialog(context, userId),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Pending Requests Section ---
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _friendService.getIncomingRequests(userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) return const SizedBox(); // hide section

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Requests',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: requests.map((req) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('users')
                                .doc(req['senderId'])
                                .get(),
                            builder: (context, senderSnapshot) {
                              if (!senderSnapshot.hasData) {
                                return const ListTile(
                                    title: Text('Loading...'));
                              }

                              final senderData = senderSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                              final senderName =
                                  senderData?['displayName'] ?? 'Unknown User';

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(senderName),
                                  subtitle:
                                      const Text('sent you a friend request'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check,
                                            color: Colors.green),
                                        onPressed: () => _friendService
                                            .respondToRequest(req['id'], true),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () => _friendService
                                            .respondToRequest(req['id'], false),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // --- Friends List Section ---
              Text(
                'Your Friends',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(userId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final friends = List<String>.from(data['friends'] ?? []);

                  if (friends.isEmpty) {
                    return Text(
                      'No friends yet',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    );
                  }

                  return Column(
                    children: friends.map((id) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('users').doc(id).get(),
                        builder: (context, friendSnapshot) {
                          if (!friendSnapshot.hasData) {
                            return const ListTile(title: Text('Loading...'));
                          }

                          final friendData = friendSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          final friendName =
                              friendData?['displayName'] ?? 'Unknown User';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Icon(Icons.person_add_alt_1,
                                    color: Colors.white),
                              ),
                              title: Text(friendName),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Add Friend Popup ---
  Future<void> _showAddFriendDialog(
      BuildContext context, String? userId) async {
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
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    if (friendName == null || friendName.isEmpty) return;

    final query = await _firestore
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

    await _friendService.sendFriendRequest(userId!, friendId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to $friendName!')),
    );
  }
}
