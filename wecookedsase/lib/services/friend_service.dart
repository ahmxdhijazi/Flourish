import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    // Prevent duplicate requests
    final existing = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Request already sent.');
    }

    await _firestore.collection('friend_requests').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    final doc = _firestore.collection('friend_requests').doc(requestId);

    await doc.update({
      'status': accept ? 'accepted' : 'declined',
    });

    if (accept) {
      final data = await doc.get();
      final senderId = data['senderId'];
      final receiverId = data['receiverId'];

      // Add both to friends list
      await _firestore.collection('users').doc(senderId).update({
        'friends': FieldValue.arrayUnion([receiverId]),
      });
      await _firestore.collection('users').doc(receiverId).update({
        'friends': FieldValue.arrayUnion([senderId]),
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getIncomingRequests(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
