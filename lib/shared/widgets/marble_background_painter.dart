import 'dart:math';
import 'package:flutter/material.dart';

/// Crisp running-bond ashlar wall — matches the neoclassical "Stone & Gilt"
/// look (cream blocks, hairline joints). Each row is seeded independently so
/// the pattern stays put when the window resizes. A faint warm sunlight wash
/// from the top-right corner keeps the pizzeria warmth without any blur.
/// Fully original — no images, no external assets.
class CastleWallPainter extends CustomPainter {
  /// Light ashlar tone (the dominant block colour).
  final Color stoneColor;

  /// Joint line colour (also the base coat behind the blocks).
  final Color mortarColor;

  /// Warm gilt light for the corner glow.
  final Color sunColor;

  final int seed;

  const CastleWallPainter({
    this.stoneColor = const Color(0xFFFAF3E5), // stoneA
    this.mortarColor = const Color(0xFFE8DBBF), // joint
    this.sunColor = const Color(0xFFD4AF37),
    this.seed = 11,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const blockHeight = 46.0;

    // Base coat in the joint colour, so the hairline joints never show
    // whatever is painted underneath this wall.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = mortarColor,
    );

    // Slightly darker second stone tone, derived from [stoneColor].
    final stoneB = HSLColor.fromColor(stoneColor)
        .withLightness(
          (HSLColor.fromColor(stoneColor).lightness - 0.028).clamp(0.0, 1.0),
        )
        .toColor();

    final fillA = Paint()..color = stoneColor;
    final fillB = Paint()..color = stoneB;
    final joint = Paint()
      ..color = mortarColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    var row = 0;

    for (double y = 0; y < size.height; y += blockHeight) {
      // Per-row seed: identical layout at any window size, no shimmer.
      final random = Random(seed + row * 7919);
      var x = -(random.nextDouble() * 80);

      while (x < size.width) {
        final width = 90 + random.nextDouble() * 60;
        final rect = Rect.fromLTWH(x, y, width, blockHeight);

        canvas.drawRect(rect, random.nextBool() ? fillA : fillB);
        canvas.drawRect(rect, joint);

        x += width;
      }

      row++;
    }

    // Faint warm sunlight from the top-right corner — subtle enough to read
    // as light, not as haze. Drop this whole block for an exact match with
    // the Manage Catalog screen.
    final wallRect = Offset.zero & size;
    final sunPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.85),
        radius: 1.3,
        colors: [
          sunColor.withOpacity(0.07),
          sunColor.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(wallRect);
    canvas.drawRect(wallRect, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CastleWallPainter oldDelegate) {
    return oldDelegate.stoneColor != stoneColor ||
        oldDelegate.mortarColor != mortarColor ||
        oldDelegate.sunColor != sunColor ||
        oldDelegate.seed != seed;
  }
}