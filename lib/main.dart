import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:multigame/providers/puzzle_game_provider.dart';
import 'package:multigame/providers/game_2048_provider.dart';
import 'package:multigame/providers/snake_game_provider.dart';
import 'package:multigame/providers/user_auth_provider.dart';
import 'package:multigame/screens/main_navigation.dart';
import 'package:multigame/services/nickname_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF21242b),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserAuthProvider()),
        ChangeNotifierProvider(create: (_) => PuzzleGameNotifier()),
        ChangeNotifierProvider(create: (_) => Game2048Provider()),
        ChangeNotifierProvider(create: (_) => SnakeGameProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Multi Game',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF16181d),
          primaryColor: const Color(0xFF00d4ff),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00d4ff),
            secondary: Color(0xFFff5c00),
            surface: Color(0xFF21242b),
          ),
        ),
        home: const FirebaseInitializer(),
      ),
    );
  }
}

/// Widget that initializes Firebase and shows loading screen
class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({super.key});

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final nicknameService = NicknameService();

      // Always sign in to Firebase (needed for Firestore access)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('🔐 Signed in to Firebase anonymously');
      }

      // Check if we have a persistent userId saved
      final savedUserId = await nicknameService.getUserId();

      if (savedUserId != null) {
        // User has played before - keep using their saved persistent ID
        debugPrint(
          '✅ Returning user - using saved persistent ID: $savedUserId',
        );
        debugPrint(
          '   (Firebase Auth userId: ${FirebaseAuth.instance.currentUser?.uid})',
        );
      } else {
        // First time user - save current Firebase userId as persistent ID
        final firebaseUserId = FirebaseAuth.instance.currentUser?.uid;
        if (firebaseUserId != null) {
          await nicknameService.saveUserId(firebaseUserId);
          debugPrint('🆕 New user - saved persistent ID: $firebaseUserId');
        }
      }

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      setState(() {
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize app'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = false;
                    _initialized = false;
                  });
                  _initializeFirebase();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              const Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return const MainNavigation();
  }
}
