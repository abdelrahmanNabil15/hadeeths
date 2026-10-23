import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/quran_fakes.dart';
import '../support/test_app.dart';

Future<AppLocalizations> _openSura1VerseByVerse(
  WidgetTester tester, {
  required bool quranTranslations,
  FakeQuranContentRepository? quranContent,
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    FakeBackend(),
    locale: 'en',
    features: FeatureFlags(quran: true, quranTranslations: quranTranslations),
    quran: FakeQuranSource(),
    quranUserData: InMemoryQuranUserData(),
    quranContent: quranContent,
  );
  final l10n = lookupAppLocalizations(const Locale('en'));
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(l10n.navQuran),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('1. ${SuraNames.latin(1)}'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(l10n.quranReadingModeVerseByVerse));
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  testWidgets(
    'the flag off: no translation button, even with content available',
    (tester) async {
      final l10n = await _openSura1VerseByVerse(
        tester,
        quranTranslations: false,
        quranContent: FakeQuranContentRepository(),
      );
      expect(find.byTooltip(l10n.quranTranslation), findsNothing);
    },
  );

  testWidgets('the flag on but no repository: still no button', (tester) async {
    final l10n = await _openSura1VerseByVerse(tester, quranTranslations: true);
    expect(find.byTooltip(l10n.quranTranslation), findsNothing);
  });

  testWidgets(
    'choosing an edition shows its translation and credit under each verse',
    (tester) async {
      final l10n = await _openSura1VerseByVerse(
        tester,
        quranTranslations: true,
        quranContent: FakeQuranContentRepository(),
      );
      expect(find.byTooltip(l10n.quranTranslation), findsOneWidget);
      expect(
        find.text(placeholderTranslation(1, const VerseRef(1, 1))),
        findsNothing,
      );

      await tester.tap(find.byTooltip(l10n.quranTranslation));
      await tester.pumpAndSettle();
      expect(find.text(l10n.quranChooseTranslation), findsOneWidget);
      expect(find.text(l10n.quranTranslationNone), findsOneWidget);
      expect(find.text('Placeholder Edition One'), findsOneWidget);

      await tester.tap(find.text('Placeholder Edition One'));
      await tester.pumpAndSettle();

      // Back in the reader: every verse shows its translation and the credit line.
      for (var v = 1; v <= 7; v++) {
        expect(
          find.text(placeholderTranslation(1, VerseRef(1, v))),
          findsOneWidget,
        );
      }
      expect(
        find.text(l10n.quranTranslationCredit('Placeholder Edition One')),
        findsNWidgets(7),
      );
    },
  );

  testWidgets('choosing "No translation" clears a previous choice', (
    tester,
  ) async {
    final l10n = await _openSura1VerseByVerse(
      tester,
      quranTranslations: true,
      quranContent: FakeQuranContentRepository(),
    );
    await tester.tap(find.byTooltip(l10n.quranTranslation));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Placeholder Edition One'));
    await tester.pumpAndSettle();
    expect(
      find.text(placeholderTranslation(1, const VerseRef(1, 1))),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(l10n.quranTranslation));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.quranTranslationNone));
    await tester.pumpAndSettle();
    expect(
      find.text(placeholderTranslation(1, const VerseRef(1, 1))),
      findsNothing,
    );
  });

  testWidgets('searching the picker filters by name', (tester) async {
    final l10n = await _openSura1VerseByVerse(
      tester,
      quranTranslations: true,
      quranContent: FakeQuranContentRepository(),
    );
    await tester.tap(find.byTooltip(l10n.quranTranslation));
    await tester.pumpAndSettle();
    expect(find.text('Placeholder Edition One'), findsOneWidget);
    expect(find.text('Placeholder Edition Two'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'One');
    await tester.pump();
    expect(find.text('Placeholder Edition One'), findsOneWidget);
    expect(find.text('Placeholder Edition Two'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing matches this');
    await tester.pump();
    expect(find.text(l10n.quranTranslationNoMatch), findsOneWidget);
  });

  testWidgets('a failed edition list shows an error with retry', (
    tester,
  ) async {
    final repo = FakeQuranContentRepository(failEditions: true);
    final l10n = await _openSura1VerseByVerse(
      tester,
      quranTranslations: true,
      quranContent: repo,
    );
    await tester.tap(find.byTooltip(l10n.quranTranslation));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorServer), findsOneWidget);

    repo.failEditions = false;
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.text('Placeholder Edition One'), findsOneWidget);
  });
}
