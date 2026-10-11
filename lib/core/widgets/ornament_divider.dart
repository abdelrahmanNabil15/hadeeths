import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';

/// A fine rule with a small gold eight-pointed star in the middle. Separates a title from the text
/// it introduces. Decoration only, hidden from screen readers.
///
/// [width] limits it to a short centred ornament (for example under a header); null spans the
/// available width.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.width, this.color, this.lineColor});

  final double? width;

  /// The star; defaults to the theme's gold.
  final Color? color;

  /// The rules; defaults to a pale gold.
  final Color? lineColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final line = lineColor ?? colors.goldSoft;
    Widget rule() => Expanded(
      child: Container(height: AppBorders.hairline, color: line),
    );
    final ornament = ExcludeSemantics(
      child: SizedBox(
        height: AppSpacing.lg,
        child: Row(
          children: [
            rule(),
            const SizedBox(width: AppSpacing.sm),
            CustomPaint(
              size: const Size.square(AppSpacing.md),
              painter: _StarPainter(color ?? colors.gold),
            ),
            const SizedBox(width: AppSpacing.sm),
            rule(),
          ],
        ),
      ),
    );
    return width == null
        ? ornament
        : Center(
            child: SizedBox(width: width, child: ornament),
          );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      eightPointStar(size.center(Offset.zero), size.shortestSide / 2),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
