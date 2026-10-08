import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// Text that follows the ambient text direction (right-to-left for Arabic, left-to-right for
/// English). [alignment] is directional: `start` is the right edge in Arabic and the left edge
/// in English.
class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    this.text = '',
    this.fontSize = AppTextSize.listTitle,
    this.color = AppColors.ink,
    this.alignment = AlignmentDirectional.topStart,
    required this.fontWeight,
    this.isHeader = false,
  });

  final String text;
  final double fontSize;
  final Color color;
  final AlignmentGeometry alignment;
  final FontWeight fontWeight;

  /// Marks the text as a heading for screen readers (they can jump between headings).
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final label = Container(
      alignment: alignment,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.family,
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
    return isHeader ? Semantics(header: true, child: label) : label;
  }
}
