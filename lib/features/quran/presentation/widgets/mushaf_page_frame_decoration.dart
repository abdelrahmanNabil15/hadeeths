import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';

/// The border round a page, in the manner of the Madinah mushaf: a heavy outer rule and a fine
/// inner one with a washed band between them, a square corner piece holding a star at each corner,
/// and a small medallion at the middle of each side. Drawn by the app, so it is sharp at any size
/// and follows the theme.
///
/// It adds [margin] on every side of [child] and never changes [child]'s own size, so a page reads
/// the same size framed or not; only the whole (page plus frame) is then fitted to the screen.
class MushafPageFrame extends StatelessWidget {
  const MushafPageFrame({super.key, required this.child, this.margin = 22});

  final Widget child;

  /// The frame's width on each side, in the page's own units.
  final double margin;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return CustomPaint(
      painter: _FramePainter(
        gold: colors.gold,
        wash: colors.goldSoft,
        surface: colors.readingSurface,
        margin: margin,
      ),
      child: Padding(padding: EdgeInsets.all(margin), child: child),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.gold,
    required this.wash,
    required this.surface,
    required this.margin,
  });

  final Color gold;
  final Color wash;
  final Color surface;
  final double margin;

  @override
  void paint(Canvas canvas, Size size) {
    final m = margin;
    final heavy = Paint()
      ..style = PaintingStyle.stroke
      ..color = gold
      ..strokeWidth = m * 0.09;
    final fine = Paint()
      ..style = PaintingStyle.stroke
      ..color = gold
      ..strokeWidth = m * 0.04;
    final fill = Paint()..color = gold;

    final outer = (Offset.zero & size).deflate(m * 0.12);
    final inner = (Offset.zero & size).deflate(m * 0.62);
    // The band between the two rules.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(outer)
        ..addRect(inner),
      Paint()..color = wash.withValues(alpha: 0.4),
    );
    canvas.drawRect(outer, heavy);
    canvas.drawRect(outer.deflate(m * 0.12), fine);
    canvas.drawRect(inner, heavy);
    canvas.drawRect(inner.inflate(m * 0.1), fine);

    // A running chain of small diamonds along the middle of the band.
    final mid = (Offset.zero & size).deflate(m * 0.37);
    final d = m * 0.09;
    void chain(Offset from, Offset to) {
      final length = (to - from).distance;
      final dir = (to - from) / length;
      final normal = Offset(-dir.dy, dir.dx);
      for (var t = m * 0.9; t < length - m * 0.9; t += d * 3.2) {
        final c = from + dir * t;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + dir.dx * d, c.dy + dir.dy * d)
            ..lineTo(c.dx + normal.dx * d * 0.7, c.dy + normal.dy * d * 0.7)
            ..lineTo(c.dx - dir.dx * d, c.dy - dir.dy * d)
            ..lineTo(c.dx - normal.dx * d * 0.7, c.dy - normal.dy * d * 0.7)
            ..close(),
          fill,
        );
      }
    }

    chain(mid.topLeft, mid.topRight);
    chain(mid.bottomLeft, mid.bottomRight);
    chain(mid.topLeft, mid.bottomLeft);
    chain(mid.topRight, mid.bottomRight);

    // Corner pieces: a square over the band with a star inside.
    final s = m * 0.62;
    for (final corner in [
      mid.topLeft,
      mid.topRight,
      mid.bottomLeft,
      mid.bottomRight,
    ]) {
      final box = Rect.fromCenter(
        center: corner,
        width: s * 1.5,
        height: s * 1.5,
      );
      canvas.drawRect(box, Paint()..color = surface);
      canvas.drawRect(box, heavy);
      canvas.drawPath(eightPointStar(corner, s * 0.6), fill);
      canvas.drawCircle(corner, s * 0.15, Paint()..color = surface);
    }

    // A medallion at the middle of each side.
    for (final centre in [
      mid.centerLeft,
      mid.centerRight,
      mid.topCenter,
      mid.bottomCenter,
    ]) {
      canvas.drawCircle(centre, s * 0.62, Paint()..color = surface);
      canvas.drawCircle(centre, s * 0.62, fine);
      canvas.drawPath(eightPointStar(centre, s * 0.5), fill);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.gold != gold ||
      old.wash != wash ||
      old.surface != surface ||
      old.margin != margin;
}
