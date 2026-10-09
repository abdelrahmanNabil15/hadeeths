import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A quiet eight-fold star lattice (two overlapping squares at each point of a square grid, with a
/// small diamond between them), drawn in thin lines. Decoration only: it is hidden from screen
/// readers, never animates, is painted once into its own layer, and is never placed behind reading
/// text. Keep [color] faint (the callers use 4 to 8% opacity).
class GeometricPattern extends StatelessWidget {
  const GeometricPattern({
    super.key,
    required this.color,
    this.tileSize = 56,
    this.strokeWidth = 1,
  });

  final Color color;
  final double tileSize;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: StarLatticePainter(
          color: color,
          tileSize: tileSize,
          strokeWidth: strokeWidth,
        ),
        size: Size.infinite,
      ),
    ),
  );
}

class StarLatticePainter extends CustomPainter {
  const StarLatticePainter({
    required this.color,
    required this.tileSize,
    required this.strokeWidth,
  });

  final Color color;
  final double tileSize;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    final star = tileSize * 0.36;
    final diamond = tileSize * 0.12;
    final columns = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final centre = Offset(column * tileSize, row * tileSize);
        canvas.drawPath(eightPointStar(centre, star), paint);
        canvas.drawPath(
          _diamond(centre + Offset(tileSize / 2, tileSize / 2), diamond),
          paint,
        );
      }
    }
  }

  static Path _diamond(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r, c.dy)
    ..close();

  @override
  bool shouldRepaint(StarLatticePainter old) =>
      old.color != color ||
      old.tileSize != tileSize ||
      old.strokeWidth != strokeWidth;
}

/// The outline of an eight-pointed star (two squares, one turned 45 degrees) of circumradius [r].
Path eightPointStar(Offset centre, double r) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    // Alternate outer points and the inner corners where the two squares cross.
    final radius = i.isEven
        ? r
        : r * math.cos(math.pi / 4) / math.cos(math.pi / 8);
    final angle = -math.pi / 2 + i * math.pi / 8;
    final point = centre + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}
