import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ludo_notifier.dart';

class LudoBombIndicator extends StatefulWidget {
  const LudoBombIndicator({
    super.key,
    required this.color,
    required this.size,
    required this.turnsLeft,
  });

  final Color color;
  final double size;
  final int turnsLeft;

  @override
  State<LudoBombIndicator> createState() => _LudoBombIndicatorState();
}

class _LudoBombIndicatorState extends State<LudoBombIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.25),
          border: Border.all(color: widget.color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 6,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.crisis_alert_rounded,
              size: widget.size * 0.55,
              color: widget.color,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: widget.size * 0.38,
                height: widget.size * 0.38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
                child: Center(
                  child: Text(
                    '${widget.turnsLeft}',
                    style: TextStyle(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Watches only [LudoGameState.turboOvershoot] and shows a brief snackbar
/// when turbo causes all tokens to overshoot with no valid move.
class LudoTurboOvershootListener extends ConsumerWidget {
  const LudoTurboOvershootListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      ludoProvider.select((s) => s.turboOvershoot),
      (_, overshot) {
        if (overshot) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turbo overshoot — no valid move!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
    return const SizedBox.shrink();
  }
}
