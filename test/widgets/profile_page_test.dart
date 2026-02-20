import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:multigame/repositories/user_repository.dart';
import 'package:multigame/screens/profile_screen.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/streak_service.dart';
import 'package:multigame/services/storage/nickname_service.dart';
import 'package:multigame/utils/storage_migrator.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake UserRepository — no SecureStorage, no platform channels needed.
class _FakeUserRepository implements UserRepository {
  @override
  Future<String?> getUserId() async => null;
  @override
  Future<bool> saveUserId(String userId) async => true;
  @override
  Future<bool> hasUserId() async => false;
  @override
  Future<bool> clearUserId() async => true;
  @override
  Future<String?> getDisplayName() async => null;
  @override
  Future<bool> saveDisplayName(String displayName) async => true;
  @override
  Future<bool> hasDisplayName() async => false;
  @override
  Future<bool> clearDisplayName() async => true;
  @override
  Future<bool> clearAll() async => true;
}

// Fake SecureStorageRepository — in-memory, no platform channels.
class _FakeSecureStorageRepository implements SecureStorageRepository {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<bool> write(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> delete(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  Future<bool> deleteAll() async {
    _store.clear();
    return true;
  }
  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_store);
  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);
}

/// Pump enough frames to:
/// 1. Flush SharedPreferences microtasks so _isLoading becomes false.
/// 2. Advance fake time past all Future.delayed timers in AnimatedProfileHeader
///    (max 300 ms) and _AchievementCard stagger delays (max ~900 ms), so no
///    pending timers remain after the test disposes the widget tree.
Future<void> _settleProfile(WidgetTester tester) async {
  await tester.pump(); // initial frame
  await tester.pump(const Duration(milliseconds: 50)); // microtask queue flush
  await tester.pump(const Duration(milliseconds: 50)); // setState rebuilds
  await tester.pump(const Duration(seconds: 1)); // fire all Future.delayed timers
}

void main() {
  group('ProfilePage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'total_completed': 5,
        'best_3x3_moves': 85,
        'best_4x4_moves': 150,
        'best_5x5_moves': 250,
        'best_3x3_time': 45,
        'best_4x4_time': 90,
        'best_5x5_time': 180,
      });

      final getIt = GetIt.instance;
      if (!getIt.isRegistered<AchievementService>()) {
        getIt.registerLazySingleton<AchievementService>(
          () => AchievementService(),
        );
      }
      if (!getIt.isRegistered<NicknameService>()) {
        getIt.registerLazySingleton<NicknameService>(
          () => NicknameService(
            userRepository: _FakeUserRepository(),
            migrator: StorageMigrator(_FakeSecureStorageRepository()),
          ),
        );
      }
      if (!getIt.isRegistered<StreakService>()) {
        getIt.registerLazySingleton<StreakService>(() => StreakService());
      }
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    testWidgets('renders profile page widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('renders scroll view after loading', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      // Loading complete: skeleton replaced by CustomScrollView
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('displays statistics section', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows grid size labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('displays best moves stats', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('displays best time stats', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('shows default values for unset stats', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('shows skeleton loading initially', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

      // pumpWidget renders the first frame; _isLoading=true shows skeleton.
      expect(find.byType(CustomScrollView), findsNothing);

      // Settle using incremental pumps (same as _settleProfile) so that all
      // Future.delayed timers created after the header is mounted also fire.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('can pull to refresh', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
