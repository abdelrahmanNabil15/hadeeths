import 'package:flutter/widgets.dart';
import 'package:mynewapp/features/quran/domain/mushaf_asset_manifest.dart';
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
    }
  }
}
