import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle/screens/puzzle.dart';

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
  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Puzzle Game',
      theme: ThemeData.dark().copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF16181d),
        primaryColor: const Color(0xFF00d4ff),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00d4ff),
          secondary: Color(0xFFff5c00),
          surface: Color(0xFF21242b),
          background: Color(0xFF16181d),
        ),
      ),
      home: const PuzzlePage(),
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}
