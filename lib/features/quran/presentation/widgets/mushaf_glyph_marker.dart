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
/// The glyph is a single silhouette (`fill: currentColor`), so it is tinted whole rather than drawn
/// with a separate stroke and fill: gold normally, sage when bookmarked, the same two colours
/// [VerseMarker] uses for its ring and its fill.
class MushafGlyphMarker extends StatelessWidget {
  const MushafGlyphMarker({
    super.key,
    required this.asset,
    required this.number,
    this.bookmarked = false,
    this.size = defaultSize,
    this.semanticLabel,
  });

  final MushafAsset asset;
  final int number;
  final bool bookmarked;
  final double size;
  final String? semanticLabel;

  static const defaultSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tint = bookmarked ? colors.sage : colors.gold;
    final glyph = SizedBox(
      width: size,
      height: size / asset.aspect,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            asset.monoAsset,
            width: size,
            height: size / asset.aspect,
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
          ),
          Positioned(
            left: asset.numberSlot.x * size,
            top: asset.numberSlot.y * (size / asset.aspect),
            width: asset.numberSlot.width * size,
            height: asset.numberSlot.height * (size / asset.aspect),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.digits.format(number),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: bookmarked ? colors.onSage : scheme.onSurfaceVariant,
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
