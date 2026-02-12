import 'dart:convert';
import 'package:multigame/models/daily_challenge.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Generates, stores, and tracks daily challenges.
///
/// Three challenges are generated each day at midnight.
/// Progress is persisted locally; completed challenges award XP via callback.
class DailyChallengeService {
  DailyChallengeService({required SecureStorageRepository storage})
      : _storage = storage;

  final SecureStorageRepository _storage;

  static const _challengesKey = 'daily_challenges_v1';
  static const _challengeDateKey = 'daily_challenges_date';

  // ── Templates used to generate daily challenges ───────────────────────────

  static const List<Map<String, dynamic>> _templates = [
    {
      'id': 'score_sudoku',
      'gameType': 'Sudoku',
      'title': 'Sudoku Master',
      'description': 'Complete a Sudoku puzzle',
      'type': 'playCount',
      'target': 1,
      'xp': 50,
    },
    {
      'id': 'score_2048',
      'gameType': '2048',
      'title': '2048 Challenge',
      'description': 'Score 2048 or higher',
      'type': 'score',
      'target': 2048,
      'xp': 75,
    },
    {
      'id': 'snake_streak',
      'gameType': 'Snake',
      'title': 'Snake Streak',
      'description': 'Play 3 Snake games',
      'type': 'playCount',
      'target': 3,
      'xp': 60,
    },
    {
      'id': 'puzzle_perfect',
      'gameType': 'Image Puzzle',
      'title': 'Perfect Puzzle',
      'description': 'Complete an image puzzle',
      'type': 'perfect',
      'target': 1,
      'xp': 80,
    },
    {
      'id': 'runner_distance',
      'gameType': 'Infinite Runner',
      'title': 'Distance Runner',
      'description': 'Run 1000 metres',
      'type': 'score',
      'target': 1000,
      'xp': 70,
    },
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns today's three challenges, generating them if needed.
  Future<List<DailyChallenge>> getTodayChallenges() async {
    final today = _todayKey();
    final savedDate = await _storage.read(_challengeDateKey);

    if (savedDate == today) {
      return _loadSavedChallenges();
    }

    // New day — generate fresh challenges
    return _generateAndSave(today);
  }

  /// Update progress for [challengeId]. Completes if target is reached.
  Future<DailyChallenge?> updateProgress(
      String challengeId, int newProgress) async {
    final challenges = await _loadSavedChallenges();
    final idx = challenges.indexWhere((c) => c.id == challengeId);
    if (idx < 0) return null;

    final challenge = challenges[idx];
    if (challenge.isCompleted) return challenge;

    final updated = challenge.copyWith(
      progress: newProgress,
      isCompleted: newProgress >= challenge.targetValue,
    );
    challenges[idx] = updated;

    await _saveChallenges(challenges);

    if (updated.isCompleted) {
      SecureLogger.log(
        'Daily challenge completed: ${updated.title} (+${updated.rewardXP} XP)',
        tag: 'Gamification',
      );
    }
    return updated;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<DailyChallenge> _generateAndSave(String dateKey) {
    final midnight = DateTime.now().copyWith(
        hour: 23, minute: 59, second: 59, millisecond: 999);

    // Pick 3 templates based on today's date seed
    final seed = DateTime.now().day % _templates.length;
    final picked = <Map<String, dynamic>>[];
    for (int i = 0; i < 3; i++) {
      picked.add(_templates[(seed + i) % _templates.length]);
    }

    final challenges = picked.map((t) {
      return DailyChallenge(
        id: '${t['id']}_$dateKey',
        gameType: t['gameType'] as String,
        title: t['title'] as String,
        description: t['description'] as String,
        type: DailyChallengeType.values.firstWhere(
          (e) => e.name == t['type'],
          orElse: () => DailyChallengeType.playCount,
        ),
        targetValue: t['target'] as int,
        rewardXP: t['xp'] as int,
        expiresAt: midnight,
      );
    }).toList();

    // Fire-and-forget save (we return synchronously from generator)
    _storage.write(_challengeDateKey, dateKey);
    _saveChallenges(challenges);

    SecureLogger.log(
      'Generated ${challenges.length} daily challenges for $dateKey',
      tag: 'Gamification',
    );
    return challenges;
  }

  Future<List<DailyChallenge>> _loadSavedChallenges() async {
    final raw = await _storage.read(_challengesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DailyChallenge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveChallenges(List<DailyChallenge> challenges) async {
    final encoded = jsonEncode(challenges.map((c) => c.toJson()).toList());
    await _storage.write(_challengesKey, encoded);
  }
}
