import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/features/quran/domain/mushaf_asset_manifest.dart';
import 'package:mynewapp/features/quran/presentation/widgets/marker_digits.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_glyph_marker.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_marker.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

/// The verse-number marker, drawn as [style] says: the app's own painted rosette, or a traced
/// Mushaf glyph from Quran.ws Quran Assets. The only place that reads [AyahMarkerStyle] — callers
/// just say where the marker goes.
class AyahMarker extends StatelessWidget {
  const AyahMarker({
    super.key,
    required this.style,
    required this.number,
    this.bookmarked = false,
    this.size = VerseMarker.defaultSize,
    this.semanticLabel,
  });

  final AyahMarkerStyle style;
  final int number;
  final bool bookmarked;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AyahMarkerStyle.rosette:
        return VerseMarker(
          number: number,
          bookmarked: bookmarked,
          size: size,
          semanticLabel: semanticLabel,
        );
      case AyahMarkerStyle.mushafGlyph:
        return MushafGlyphMarker(
          asset: defaultMushafGlyph,
          number: number,
          bookmarked: bookmarked,
          size: size,
          semanticLabel: semanticLabel,
        );
      case AyahMarkerStyle.scheherazadeColor:
        return MushafGlyphMarker(
          asset: scheherazadeColorGlyph,
          number: number,
          bookmarked: bookmarked,
          tinted: false,
          size: size,
          semanticLabel: semanticLabel,
        );
      case AyahMarkerStyle.mushafFont:
        // The font draws Arabic-Indic digits inside its end-of-verse ornament by itself.
        return Semantics(
          label: semanticLabel,
          excludeSemantics: true,
          child: Text(
            arabicIndicDigits(number),
            textDirection: TextDirection.rtl,
            maxLines: 1,
            softWrap: false,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: 'KFGQPCHafs',
              fontSize: size * 0.95,
              height: 1,
              color: bookmarked
                  ? AppColors.of(context).gold
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
    }
  }
}
