import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';

/// The verse number at the end of a verse, like the rosette in a printed mushaf: the number inside a
/// small ring, set in a fine gold eight-pointed star, filled with sage when the verse is bookmarked.
/// The number is drawn beside the text, never added to it.
///
/// Without a [semanticLabel] it is decoration for screen readers; the reader gives it the verse's
/// label so the number is announced after the verse, as it is read in the mushaf.
class VerseMarker extends StatelessWidget {
  const VerseMarker({
    super.key,
    required this.number,
    this.bookmarked = false,
    this.size = defaultSize,
    this.semanticLabel,
  });

  final int number;
  final bool bookmarked;
  final double size;
  final String? semanticLabel;

  static const defaultSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rosette = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RosettePainter(
          stroke: colors.gold,
          fill: bookmarked ? colors.sage : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(size * 0.18),
              child: Text(
                context.digits.format(number),
                style: TextStyle(
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w600,
                  color: bookmarked ? colors.onSage : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: rosette)
        : Semantics(
            label: semanticLabel,
            excludeSemantics: true,
            child: rosette,
          );
  }
}

class _RosettePainter extends CustomPainter {
  const _RosettePainter({required this.stroke, this.fill});

  final Color stroke;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - AppBorders.emphasis;
    final star = eightPointStar(center, radius);
    if (fill != null) canvas.drawPath(star, Paint()..color = fill!);
    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppBorders.emphasis;
    canvas.drawPath(star, line);
    // The inner ring the number sits in.
    canvas.drawCircle(
      center,
      radius * 0.62,
      line..strokeWidth = AppBorders.hairline,
    );
  }

  @override
  bool shouldRepaint(_RosettePainter old) =>
      old.stroke != stroke || old.fill != fill;
}
