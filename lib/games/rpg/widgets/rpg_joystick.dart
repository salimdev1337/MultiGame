import 'package:flutter/material.dart';

class RpgJoystick extends StatefulWidget {
  const RpgJoystick({super.key, required this.onChanged});

  final void Function(double dx, double dy) onChanged;

  @override
  State<RpgJoystick> createState() => _RpgJoystickState();
}

class _RpgJoystickState extends State<RpgJoystick> {
  static const double _radius = 50;
  static const double _thumbRadius = 20;

  Offset _thumbOffset = Offset.zero;
  bool _active = false;
  int? _pointerId;

  void _handleUpdate(Offset localPos, Offset center) {
    final delta = localPos - center;
    final dist = delta.distance;
    final clamped = dist > _radius ? delta / dist * _radius : delta;
    setState(() => _thumbOffset = clamped);
    final dx = clamped.dx / _radius;
    final dy = clamped.dy / _radius;
    widget.onChanged(dx, dy);
  }

  void _handleRelease() {
    setState(() {
      _thumbOffset = Offset.zero;
      _active = false;
      _pointerId = null;
    });
    widget.onChanged(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final total = (_radius + _thumbRadius) * 2;
    final center = Offset(total / 2, total / 2);
    return SizedBox(
      width: total,
      height: total,
      child: Listener(
        onPointerDown: (e) {
          if (_pointerId == null) {
            _pointerId = e.pointer;
            _active = true;
            _handleUpdate(e.localPosition, center);
          }
        },
        onPointerMove: (e) {
          if (e.pointer == _pointerId) {
            _handleUpdate(e.localPosition, center);
          }
        },
        onPointerUp: (e) {
          if (e.pointer == _pointerId) {
            _handleRelease();
          }
        },
        onPointerCancel: (e) {
          if (e.pointer == _pointerId) {
            _handleRelease();
          }
        },
        child: CustomPaint(
          painter: _JoystickPainter(
            thumbOffset: _thumbOffset,
            active: _active,
            radius: _radius,
            thumbRadius: _thumbRadius,
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  const _JoystickPainter({
    required this.thumbOffset,
    required this.active,
    required this.radius,
    required this.thumbRadius,
  });

  final Offset thumbOffset;
  final bool active;
  final double radius;
  final double thumbRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Base circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0x44FFFFFF),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Thumb
    canvas.drawCircle(
      center + thumbOffset,
      thumbRadius,
      Paint()..color = active ? const Color(0xCCFFD700) : const Color(0x88FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      thumbOffset != old.thumbOffset || active != old.active;
}
