import 'package:flutter/widgets.dart';

/// Splits [text] into pieces that each fit in [maxHeight] at [width] in [style], breaking only at
/// spaces. The pieces are pieces of the text itself: nothing is added, removed or reordered, only
/// the spaces where a piece ends are dropped. A single word longer than a page gets a page of its
/// own (it is never cut).
List<String> splitIntoPages(
  String text, {
  required TextStyle style,
  required double width,
  required double maxHeight,
  required TextDirection direction,
}) {
  final words = RegExp(r'\S+').allMatches(text).toList();
  if (words.isEmpty) return const [];
  bool fits(int from, int to) {
    final painter = TextPainter(
      text: TextSpan(
        text: text.substring(words[from].start, words[to].end),
        style: style,
      ),
      textDirection: direction,
    )..layout(maxWidth: width);
    final height = painter.height;
    painter.dispose();
    return height <= maxHeight;
  }

  final pages = <String>[];
  var start = 0;
  while (start < words.length) {
    // The longest run of words from [start] that fits, found by halving.
    var low = start;
    var high = words.length - 1;
    var best = start;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (fits(start, mid)) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    pages.add(text.substring(words[start].start, words[best].end));
    start = best + 1;
  }
  return pages;
}
