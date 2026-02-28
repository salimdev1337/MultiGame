import 'package:flutter/material.dart';

class TunisianBackground extends StatelessWidget {
  const TunisianBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/rummy_table_bg.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.28),
            ],
            stops: const [0.55, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}
