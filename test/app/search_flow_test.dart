import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/search/domain/search_repository.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

FakeBackend _backend() => FakeBackend(
  pages: {
    '2:1': samplePage(ids: ['101']),
  },
);

Future<void> _openSearch(WidgetTester tester) =>
    tapVisible(tester, find.byIcon(Icons.search));

/// Types [text] and waits past the typing pause.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the home search field opens the search screen with the keyboard ready',
    (tester) async {
      await pumpApp(tester, _backend(), locale: 'en');
      await _openSearch(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).autofocus,
        isTrue,
      );
      expect(
        find.text('Type a word or phrase to search the text of the hadiths.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a short phrase gets guidance and no request', (tester) async {
    final api = _backend();
    await pumpApp(tester, api, locale: 'en');
    await _openSearch(tester);
    await _type(tester, 'ab');
    expect(find.text('Type at least 3 characters.'), findsOneWidget);
    expect(api.searchPhrases, isEmpty);
  });

  testWidgets(
    'results show the title, the count and the matched words highlighted',
    (tester) async {
      final api = _backend();
      await pumpApp(tester, api, locale: 'en');
      await _openSearch(tester);
      await _type(tester, 'النية');
      expect(api.searchPhrases, ['النية']);
      expect(find.text('2 results'), findsOneWidget);
      expect(find.text('نتيجة 700'), findsOneWidget);

      // The excerpt is one rich text whose matched run is emphasised, with the text unchanged.
      final rich = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((r) => r.text)
          .firstWhere((s) => s.toPlainText().contains('إنما الأعمال بالنية'));
      final leaves = <TextSpan>[];
      rich.visitChildren((span) {
        if (span is TextSpan && span.text != null) leaves.add(span);
        return true;
      });
      final highlighted = leaves.where((s) => s.style?.backgroundColor != null);
      expect(highlighted.map((s) => s.text), ['بالنية']);
      expect(
        rich.toPlainText(),
        contains('إنما الأعمال بالنية وإنما لكل امرئ ما نوى'),
      );
    },
  );

  testWidgets('a result opens that hadith', (tester) async {
    final api = _backend();
    await pumpApp(tester, api, locale: 'en');
    await _openSearch(tester);
    await _type(tester, 'النية');
    await tapText(tester, 'نتيجة 701');
    expect(api.detailsRequests, ['701']);
    expect(find.text('عنوان الحديث'), findsOneWidget);
  });

  testWidgets('no matches says so, quoting the phrase', (tester) async {
    final api = FakeBackend(searchResults: const []);
    await pumpApp(tester, api, locale: 'en');
    await _openSearch(tester);
    await _type(tester, 'zzzz');
    expect(find.text('No results for "zzzz"'), findsOneWidget);
  });

  testWidgets('a failure offers retry', (tester) async {
    final api = _backend()..searchFailure = noConnection;
    await pumpApp(tester, api, locale: 'en');
    await _openSearch(tester);
    await _type(tester, 'النية');
    expect(find.text('No internet connection'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);
  });

  testWidgets('the clear button empties the field and returns to the prompt', (
    tester,
  ) async {
    await pumpApp(tester, _backend(), locale: 'en');
    await _openSearch(tester);
    await _type(tester, 'النية');
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      find.text('Type a word or phrase to search the text of the hadiths.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Clear'), findsNothing);
  });

  testWidgets('a full page of results warns that more may exist', (
    tester,
  ) async {
    final api = FakeBackend(
      searchResults: sampleSearchResults(count: SearchRepository.maxResults),
    );
    await pumpApp(tester, api, locale: 'en');
    await _openSearch(tester);
    await _type(tester, 'النية');
    expect(
      find.textContaining('Showing the first 100 results only'),
      findsOneWidget,
    );
  });

  testWidgets('while searching, placeholders are shown', (tester) async {
    final api = _backend()..gate = Completer<void>();
    await pumpApp(tester, api, locale: 'en', settle: false);
    api.gate!.complete();
    await tester.pumpAndSettle();
    api.gate = Completer<void>();
    await _openSearch(tester);
    await tester.enterText(find.byType(TextField), 'النية');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SkeletonList), findsOneWidget);
    api.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonList), findsNothing);
  });
}
