import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_marker.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/quran_fakes.dart';
import '../support/quran_reader.dart';
import '../support/test_app.dart';

Future<AppLocalizations> _open(
  WidgetTester tester, {
  String locale = 'en',
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    FakeBackend(),
    locale: locale,
    features: const FeatureFlags(quran: true),
    quran: FakeQuranSource(),
    quranUserData: InMemoryQuranUserData(),
  );
  final l10n = lookupAppLocalizations(Locale(locale));
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(l10n.navQuran),
    ),
  );
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  testWidgets(
    'the reader opens with the sura banner, its count and the verse numbers',
    (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await _open(tester);
      await tester.tap(find.text('1. ${SuraNames.latin(1)}'));
      await tester.pumpAndSettle();
      final title = l10n.quranSuraTitle(SuraNames.latin(1));
      expect(find.text(title), findsOneWidget);
      expect(
        tester.getSemantics(find.text(title)),
        isSemantics(label: title, isHeader: true),
      );
      expect(find.text('7 verses'), findsOneWidget);
      // Interface text keeps the app's direction inside the right-to-left reader.
      expect(
        tester
            .widget<Directionality>(
              find
                  .ancestor(
                    of: find.text('7 verses'),
                    matching: find.byType(Directionality),
                  )
                  .first,
            )
            .textDirection,
        TextDirection.ltr,
      );
      expect(find.byType(VerseMarker), findsNWidgets(7));
      handle.dispose();
    },
  );

  testWidgets(
    'verse markers are announced as the verse, and fill when bookmarked',
    (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await _open(tester);
      await tester.tap(find.text('1. ${SuraNames.latin(1)}'));
      await tester.pumpAndSettle();
      final first = find.byType(VerseMarker).first;
      // The number is drawn, not announced on its own: its label names the verse ("Verse 1").
      expect(find.bySemanticsLabel(RegExp(r'^1$')), findsNothing);
      expect(find.bySemanticsLabel(l10n.quranVerseLabel('1')), findsOneWidget);
      expect(tester.widget<VerseMarker>(first).bookmarked, isFalse);

      await longPressVerse(tester, placeholderVerse(1, 1));
      // The shared options sheet, titled with the verse it acts on.
      expect(find.textContaining(l10n.quranVerseLabel('1')), findsOneWidget);
      await tester.tap(find.text(l10n.quranBookmarkAdd));
      await tester.pumpAndSettle();
      expect(
        tester.widget<VerseMarker>(find.byType(VerseMarker).first).bookmarked,
        isTrue,
      );
      handle.dispose();
    },
  );

  testWidgets('search prompts before typing and shows results on cards', (
    tester,
  ) async {
    final l10n = await _open(tester);
    await tester.tap(find.text(l10n.quranSearchHint));
    await tester.pumpAndSettle();
    expect(find.text(l10n.quranSearchPrompt), findsOneWidget);
    expect(find.byType(StateMedallion), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'كلمة');
    await tester.pump();
    expect(find.text(l10n.quranSearchPrompt), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(AppCard),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('reader and search fit at 200% text', (tester) async {
    useSmallPhone(tester, textScale: 2);
    await pumpApp(
      tester,
      FakeBackend(),
      features: const FeatureFlags(quran: true),
      quran: FakeQuranSource(),
      quranUserData: InMemoryQuranUserData(),
    );
    await tester.tap(find.text('المصحف'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('البحث في القرآن'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('١. ${SuraNames.arabic(1)}'));
    expect(tester.takeException(), isNull);
  });
}
