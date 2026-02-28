import 'package:flutter/rendering.dart';

const _kRedDark = Color(0xFFB71C1C);
const _kRedMid = Color(0xFFD32F2F);
const _kWhite = Color(0xFFFFFEFA);
const _kBorder = Color(0xFF8B0000);

// Static Paint objects — allocated once at startup.
final _paintBg = Paint()..color = _kRedDark;
final _paintBorder = Paint()
  ..color = _kBorder
  ..style = PaintingStyle.stroke
  ..strokeWidth = 0.8;
final _paintInnerBorder = Paint()
  ..color = _kWhite
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.2;
final _paintOvalFill = Paint()..color = _kRedDark;
final _paintOvalStroke = Paint()
  ..color = _kWhite
  ..style = PaintingStyle.stroke
  ..strokeWidth = 0.8;

void paintCardBack(Canvas canvas, Size size, RRect rRect) {
  canvas.drawRRect(rRect, _paintBg);

  canvas.drawRRect(rRect, _paintBorder);

  final margin = size.width * 0.08;
  final innerRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2),
    const Radius.circular(3),
  );

  canvas.drawRRect(innerRect, _paintInnerBorder);

  final innerFill = Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2);

  canvas.save();
  canvas.clipRRect(innerRect);

  final latticePaint = Paint()
    ..color = _kRedMid.withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.6;

  final spacing = size.width * 0.35;
  final diag = size.width + size.height;
  for (var d = -diag; d < diag; d += spacing) {
    canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), latticePaint);
    canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), latticePaint);
  }

  final dotPaint = Paint()..color = _kWhite.withValues(alpha: 0.15);
  for (var y = spacing / 2; y < size.height; y += spacing / 2) {
    for (var x = spacing / 2; x < size.width; x += spacing / 2) {
      canvas.drawCircle(Offset(x, y), 0.7, dotPaint);
    }
  }

  canvas.restore();

  final cx = size.width / 2;
  final cy = size.height / 2;
  final ovalW = innerFill.width * 0.5;
  final ovalH = innerFill.height * 0.3;

  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, cy), width: ovalW, height: ovalH),
    _paintOvalFill,
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, cy), width: ovalW, height: ovalH),
    _paintOvalStroke,
  );

  final diamondPath = Path()
    ..moveTo(cx, cy - ovalH * 0.3)
    ..lineTo(cx + ovalW * 0.18, cy)
    ..lineTo(cx, cy + ovalH * 0.3)
    ..lineTo(cx - ovalW * 0.18, cy)
    ..close();
  canvas.drawPath(diamondPath, Paint()..color = _kWhite.withValues(alpha: 0.5));
}
