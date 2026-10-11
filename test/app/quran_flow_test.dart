import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

import '../support/fake_backend.dart';
import '../support/quran_fakes.dart';
import '../support/test_app.dart';

Future<InMemoryQuranUserData> _openQuran(
  WidgetTester tester, {
  String locale = 'ar',
  FakeQuranSource? source,
  InMemoryQuranUserData? data,
  bool tall = true,
}) async {
  if (tall) {
    tester.view.physicalSize = const Size(700, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  final userData = data ?? InMemoryQuranUserData();
  await pumpApp(
    tester,
    FakeBackend(),
    locale: locale,
    features: const FeatureFlags(quran: true),
    quran: source ?? FakeQuranSource(),
    quranUserData: userData,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(locale == 'ar' ? 'المصحف' : 'Quran'),
    ),
  );
  await tester.pumpAndSettle();
  return userData;
}

void main() {
  testWidgets(
    'without a verified text the section says so and shows nothing else',
    (tester) async {
      await _openQuran(tester, source: FakeQuranSource(fail: true));
      expect(find.textContaining('غير مضمَّن'), findsOneWidget);
      expect(find.text('السور'), findsNothing);
    },
  );

  testWidgets(
    'lists the suras by name with their verse counts, and credits the source',
    (tester) async {
      await _openQuran(tester);
      expect(find.text('١. الفاتحة'), findsOneWidget);
      expect(find.text('٢. البقرة'), findsOneWidget);
      expect(find.text('٣. آل عمران'), findsOneWidget);
      expect(find.text('٧ آيات'), findsOneWidget);
      expect(find.text('١٢ آية'), findsOneWidget);
      expect(find.textContaining('tanzil.net'), findsOneWidget);
    },
  );

  testWidgets(
    'a sura shows every verse exactly as in the file, and adds nothing above them',
    (tester) async {
      await _openQuran(tester);
      await tester.tap(find.text('٢. البقرة'));
      await tester.pumpAndSettle();
      // Nothing is added above the first verse: the file itself carries any opening line.
      expect(find.text(placeholderVerse(1, 1)), findsNothing);
      for (var v = 1; v <= 12; v++) {
        expect(
          find.text(placeholderVerse(2, v)),
          findsOneWidget,
          reason: '2:$v',
        );
      }
      expect(find.text('١٢'), findsOneWidget);
    },
  );

  testWidgets('al-Fatihah shows its first verse once', (tester) async {
    await _openQuran(tester);
    await tester.tap(find.text('١. الفاتحة'));
    await tester.pumpAndSettle();
    expect(find.text(placeholderVerse(1, 1)), findsOneWidget);
  });

  testWidgets('verse text is right to left even in the English interface', (
    tester,
  ) async {
    await _openQuran(tester, locale: 'en');
    await tester.tap(find.text('2. Al-Baqarah'));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.text(placeholderVerse(2, 1)))),
      TextDirection.rtl,
    );
  });

  testWidgets('opening a sura remembers it, and the list offers to continue', (
    tester,
  ) async {
    final data = await _openQuran(tester);
    await tester.tap(find.text('٣. آل عمران'));
    await tester.pumpAndSettle();
    expect(data.last, const VerseRef(3, 1));
    await goBack(tester);
    expect(find.text('متابعة القراءة'), findsOneWidget);
    expect(find.text('آل عمران، الآية ١'), findsOneWidget);
  });

  testWidgets('a long press bookmarks a verse, and Bookmarks lists it', (
    tester,
  ) async {
    final data = await _openQuran(tester);
    await tester.tap(find.text('٢. البقرة'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text(placeholderVerse(2, 3)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('وضع علامة على هذه الآية'));
    await tester.pumpAndSettle();
    expect(data.marks, {const VerseRef(2, 3)});
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    await goBack(tester);
    await tester.tap(find.text('العلامات'));
    await tester.pumpAndSettle();
    expect(find.text(placeholderVerse(2, 3)), findsOneWidget);
    expect(find.text('البقرة ٢:٣'), findsOneWidget);
  });

  testWidgets('search finds verses ignoring marks and opens them', (
    tester,
  ) async {
    await _openQuran(tester);
    await tester.tap(find.text('البحث في القرآن').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'كلمة مشكلة');
    await tester.pumpAndSettle();
    expect(find.text('وُجدت آيتان'), findsOneWidget);
    expect(find.text(placeholderVerse(2, 3)), findsOneWidget);
    await tester.tap(find.text(placeholderVerse(3, 2)));
    await tester.pumpAndSettle();
    expect(find.text('آل عمران'), findsWidgets);
  });

  testWidgets('go to a verse checks the numbers and opens the reader there', (
    tester,
  ) async {
    final data = await _openQuran(tester);
    await tester.tap(find.text('الانتقال إلى آية'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '2');
    await tester.pump();
    expect(find.text('البقرة'), findsOneWidget); // the sura's name as a hint
    await tester.enterText(fields.at(1), '13');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'انتقال'))
          .onPressed,
      isNull,
    );
    await tester.enterText(fields.at(1), '9');
    await tester.pump();
    await tester.tap(find.text('انتقال'));
    await tester.pumpAndSettle();
    expect(data.last, const VerseRef(2, 9));
    expect(find.text(placeholderVerse(2, 9)), findsOneWidget);
  });

  testWidgets('fits at 200% text on a small phone', (tester) async {
    useSmallPhone(tester, textScale: 2);
    await _openQuran(tester, tall: false);
    expect(tester.takeException(), isNull);
    // Below the sura filter at this size: scroll to it first.
    await scrollAndTap(tester, find.text('١. الفاتحة'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap targets, labels and contrast hold on the list', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useSmallPhone(tester);
    await _openQuran(tester, tall: false);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
