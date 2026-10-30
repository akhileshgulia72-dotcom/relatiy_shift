import 'package:flutter/material.dart';

class ConstellationPainter extends CustomPainter {
  final List<Offset> points;

  ConstellationPainter(this.points);

 @override
void paint(Canvas canvas, Size size) {
  if (points.length < 2) return;

  final glow = Paint()
    ..color = Colors.cyanAccent.withOpacity(0.35)
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      15,
    );

  final line = Paint()
    ..color = Colors.white
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

  for (int i = 0; i < points.length - 1; i++) {
    canvas.drawLine(points[i], points[i + 1], glow);
    canvas.drawLine(points[i], points[i + 1], line);
  }
}
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}