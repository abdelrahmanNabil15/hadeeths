import 'package:equatable/equatable.dart';

/// A run of text, flagged when the server marked it as matching the search phrase.
class TextSegment extends Equatable {
  const TextSegment(this.text, {this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  List<Object?> get props => [text, highlighted];
}

/// One hadith found by a search. [text] is the hadith exactly as received;
/// [highlightedText] is the same text with `<mark>` tags around the matches.
class HadithSearchResult extends Equatable {
  const HadithSearchResult({
    required this.id,
    required this.title,
    required this.text,
    required this.highlightedText,
  });

  final String id;
  final String title;
  final String text;
  final String highlightedText;

  /// [highlightedText] split into plain and highlighted runs. The characters of the runs,
  /// joined, equal the source text; only the tags are removed.
  List<TextSegment> get segments => parseHighlights(highlightedText);

  @override
  List<Object?> get props => [id, title, text, highlightedText];
}

/// Splits text containing `<mark>…</mark>` into runs. Tolerates a missing closing tag.
List<TextSegment> parseHighlights(String source) {
  if (source.isEmpty) return const [];
  final segments = <TextSegment>[];
  final pattern = RegExp(r'<mark>|</mark>');
  var highlighted = false;
  var cursor = 0;
  for (final match in pattern.allMatches(source)) {
    if (match.start > cursor) {
      segments.add(
        TextSegment(
          source.substring(cursor, match.start),
          highlighted: highlighted,
        ),
      );
    }
    highlighted = match.group(0) == '<mark>';
    cursor = match.end;
  }
  if (cursor < source.length) {
    segments.add(
      TextSegment(source.substring(cursor), highlighted: highlighted),
    );
  }
  return segments;
}

/// A short excerpt of [segments] around the first highlighted run, for a result row.
///
/// The excerpt is only a window onto the text (it never alters characters); ellipses are
/// added by the caller when [leading] or [trailing] is true.
({List<TextSegment> segments, bool leading, bool trailing}) excerptAround(
  List<TextSegment> segments, {
  int radius = 90,
}) {
  final total = segments.fold<int>(0, (sum, s) => sum + s.text.length);
  var firstMatchStart = -1;
  var offset = 0;
  for (final s in segments) {
    if (s.highlighted) {
      firstMatchStart = offset;
      break;
    }
    offset += s.text.length;
  }
  final from = firstMatchStart < 0
      ? 0
      : (firstMatchStart - radius).clamp(0, total);
  final to = (from + radius * 2).clamp(0, total);
  final result = <TextSegment>[];
  var position = 0;
  for (final s in segments) {
    final start = position;
    final end = position + s.text.length;
    position = end;
    if (end <= from || start >= to) continue;
    final cutStart = from > start ? from - start : 0;
    final cutEnd = to < end ? to - start : s.text.length;
    result.add(
      TextSegment(
        s.text.substring(cutStart, cutEnd),
        highlighted: s.highlighted,
      ),
    );
  }
  return (segments: result, leading: from > 0, trailing: to < total);
}
