import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/features/quran/domain/mushaf_asset.dart';

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
    final digitColor = tinted && bookmarked
        ? colors.onSage
        : scheme.onSurfaceVariant;
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
            left: asset.numberSlot.x * size,
            top: asset.numberSlot.y * glyphHeight,
            width: asset.numberSlot.width * size,
            height: asset.numberSlot.height * glyphHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.digits.format(number),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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
