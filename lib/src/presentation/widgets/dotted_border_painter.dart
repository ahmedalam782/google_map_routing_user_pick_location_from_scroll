import 'package:flutter/material.dart';
import 'dart:math' as math;

class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashLength = 3;
    const gapLength = 3;
    const borderRadius = 12.0;

    // Draw dotted straight edges
    // Top edge
    for (double x = borderRadius;
        x < size.width - borderRadius;
        x += dashLength + gapLength) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashLength, 0), paint);
    }

    // Right edge
    for (double y = borderRadius;
        y < size.height - borderRadius;
        y += dashLength + gapLength) {
      canvas.drawLine(
        Offset(size.width, y),
        Offset(size.width, y + dashLength),
        paint,
      );
    }

    // Bottom edge
    for (double x = size.width - borderRadius;
        x > borderRadius;
        x -= dashLength + gapLength) {
      canvas.drawLine(
        Offset(x - dashLength, size.height),
        Offset(x, size.height),
        paint,
      );
    }

    // Left edge
    for (double y = size.height - borderRadius;
        y > borderRadius;
        y -= dashLength + gapLength) {
      canvas.drawLine(Offset(0, y - dashLength), Offset(0, y), paint);
    }

    // Draw dotted corner arcs
    _drawDottedArc(
      canvas,
      Offset(size.width - borderRadius, borderRadius),
      borderRadius,
      -math.pi / 2,
      math.pi / 2,
      paint,
    );

    _drawDottedArc(
      canvas,
      Offset(size.width - borderRadius, size.height - borderRadius),
      borderRadius,
      0,
      math.pi / 2,
      paint,
    );

    _drawDottedArc(
      canvas,
      Offset(borderRadius, size.height - borderRadius),
      borderRadius,
      math.pi / 2,
      math.pi / 2,
      paint,
    );

    _drawDottedArc(
      canvas,
      const Offset(borderRadius, borderRadius),
      borderRadius,
      math.pi,
      math.pi / 2,
      paint,
    );
  }

  void _drawDottedArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    Paint paint,
  ) {
    const dashLength = 3;
    const gapLength = 3;

    // Calculate arc length
    final arcLength = radius * sweepAngle;
    final steps = (arcLength / (dashLength + gapLength)).ceil();
    final stepAngle = sweepAngle / steps;

    for (int i = 0; i < steps; i++) {
      final startArcAngle = startAngle + i * stepAngle;
      final endArcAngle = startAngle +
          i * stepAngle +
          stepAngle * dashLength / (dashLength + gapLength);

      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          startArcAngle,
          endArcAngle - startArcAngle,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
