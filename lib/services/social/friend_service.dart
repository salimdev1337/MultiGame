import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multigame/models/friend.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Manages friend relationships via Firestore.
///
/// Firebase schema:
///   /users/{userId}/friends — list of friend user IDs
///   /friend_requests/{requestId} — FriendRequest documents
class FriendService {
  FriendService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── Friend Requests ───────────────────────────────────────────────────────

  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromDisplayName,
    required String toUserId,
  }) async {
    final ref = _db.collection('friend_requests').doc();
    await ref.set({
      'requestId': ref.id,
      'from': fromUserId,
      'fromDisplayName': fromDisplayName,
      'to': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    SecureLogger.log('Friend request sent to $toUserId', tag: 'Social');
  }

  Future<void> acceptFriendRequest(
      String requestId, String userId, String friendId) async {
    final batch = _db.batch();

    // Update request status
    batch.update(_db.collection('friend_requests').doc(requestId),
        {'status': 'accepted'});

    // Add to both users' friend lists
    batch.set(
      _db.collection('users').doc(userId).collection('friends').doc(friendId),
      {'friendId': friendId, 'addedAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db.collection('users').doc(friendId).collection('friends').doc(userId),
      {'friendId': userId, 'addedAt': FieldValue.serverTimestamp()},
    );

    await batch.commit();
    SecureLogger.log('Friend request $requestId accepted', tag: 'Social');
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _db
        .collection('friend_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _db.collection('friend_requests').doc(requestId).delete();
  }

  // ── Friends List ──────────────────────────────────────────────────────────

  Future<List<Friend>> getFriends(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();

    final friends = <Friend>[];
    for (final doc in snap.docs) {
      final friendId = doc.data()['friendId'] as String? ?? doc.id;
      final userDoc =
          await _db.collection('users').doc(friendId).get();
      if (!userDoc.exists) continue;
      final data = userDoc.data()!;
      friends.add(Friend(
        userId: friendId,
        displayName: data['displayName'] as String? ?? 'Player',
        avatarId: data['avatarId'] as String?,
        isOnline: data['isOnline'] as bool? ?? false,
        lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      ));
    }
    return friends;
  }

  Stream<List<Friend>> friendsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .asyncMap((_) => getFriends(userId));
  }

  Future<void> removeFriend(
      String userId, String friendId) async {
    final batch = _db.batch();
    batch.delete(
        _db.collection('users').doc(userId).collection('friends').doc(friendId));
    batch.delete(
        _db.collection('users').doc(friendId).collection('friends').doc(userId));
    await batch.commit();
  }

  // ── Online Status ─────────────────────────────────────────────────────────

  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await _db.collection('users').doc(userId).set(
      {
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<List<Friend>> searchUsers(String query) async {
    if (query.length < 2) return [];
    final snap = await _db
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: '${query}z')
        .limit(20)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return Friend(
        userId: doc.id,
        displayName: data['displayName'] as String? ?? 'Player',
        avatarId: data['avatarId'] as String?,
        isOnline: data['isOnline'] as bool? ?? false,
        lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  // ── Pending Requests ──────────────────────────────────────────────────────

  Future<List<FriendRequest>> getPendingRequests(String userId) async {
    final snap = await _db
        .collection('friend_requests')
        .where('to', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return FriendRequest(
        requestId: doc.id,
        fromUserId: data['from'] as String,
        fromDisplayName: data['fromDisplayName'] as String? ?? 'Player',
        status: FriendRequestStatus.pending,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }
}
