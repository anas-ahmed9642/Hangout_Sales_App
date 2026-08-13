import 'dart:math';
import 'package:flutter/material.dart';

/// Draws a procedural sun-warmed terracotta plaster wall texture —
/// evoking an Italian pizzeria's exposed brick/plaster, with warm
/// golden sunlight falling across it from one corner.
/// Fully original — no images, no external assets.
class CastleWallPainter extends CustomPainter {
  final Color stoneColor;
  final Color mortarColor;
  final Color sunColor;
  final int seed;

  CastleWallPainter({
    this.stoneColor = const Color(0xFFC97B4A), // warm terracotta
    this.mortarColor = const Color(0xFF8C5A3B), // deeper clay/mortar
    this.sunColor = const Color(0xFFD4AF37), // gold, unchanged
    this.seed = 11,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);

    // ---- 1. Terracotta block/brick pattern ----
    const double blockHeight = 42;
    const double blockWidthBase = 88;

    final mortarPaint = Paint()
      ..color = mortarColor.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final stonePaint = Paint()..style = PaintingStyle.fill;

    int row = 0;
    for (double y = 0; y < size.height; y += blockHeight) {
      final rowOffset = (row.isEven) ? 0.0 : blockWidthBase / 2;
      double x = -blockWidthBase + rowOffset;

      while (x < size.width) {
        final widthJitter = blockWidthBase + (random.nextDouble() - 0.5) * 18;
        final rect = Rect.fromLTWH(x, y, widthJitter, blockHeight);

        // Warmer tonal variation per brick — some slightly redder, some more ochre
        final shade = 0.025 + random.nextDouble() * 0.04;
        stonePaint.color = stoneColor.withOpacity(shade);
        canvas.drawRect(rect, stonePaint);
        canvas.drawRect(rect, mortarPaint);

        x += widthJitter;
      }
      row++;
    }

    // ---- 2. Warm directional sunlight glow (from top-right corner) ----
    final sunlightRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final sunGradient = RadialGradient(
      center: const Alignment(0.85, -0.85),
      radius: 1.3,
      colors: [
        sunColor.withOpacity(0.18),
        sunColor.withOpacity(0.06),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 1.0],
    );
    final sunPaint = Paint()..shader = sunGradient.createShader(sunlightRect);
    canvas.drawRect(sunlightRect, sunPaint);

    // ---- 3. Faint light-ray streaks radiating from the sun corner ----
    final rayOrigin = Offset(size.width * 0.92, size.height * -0.05);
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final angle = pi * (0.55 + i * 0.06);
      final length = size.longestSide * 1.1;
      final end = Offset(
        rayOrigin.dx + length * cos(angle),
        rayOrigin.dy + length * sin(angle),
      );

      rayPaint.shader = LinearGradient(
        colors: [
          sunColor.withOpacity(0.11),
          sunColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromPoints(rayOrigin, end));

      canvas.drawLine(rayOrigin, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CastleWallPainter oldDelegate) => false;
}