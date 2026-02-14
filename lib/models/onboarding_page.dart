import 'package:flutter/material.dart';

/// Model representing a single page in the onboarding tutorial
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final String? animationAsset; // For Lottie animations (future)

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.animationAsset,
  });

  /// Default onboarding pages for MultiGame
  static List<OnboardingPage> get defaultPages => [
    const OnboardingPage(
      title: 'Welcome to MultiGame',
      description:
          'Your ultimate gaming hub with 5+ exciting games all in one place',
      icon: Icons.sports_esports_rounded,
      primaryColor: Color(0xFF00d4ff), // Cyan
      secondaryColor: Color(0xFFff5c00), // Orange
    ),
    const OnboardingPage(
      title: 'Challenge Yourself',
      description:
          'Play Sudoku, Snake, 2048, Puzzle, and Infinite Runner. Track your progress and compete on leaderboards',
      icon: Icons.emoji_events_rounded,
      primaryColor: Color(0xFFff5c00), // Orange
      secondaryColor: Color(0xFF00d4ff), // Cyan
    ),
    const OnboardingPage(
      title: 'Unlock Achievements',
      description:
          'Complete challenges, earn badges, and show off your gaming skills',
      icon: Icons.military_tech_rounded,
      primaryColor: Color(0xFF00d4ff), // Cyan
      secondaryColor: Color(0xFFff5c00), // Orange
    ),
    const OnboardingPage(
      title: 'Compete Online',
      description:
          'Challenge friends in multiplayer Sudoku and climb the global leaderboards',
      icon: Icons.people_rounded,
      primaryColor: Color(0xFFff5c00), // Orange
      secondaryColor: Color(0xFF00d4ff), // Cyan
    ),
  ];
}
