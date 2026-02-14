import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multigame/models/challenge.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Manages head-to-head challenges via Firestore.
///
/// Firebase schema:
///   /challenges/{challengeId} — Challenge documents
class ChallengeService {
  ChallengeService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const Duration _challengeExpiry = Duration(hours: 48);

  // ── Create / Respond ──────────────────────────────────────────────────────

  Future<String> createChallenge({
    required String challengerId,
    required String challengerName,
    required String challengedId,
    required String challengedName,
    required String gameType,
  }) async {
    final ref = _db.collection('challenges').doc();
    final now = DateTime.now();
    await ref.set({
      'challenger': challengerId,
      'challengerName': challengerName,
      'challenged': challengedId,
      'challengedName': challengedName,
      'gameType': gameType,
      'status': 'pending',
      'challengerScore': null,
      'challengedScore': null,
      'winner': null,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(_challengeExpiry)),
    });
    SecureLogger.log(
      'Challenge created: $challengerId vs $challengedId ($gameType)',
      tag: 'Social',
    );
    return ref.id;
  }

  Future<void> acceptChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'status': 'active',
    });
  }

  Future<void> declineChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'status': 'expired',
    });
  }

  // ── Score Submission ──────────────────────────────────────────────────────

  Future<void> submitScore({
    required String challengeId,
    required String userId,
    required String challengerId,
    required int score,
  }) async {
    final isChallenger = userId == challengerId;
    final field = isChallenger ? 'challengerScore' : 'challengedScore';

    await _db.collection('challenges').doc(challengeId).update({field: score});

    // Check if both scores are in — determine winner
    final doc = await _db.collection('challenges').doc(challengeId).get();
    final data = doc.data()!;
    final cScore = data['challengerScore'] as int?;
    final dScore = data['challengedScore'] as int?;

    if (cScore != null && dScore != null) {
      final winner = cScore >= dScore
          ? data['challenger'] as String
          : data['challenged'] as String;
      await _db.collection('challenges').doc(challengeId).update({
        'status': 'completed',
        'winner': winner,
      });
      SecureLogger.log(
        'Challenge $challengeId completed. Winner: $winner',
        tag: 'Social',
      );
    }
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<Challenge>> getMyChallenges(String userId) async {
    final asChallenger = await _db
        .collection('challenges')
        .where('challenger', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final asChallenged = await _db
        .collection('challenges')
        .where('challenged', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final all = {...asChallenger.docs, ...asChallenged.docs};
    return all.map(_docToChallenge).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<Challenge>> challengesStream(String userId) {
    return _db
        .collection('challenges')
        .where('challenger', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(_docToChallenge).toList());
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Challenge _docToChallenge(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      challengerId: data['challenger'] as String,
      challengerName: data['challengerName'] as String? ?? 'Player',
      challengedId: data['challenged'] as String,
      challengedName: data['challengedName'] as String? ?? 'Player',
      gameType: data['gameType'] as String,
      status: ChallengeStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ChallengeStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 48)),
      challengerScore: data['challengerScore'] as int?,
      challengedScore: data['challengedScore'] as int?,
      winnerId: data['winner'] as String?,
    );
  }
}
