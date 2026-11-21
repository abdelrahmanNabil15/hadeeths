import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/features/quran/domain/mushaf_asset.dart';
import 'package:mynewapp/features/quran/presentation/widgets/marker_digits.dart';

/// The verse number drawn inside a traced Mushaf ayah-marker glyph (Quran.ws Quran Assets,
/// OFL-1.1, `confirmed` assets only — see `docs/QURAN_ASSETS_INTEGRATION_PLAN.md`). An alternative
/// to [VerseMarker]'s painted rosette, chosen by the reader's "Ayah marker" setting; this widget
/// never decides that choice itself.
///
/// With [tinted] (the default), the glyph is drawn from its single-colour silhouette
/// (`asset.monoAsset`, `fill: currentColor`) and tinted whole: gold normally, sage when bookmarked,
/// the same two colours [VerseMarker] uses for its ring and its fill. With [tinted] false, the
/// glyph is drawn from its own full-colour artwork (`asset.colorAsset`) exactly as published —
/// never recoloured, including on bookmark, because at that point it isn't one colour to tint.
class MushafGlyphMarker extends StatelessWidget {
  const MushafGlyphMarker({
    super.key,
    required this.asset,
    required this.number,
    this.bookmarked = false,
    this.tinted = true,
    this.size = defaultSize,
    this.semanticLabel,
  });

  final MushafAsset asset;
  final int number;
  final bool bookmarked;

  /// Whether the glyph is recoloured gold/sage. False shows the asset's own published palette,
  /// unchanged, regardless of [bookmarked].
  final bool tinted;

  final double size;
  final String? semanticLabel;

  static const defaultSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final glyphHeight = size / asset.aspect;
    // Full-contrast digits: the theme's text colour round a tinted glyph, and a fixed dark ink
    // inside a full-colour glyph, whose own light fill does not change with the theme.
    final digitColor = !tinted
        ? const Color(0xFF1F1A14)
        : bookmarked
        ? colors.onSage
        : scheme.onSurface;
    // The traced number slot is tight round the source font's own digits; the Naskh digits need
    // more room, so it is grown about its centre (staying inside the glyph).
    final slot = asset.numberSlot;
    final slotWidth = (slot.width * 1.45).clamp(0.0, 0.72);
    final slotHeight = (slot.height * 1.9).clamp(0.0, 0.5);
    final slotLeft = slot.x + slot.width / 2 - slotWidth / 2;
    final slotTop = slot.y + slot.height / 2 - slotHeight / 2;
    final glyph = SizedBox(
      width: size,
      height: glyphHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (tinted)
            SvgPicture.asset(
              asset.monoAsset,
              width: size,
              height: glyphHeight,
              colorFilter: ColorFilter.mode(
                bookmarked ? colors.sage : colors.gold,
                BlendMode.srcIn,
              ),
            )
          else
            SvgPicture.asset(
              asset.colorAsset,
              width: size,
              height: glyphHeight,
            ),
          Positioned(
            left: slotLeft * size,
            top: slotTop * glyphHeight,
            width: slotWidth * size,
            height: slotHeight * glyphHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                arabicIndicDigits(number),
                textScaler: TextScaler.noScaling,
                style: markerDigitStyle(
                  fontSize: size * 0.5,
                  color: digitColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: glyph)
        : Semantics(label: semanticLabel, excludeSemantics: true, child: glyph);
  }
}
