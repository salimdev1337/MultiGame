import 'package:flutter/material.dart';

class BossIntroOverlay extends StatefulWidget {
  const BossIntroOverlay({
    super.key,
    required this.bossName,
    required this.onComplete,
  });

  final String bossName;
  final VoidCallback onComplete;

  @override
  State<BossIntroOverlay> createState() => _BossIntroOverlayState();
}

class _BossIntroOverlayState extends State<BossIntroOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _barExpand;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.4, curve: Curves.easeIn),
    );
    _barExpand = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );
    _ctrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          color: Colors.black.withValues(alpha: 0.85),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeIn,
                child: const Text(
                  'A boss appears!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fadeIn,
                child: Text(
                  widget.bossName.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFCC2200),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(color: Color(0xFFFF4400), blurRadius: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizeTransition(
                sizeFactor: _barExpand,
                axis: Axis.horizontal,
                axisAlignment: -1,
                child: Container(
                  height: 6,
                  width: 300,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCC2200), Color(0xFFFF6600)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
