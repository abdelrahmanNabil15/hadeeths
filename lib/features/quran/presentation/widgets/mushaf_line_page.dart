import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/features/quran/domain/mushaf_lines.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/widgets/ayah_marker.dart';
import 'package:mynewapp/features/quran/presentation/widgets/marker_digits.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_surah_header.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The font the 15-line pages are set in: the King Fahd Complex's own Uthmani Hafs script, the one
/// the bundled lines file's text is written for.
const mushafFontFamily = 'KFGQPCHafs';

/// One page of the 15-line Madinah mushaf, line for line as printed: every line holds exactly the
/// words it holds in the printed copy and is justified edge to edge; a sura's name and its basmala
/// each take a line of their own. Pages 1 and 2 are set, as in the print, as a narrower block in
/// the middle of the page.
///
/// The page is always [width] wide and [height] tall (fifteen lines of [lineHeight]), so it can be
/// scaled whole to the screen like a sheet of paper. A line that would not fit at the page's size
/// (rare) is shrunk on its own rather than wrapped, so the page's lines never move.
class MushafLinePage extends StatelessWidget {
  const MushafLinePage({
    super.key,
    required this.lines,
    required this.page,
    required this.width,
    required this.bookmarks,
    required this.onVerseActions,
    this.markerStyle = AyahMarkerStyle.rosette,
  });

  final List<MushafLine> lines;
  final int page;
  final double width;
  final List<VerseRef> bookmarks;
  final AyahMarkerStyle markerStyle;
  final void Function(VerseRef verse) onVerseActions;

  /// The page's proportions: fifteen lines, each this fraction of the page's width.
  static const lineHeightFactor = 0.112;

  /// The script's size, as a fraction of a line's height.
  static const fontSizeFactor = 0.5;

  double get lineHeight => width * lineHeightFactor;
  double get height => lineHeight * 15;

  @override
  Widget build(BuildContext context) {
    final opening = page <= 2;
    final style = TextStyle(
      fontFamily: mushafFontFamily,
      fontSize: lineHeight * fontSizeFactor,
      height: 1,
      color: Theme.of(context).colorScheme.onSurface,
    );
    Widget lineAt(MushafLine line, double lineWidth) => SizedBox(
      width: lineWidth,
      height: lineHeight,
      child: switch (line) {
        SuraNameLine(:final sura) => MushafSuraHeader(
          sura: sura,
          height: lineHeight,
        ),
        BasmalaLine(:final text) => _CenteredWords(
          words: text.split(' '),
          style: style,
          width: lineWidth,
        ),
        VerseLine(:final pieces) => _VerseLineView(
          pieces: pieces,
          style: style,
          width: lineWidth,
          centered: opening,
          bookmarks: bookmarks,
          markerStyle: markerStyle,
          onVerseActions: onVerseActions,
        ),
      },
    );

    final Widget body;
    if (opening) {
      // The sura's name across the top; the rest a narrower block centred on the page.
      final blockWidth = width * 0.72;
      body = Column(
        children: [
          lineAt(lines.first, width),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final line in lines.skip(1)) lineAt(line, blockWidth),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      body = Column(children: [for (final line in lines) lineAt(line, width)]);
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(width: width, height: height, child: body),
    );
  }
}

/// A line of verse text, justified to [width]: its words spread so the first touches the right
/// edge and the last (or the last verse number) the left, as in the printed page.
class _VerseLineView extends StatelessWidget {
  const _VerseLineView({
    required this.pieces,
    required this.style,
    required this.width,
    required this.centered,
    required this.bookmarks,
    required this.markerStyle,
    required this.onVerseActions,
  });

  final List<VersePiece> pieces;
  final TextStyle style;
  final double width;
  final bool centered;
  final List<VerseRef> bookmarks;
  final AyahMarkerStyle markerStyle;
  final void Function(VerseRef verse) onVerseActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppColors.of(context);
    final fontSize = style.fontSize!;
    final markerSize = markerStyle == AyahMarkerStyle.mushafFont
        ? fontSize
        : fontSize * 1.35;
    final tokens = <Widget>[];
    var natural = 0.0;
    for (final piece in pieces) {
      final ref = piece.ref;
      final marked = bookmarks.contains(ref);
      for (final word in piece.words.expand((w) => w.split(' '))) {
        natural += _textWidth(word, style);
        tokens.add(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => onVerseActions(ref),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: marked ? colors.goldSoft.withValues(alpha: 0.5) : null,
              ),
              child: Text(
                word,
                style: style,
                maxLines: 1,
                softWrap: false,
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
        );
      }
      if (piece.endsHere) {
        // The verse's number, in the marker the reader chose (the font's own ornament is as wide
        // as its glyph; the others are square).
        natural += markerStyle == AyahMarkerStyle.mushafFont
            ? _textWidth(
                arabicIndicDigits(piece.verse),
                style.copyWith(fontSize: markerSize * 0.95),
              )
            : markerSize;
        tokens.add(
          Semantics(
            label: l10n.quranVerseLabel(context.digits.format(piece.verse)),
            onLongPressHint: marked
                ? l10n.quranBookmarkRemove
                : l10n.quranBookmarkAdd,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () => onVerseActions(ref),
              child: AyahMarker(
                style: markerStyle,
                number: piece.verse,
                bookmarked: marked,
                size: markerSize,
              ),
            ),
          ),
        );
      }
    }
    final minGap = fontSize * 0.28;
    final needed = natural + minGap * (tokens.length - 1);
    // A short line (the end of a sura, or the opening pages) is centred with even spaces rather
    // than pulled apart.
    final justify = !centered && needed <= width && needed > width * 0.6;
    if (justify) {
      return Row(
        mainAxisAlignment: tokens.length == 1
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: tokens,
      );
    }
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tokens.length; i++) ...[
              if (i > 0) SizedBox(width: minGap * 1.3),
              tokens[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Words set in the middle of a line (the basmala).
class _CenteredWords extends StatelessWidget {
  const _CenteredWords({
    required this.words,
    required this.style,
    required this.width,
  });

  final List<String> words;
  final TextStyle style;
  final double width;

  @override
  Widget build(BuildContext context) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        words.join(' '),
        style: style,
        maxLines: 1,
        softWrap: false,
        textScaler: TextScaler.noScaling,
      ),
    ),
  );
}

double _textWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.rtl,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
