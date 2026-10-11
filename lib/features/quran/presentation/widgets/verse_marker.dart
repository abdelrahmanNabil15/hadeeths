import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';

/// The verse number beside a verse: the number inside a fine gold eight-pointed star, filled with
/// sage when the verse is bookmarked. The number is drawn beside the text, never added to it.
/// Decoration for screen readers: the verse's own label carries the number.
class VerseMarker extends StatelessWidget {
  const VerseMarker({super.key, required this.number, this.bookmarked = false});

  final int number;
  final bool bookmarked;

  static const size = 40.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _StarPainter(
            stroke: colors.gold,
            fill: bookmarked ? colors.sage : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  context.digits.format(number),
                  style: TextStyle(
                    fontSize: AppTextSize.meta - 1,
                    fontWeight: FontWeight.w600,
                    color: bookmarked ? colors.onSage : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.stroke, this.fill});

  final Color stroke;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final path = eightPointStar(
      size.center(Offset.zero),
      size.shortestSide / 2 - AppBorders.emphasis,
    );
    if (fill != null) canvas.drawPath(path, Paint()..color = fill!);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppBorders.emphasis,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.stroke != stroke || old.fill != fill;
}
