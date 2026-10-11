import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_marker.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The opening line the source file puts at the start of verse 1 of most suras, taken from the
/// file's own first verse (al-Fatihah 1:1). Null when [sura] has none: al-Fatihah shows it as its
/// first verse, and at-Tawbah does not begin with it.
String? leadingBasmala(QuranText text, int sura) {
  if (sura == 1) return null;
  final first = text.sura(sura).first.text;
  final basmala = text.sura(1).first.text;
  return first.startsWith('$basmala ') ? basmala : null;
}

/// The verses of a sura as one continuous, justified paragraph, each verse ending with its number in
/// a rosette, as in a printed mushaf. Every verse's text is exactly as in the source; the numbers are
/// drawn after it, never in it. Long-press a verse (or its number) for its actions.
class VerseFlow extends StatefulWidget {
  const VerseFlow({
    super.key,
    required this.verses,
    required this.style,
    required this.bookmarks,
    required this.onVerseActions,
    this.skipFromFirst = '',
  });

  final List<Verse> verses;
  final TextStyle style;
  final List<VerseRef> bookmarks;

  final void Function(Verse verse) onVerseActions;

  /// A start of the first verse that is shown elsewhere (the opening line, set above the page).
  final String skipFromFirst;

  @override
  State<VerseFlow> createState() => _VerseFlowState();
}

class _VerseFlowState extends State<VerseFlow> {
  late final List<LongPressGestureRecognizer> _recognizers = [
    for (final _ in widget.verses) LongPressGestureRecognizer(),
  ];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppColors.of(context);
    final fontSize = widget.style.fontSize ?? 24;
    // Inline widgets do not follow the text scale by themselves.
    final markerSize = MediaQuery.textScalerOf(context).scale(fontSize) * 0.95;
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.verses.length; i++) {
      final verse = widget.verses[i];
      final place = VerseRef(verse.sura, verse.number);
      final marked = widget.bookmarks.contains(place);
      final text = i == 0 && widget.skipFromFirst.isNotEmpty
          ? verse.text.substring(widget.skipFromFirst.length).trimLeft()
          : verse.text;
      _recognizers[i].onLongPress = () => widget.onVerseActions(verse);
      spans
        ..add(
          TextSpan(
            text: text,
            recognizer: _recognizers[i],
            style: marked
                ? TextStyle(
                    backgroundColor: colors.goldSoft.withValues(alpha: 0.5),
                  )
                : null,
          ),
        )
        // A non-breaking space keeps the number on the line of the verse's last word.
        ..add(const TextSpan(text: ' '))
        ..add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Semantics(
              label: l10n.quranVerseLabel(context.digits.format(verse.number)),
              onLongPressHint: marked
                  ? l10n.quranBookmarkRemove
                  : l10n.quranBookmarkAdd,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => widget.onVerseActions(verse),
                child: VerseMarker(
                  number: verse.number,
                  bookmarked: marked,
                  size: markerSize,
                ),
              ),
            ),
          ),
        )
        ..add(const TextSpan(text: ' '));
    }
    return Text.rich(
      TextSpan(children: spans, style: widget.style),
      textAlign: TextAlign.justify,
    );
  }
}
