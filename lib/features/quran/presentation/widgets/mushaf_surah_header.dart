import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/features/quran/presentation/quran_labels.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The band at the head of a sura, in the manner of the Madinah mushaf: a framed gold band the
/// full width of the text, with the sura's name in a cartouche at its centre and a rosette on
/// either side. Drawn by the app (no artwork files), so it is sharp at any size and follows the
/// theme. The name is set in the King Fahd Complex's script, always in Arabic as in the print, and
/// read out in the interface language; nothing here is Quran text.
///
/// It is as wide as it is given; [height] defaults to a ninth of that, and in the 15-line layout
/// is exactly one line.
class MushafSuraHeader extends StatelessWidget {
  const MushafSuraHeader({super.key, required this.sura, this.height});

  final int sura;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ink = Theme.of(context).colorScheme.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final h = height ?? width / 9;
        return Semantics(
          container: true,
          header: true,
          label: context.l10n.quranSuraTitle(suraName(context, sura)),
          excludeSemantics: true,
          child: CustomPaint(
            size: Size(width, h),
            painter: _HeaderPainter(
              gold: colors.gold,
              wash: colors.goldSoft,
              surface: colors.readingSurface,
            ),
            child: SizedBox(
              width: width,
              height: h,
              child: Center(
                child: SizedBox(
                  width: width * _cartoucheWidth * 0.82,
                  height: h * 0.78,
                  child: FittedBox(
                    child: Text(
                      'سورة ${SuraNames.arabic(sura)}',
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: 'KFGQPCHafs',
                        fontSize: h * 0.5,
                        height: 1.1,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The cartouche's share of the band's width.
const _cartoucheWidth = 0.46;

class _HeaderPainter extends CustomPainter {
  const _HeaderPainter({
    required this.gold,
    required this.wash,
    required this.surface,
  });

  final Color gold;
  final Color wash;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rule = (h * 0.035).clamp(0.6, 2.0);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = gold
      ..strokeWidth = rule;
    final fine = Paint()
      ..style = PaintingStyle.stroke
      ..color = gold
      ..strokeWidth = rule * 0.55;
    final fill = Paint()..color = gold;

    // The band: a washed panel between a heavy outer rule and a fine inner one.
    final outer = Rect.fromLTWH(rule / 2, h * 0.08, w - rule, h * 0.84);
    canvas.drawRect(outer, Paint()..color = wash.withValues(alpha: 0.45));
    canvas.drawRect(outer, line);
    canvas.drawRect(outer.deflate(h * 0.09), fine);

    // A chain of small diamonds along each side panel.
    final cartoucheHalf = w * _cartoucheWidth / 2;
    final cy = h / 2;
    final d = h * 0.11;
    final rosetteR = h * 0.26;
    for (final side in [-1.0, 1.0]) {
      final rosetteX =
          w / 2 + side * (cartoucheHalf + (w / 2 - cartoucheHalf) / 2);
      final from = w / 2 + side * (cartoucheHalf + d * 2);
      final to = side < 0 ? outer.left + h * 0.25 : outer.right - h * 0.25;
      for (var x = from; side < 0 ? x > to : x < to; x += side * d * 2.6) {
        if ((x - rosetteX).abs() < rosetteR * 1.4) continue;
        canvas.drawPath(
          Path()
            ..moveTo(x, cy - d)
            ..lineTo(x + d * 0.7, cy)
            ..lineTo(x, cy + d)
            ..lineTo(x - d * 0.7, cy)
            ..close(),
          fill,
        );
      }
      // The rosette: an eight-pointed star in a ring.
      final centre = Offset(rosetteX, cy);
      canvas.drawCircle(centre, rosetteR, Paint()..color = surface);
      canvas.drawCircle(centre, rosetteR, fine);
      canvas.drawPath(eightPointStar(centre, rosetteR * 0.78), fill);
      canvas.drawCircle(centre, rosetteR * 0.22, Paint()..color = surface);
    }

    // The cartouche: a long medallion with pointed, scalloped ends.
    final left = w / 2 - cartoucheHalf;
    final right = w / 2 + cartoucheHalf;
    final top = h * 0.14;
    final bottom = h * 0.86;
    final tip = h * 0.42;
    final cartouche = Path()
      ..moveTo(left, cy)
      ..cubicTo(left + tip * 0.4, top, left + tip, top, left + tip * 1.25, top)
      ..lineTo(right - tip * 1.25, top)
      ..cubicTo(right - tip, top, right - tip * 0.4, top, right, cy)
      ..cubicTo(
        right - tip * 0.4,
        bottom,
        right - tip,
        bottom,
        right - tip * 1.25,
        bottom,
      )
      ..lineTo(left + tip * 1.25, bottom)
      ..cubicTo(left + tip, bottom, left + tip * 0.4, bottom, left, cy)
      ..close();
    canvas.drawPath(cartouche, Paint()..color = surface);
    canvas.drawPath(cartouche, line);
    // A fine inner outline, and a small bead at each point.
    canvas.save();
    canvas.translate(w / 2, cy);
    canvas.scale(0.94, 0.8);
    canvas.translate(-w / 2, -cy);
    canvas.drawPath(cartouche, fine);
    canvas.restore();
    for (final x in [left, right]) {
      canvas.drawCircle(Offset(x, cy), h * 0.06, fill);
    }
  }

  @override
  bool shouldRepaint(_HeaderPainter old) =>
      old.gold != gold || old.wash != wash || old.surface != surface;
}
