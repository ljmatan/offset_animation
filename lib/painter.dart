import 'package:flutter/material.dart';

// Custom painter drawing of a shrinking line
class TrailPainter extends CustomPainter {
  final List<Offset> points;

  TrailPainter(this.points);

  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i],
          points[i + 1],
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 10 * (i / points.length)
            ..color = const Color(0xffffffff),
        );
      }
    }
  }

  bool shouldRepaint(TrailPainter other) => other.points != points;
}
