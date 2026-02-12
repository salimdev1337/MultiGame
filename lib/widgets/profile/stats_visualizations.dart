import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:multigame/design_system/design_system.dart';

/// Simple line chart for performance over time
class PerformanceChart extends StatefulWidget {
  const PerformanceChart({
    super.key,
    required this.dataPoints,
    required this.labels,
    this.title = 'Performance Trend',
    this.color,
  });

  final List<double> dataPoints;
  final List<String> labels;
  final String title;
  final Color? color;

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slower,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? DSColors.primary;

    return Container(
      padding: EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSSpacing.md),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: DSTypography.titleMedium.copyWith(
              color: DSColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DSSpacing.md),
          SizedBox(
            height: 150,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: LineChartPainter(
                    dataPoints: widget.dataPoints,
                    labels: widget.labels,
                    color: color,
                    progress: _animation.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Line chart painter
class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final Color color;
  final double progress;

  LineChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final maxValue = dataPoints.reduce(math.max);
    final minValue = dataPoints.reduce(math.min);
    final range = maxValue - minValue;

    final points = <Offset>[];
    final spacing = size.width / (dataPoints.length - 1);

    // Calculate points
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final normalizedValue = range > 0 ? (dataPoints[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.8) - 20;
      points.add(Offset(x, y));
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = DSColors.textTertiary.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw gradient fill
    if (progress > 0) {
      final path = Path();
      path.moveTo(0, size.height);

      for (int i = 0; i < points.length; i++) {
        if (i / points.length <= progress) {
          if (i == 0) {
            path.lineTo(points[i].dx, points[i].dy);
          } else {
            path.lineTo(points[i].dx, points[i].dy);
          }
        }
      }

      path.lineTo(size.width * progress, size.height);
      path.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, gradientPaint);
    }

    // Draw line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      if (i / points.length <= progress) {
        if (i == 0) {
          linePath.moveTo(points[i].dx, points[i].dy);
        } else {
          linePath.lineTo(points[i].dx, points[i].dy);
        }
      }
    }

    canvas.drawPath(linePath, linePaint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      if (i / points.length <= progress) {
        canvas.drawCircle(points[i], 4, pointPaint);
        canvas.drawCircle(
          points[i],
          6,
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Draw labels
    final textStyle = TextStyle(
      color: DSColors.textTertiary,
      fontSize: 10,
    );

    for (int i = 0; i < labels.length; i++) {
      if (i / labels.length <= progress) {
        final textSpan = TextSpan(text: labels[i], style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(points[i].dx - textPainter.width / 2, size.height - 15),
        );
      }
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Heat map for play activity
class ActivityHeatMap extends StatefulWidget {
  const ActivityHeatMap({
    super.key,
    required this.activityData,
    this.weeksToShow = 12,
  });

  final Map<DateTime, int> activityData; // Date -> games played
  final int weeksToShow;

  @override
  State<ActivityHeatMap> createState() => _ActivityHeatMapState();
}

class _ActivityHeatMapState extends State<ActivityHeatMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slower,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSSpacing.md),
        border: Border.all(
          color: DSColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity',
                style: DSTypography.titleMedium.copyWith(
                  color: DSColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _HeatMapLegend(),
            ],
          ),
          SizedBox(height: DSSpacing.md),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(double.infinity, 120),
                painter: HeatMapPainter(
                  activityData: widget.activityData,
                  weeksToShow: widget.weeksToShow,
                  progress: _animation.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Heat map legend
class _HeatMapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Less',
          style: DSTypography.labelSmall.copyWith(
            color: DSColors.textTertiary,
          ),
        ),
        SizedBox(width: DSSpacing.xs),
        ...List.generate(5, (index) {
          return Container(
            width: 12,
            height: 12,
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _getHeatMapColor(index / 4),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        SizedBox(width: DSSpacing.xs),
        Text(
          'More',
          style: DSTypography.labelSmall.copyWith(
            color: DSColors.textTertiary,
          ),
        ),
      ],
    );
  }

  static Color _getHeatMapColor(double intensity) {
    if (intensity == 0) return DSColors.surface;
    return DSColors.success.withValues(
      alpha: (0.3 + intensity * 0.7).clamp(0.0, 1.0),
    );
  }
}

/// Heat map painter
class HeatMapPainter extends CustomPainter {
  final Map<DateTime, int> activityData;
  final int weeksToShow;
  final double progress;

  HeatMapPainter({
    required this.activityData,
    required this.weeksToShow,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = 12.0;
    final spacing = 4.0;
    final now = DateTime.now();

    // Calculate max activity for normalization
    final maxActivity = activityData.values.isEmpty
        ? 1
        : activityData.values.reduce(math.max);

    // Draw cells for past weeks
    int cellIndex = 0;
    final totalCells = weeksToShow * 7;

    for (int week = weeksToShow - 1; week >= 0; week--) {
      for (int day = 0; day < 7; day++) {
        final date = now.subtract(Duration(days: week * 7 + (6 - day)));
        final dateKey = DateTime(date.year, date.month, date.day);
        final activity = activityData[dateKey] ?? 0;
        final intensity = maxActivity > 0 ? activity / maxActivity : 0.0;

        // Calculate position
        final x = (weeksToShow - 1 - week) * (cellSize + spacing);
        final y = day * (cellSize + spacing);

        // Only draw if within progress
        if (cellIndex / totalCells <= progress) {
          final paint = Paint()
            ..color = _getHeatMapColor(intensity)
            ..style = PaintingStyle.fill;

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, cellSize, cellSize),
              const Radius.circular(2),
            ),
            paint,
          );
        }

        cellIndex++;
      }
    }

    // Draw day labels
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final textStyle = TextStyle(
      color: DSColors.textTertiary,
      fontSize: 10,
    );

    for (int i = 0; i < days.length; i++) {
      final textSpan = TextSpan(text: days[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-20, i * (cellSize + spacing)),
      );
    }
  }

  Color _getHeatMapColor(double intensity) {
    if (intensity == 0) return DSColors.surface;
    return DSColors.success.withValues(
      alpha: (0.3 + intensity * 0.7).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(HeatMapPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Win rate circular chart
class WinRateChart extends StatefulWidget {
  const WinRateChart({
    super.key,
    required this.winRate,
    this.size = 120,
  });

  final double winRate; // 0.0 to 1.0
  final double size;

  @override
  State<WinRateChart> createState() => _WinRateChartState();
}

class _WinRateChartState extends State<WinRateChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slower,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.winRate).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: CircularChartPainter(
                  progress: _animation.value,
                  color: DSColors.success,
                ),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    '${(_animation.value * 100).toInt()}%',
                    style: DSTypography.headlineMedium.copyWith(
                      color: DSColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              Text(
                'Win Rate',
                style: DSTypography.labelSmall.copyWith(
                  color: DSColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular chart painter
class CircularChartPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularChartPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = DSColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularChartPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
