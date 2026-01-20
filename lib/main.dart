import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:multigame/providers/puzzle_game_provider.dart';
import 'package:multigame/providers/game_2048_provider.dart';
import 'package:multigame/providers/snake_game_provider.dart';
import 'package:multigame/screens/main_navigation.dart';

void main() {
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
        ChangeNotifierProvider(create: (_) => PuzzleGameNotifier()),
        ChangeNotifierProvider(create: (_) => Game2048Provider()),
        ChangeNotifierProvider(create: (_) => SnakeGameProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Puzzle Game',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF16181d),
          primaryColor: const Color(0xFF00d4ff),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00d4ff),
            secondary: Color(0xFFff5c00),
            surface: Color(0xFF21242b),
          ),
        ),
        home: const MainNavigation(),
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
      ),
    );
  }
}
