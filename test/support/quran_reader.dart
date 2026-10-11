import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The reader sets the verses of each mushaf page of a sura as one paragraph. This is the text of each
/// verse in them, in order, taken from the spans that react to a long press (the numbers and spaces are not verses).
List<String> verseTexts(WidgetTester tester) {
  bool isPage(Widget w) =>
      w is Text &&
      w.textSpan is TextSpan &&
      ((w.textSpan! as TextSpan).children ?? const []).any(
        (s) => s is TextSpan && s.recognizer is LongPressGestureRecognizer,
      );
  return [
    for (final paragraph in tester.widgetList<Text>(
      find.byWidgetPredicate(isPage),
    ))
      for (final span in (paragraph.textSpan! as TextSpan).children!)
        if (span is TextSpan && span.recognizer is LongPressGestureRecognizer)
          span.text!,
  ];
}

/// Long-presses the verse whose text is [verse], on the words themselves.
Future<void> longPressVerse(WidgetTester tester, String verse) async {
  final render = tester.renderObject<RenderParagraph>(
    find
        .byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('$verse '),
        )
        .first,
  );
  final start = render.text.toPlainText().indexOf('$verse ');
  final boxes = render.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + verse.length),
  );
  await tester.longPressAt(render.localToGlobal(boxes.first.toRect().center));
  await tester.pumpAndSettle();
}

/// Turns to the next page of the mushaf: pages are right to left, so the next one is dragged in from
/// the left.
Future<void> turnPage(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(500, 0), 2000);
  await tester.pumpAndSettle();
}
