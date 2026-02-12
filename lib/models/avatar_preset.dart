import 'package:flutter/material.dart';

/// An avatar option for the user's profile.
class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.name,
    this.isUnlocked = true,
  });

  final String id;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String name;
  final bool isUnlocked;

  static const List<AvatarPreset> defaults = [
    AvatarPreset(
      id: 'rocket',
      icon: Icons.rocket_launch_rounded,
      backgroundColor: Color(0xFF00d4ff),
      iconColor: Colors.white,
      name: 'Rocket',
    ),
    AvatarPreset(
      id: 'star',
      icon: Icons.star_rounded,
      backgroundColor: Color(0xFFffd700),
      iconColor: Colors.white,
      name: 'Star',
    ),
    AvatarPreset(
      id: 'fire',
      icon: Icons.local_fire_department_rounded,
      backgroundColor: Color(0xFFff6b35),
      iconColor: Colors.white,
      name: 'Fire',
    ),
    AvatarPreset(
      id: 'brain',
      icon: Icons.psychology_rounded,
      backgroundColor: Color(0xFFb14aed),
      iconColor: Colors.white,
      name: 'Brain',
    ),
    AvatarPreset(
      id: 'lightning',
      icon: Icons.bolt_rounded,
      backgroundColor: Color(0xFFFFD700),
      iconColor: Colors.white,
      name: 'Lightning',
    ),
    AvatarPreset(
      id: 'diamond',
      icon: Icons.diamond_rounded,
      backgroundColor: Color(0xFF00b4d8),
      iconColor: Colors.white,
      name: 'Diamond',
    ),
    AvatarPreset(
      id: 'trophy',
      icon: Icons.emoji_events_rounded,
      backgroundColor: Color(0xFFFFD700),
      iconColor: Colors.white,
      name: 'Trophy',
      isUnlocked: false,
    ),
    AvatarPreset(
      id: 'crown',
      icon: Icons.military_tech_rounded,
      backgroundColor: Color(0xFFFF6B35),
      iconColor: Colors.white,
      name: 'Crown',
      isUnlocked: false,
    ),
    AvatarPreset(
      id: 'ghost',
      icon: Icons.face_retouching_natural,
      backgroundColor: Color(0xFF52b788),
      iconColor: Colors.white,
      name: 'Ghost',
    ),
    AvatarPreset(
      id: 'alien',
      icon: Icons.sentiment_very_satisfied_rounded,
      backgroundColor: Color(0xFF39d353),
      iconColor: Colors.white,
      name: 'Alien',
    ),
    AvatarPreset(
      id: 'robot',
      icon: Icons.smart_toy_rounded,
      backgroundColor: Color(0xFF4cc9f0),
      iconColor: Colors.white,
      name: 'Robot',
    ),
    AvatarPreset(
      id: 'ninja',
      icon: Icons.sports_martial_arts_rounded,
      backgroundColor: Color(0xFF6d6875),
      iconColor: Colors.white,
      name: 'Ninja',
      isUnlocked: false,
    ),
  ];
}
