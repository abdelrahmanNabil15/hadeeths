import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/quran_fakes.dart';
import '../support/quran_reader.dart';
import '../support/test_app.dart';

Future<AppLocalizations> _openSura1(
  WidgetTester tester, {
  required FeatureFlags features,
  FakeQuranContentRepository? quranContent,
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    FakeBackend(),
    locale: 'en',
    features: features,
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
  return l10n;
}

void main() {
  testWidgets('the flag off: no tafsir button, even with content available', (
    tester,
  ) async {
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true),
      quranContent: FakeQuranContentRepository(),
    );
    expect(find.byTooltip(l10n.quranTafsir), findsNothing);
  });

  testWidgets('the flag on but no repository: still no button', (tester) async {
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranTafsir: true),
    );
    expect(find.byTooltip(l10n.quranTafsir), findsNothing);
  });

  testWidgets('tafsir and translations are gated independently', (
    tester,
  ) async {
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranTafsir: true),
      quranContent: FakeQuranContentRepository(),
    );
    expect(find.byTooltip(l10n.quranTafsir), findsOneWidget);
    expect(find.byTooltip(l10n.quranTranslation), findsNothing);
  });

  testWidgets(
    'the tafsir button works in mushaf mode too, unlike the translation one',
    (tester) async {
      final l10n = await _openSura1(
        tester,
        features: const FeatureFlags(quran: true, quranTafsir: true),
        quranContent: FakeQuranContentRepository(),
      );
      // Still on the default (mushaf) layout.
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byTooltip(l10n.quranTafsir), findsOneWidget);
    },
  );

  testWidgets(
    'without a chosen edition, long-pressing a verse offers no tafsir action',
    (tester) async {
      await _openSura1(
        tester,
        features: const FeatureFlags(quran: true, quranTafsir: true),
        quranContent: FakeQuranContentRepository(),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      await longPressVerse(tester, placeholderVerse(1, 1));
      expect(find.text(l10n.quranBookmarkAdd), findsOneWidget);
      expect(find.text(l10n.quranTafsirRead), findsNothing);
    },
  );

  testWidgets(
    'choosing an edition, then reading a verse shows its tafsir, credit and disclaimer',
    (tester) async {
      final l10n = await _openSura1(
        tester,
        features: const FeatureFlags(quran: true, quranTafsir: true),
        quranContent: FakeQuranContentRepository(),
      );
      await tester.tap(find.byTooltip(l10n.quranTafsir));
      await tester.pumpAndSettle();
      expect(find.text(l10n.quranChooseTafsir), findsOneWidget);
      await tester.tap(find.text('Placeholder Tafsir One'));
      await tester.pumpAndSettle();

      await longPressVerse(tester, placeholderVerse(1, 1));
      expect(find.text(l10n.quranTafsirRead), findsOneWidget);
      await tester.tap(find.text(l10n.quranTafsirRead));
      await tester.pumpAndSettle();

      expect(
        find.text(placeholderTafsir(10, const VerseRef(1, 1))),
        findsOneWidget,
      );
      expect(find.text(l10n.quranTafsirDisclaimer), findsOneWidget);
      expect(
        find.text(l10n.quranTafsirCredit('Placeholder Tafsir One')),
        findsOneWidget,
      );
    },
  );

  testWidgets('a failed tafsir fetch shows an error with retry in the sheet', (
    tester,
  ) async {
    final repo = FakeQuranContentRepository(failTafsir: true);
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranTafsir: true),
      quranContent: repo,
    );
    await tester.tap(find.byTooltip(l10n.quranTafsir));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Placeholder Tafsir One'));
    await tester.pumpAndSettle();
    await longPressVerse(tester, placeholderVerse(1, 1));
    await tester.tap(find.text(l10n.quranTafsirRead));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorServer), findsOneWidget);

    repo.failTafsir = false;
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(
      find.text(placeholderTafsir(10, const VerseRef(1, 1))),
      findsOneWidget,
    );
  });

  testWidgets('a failed edition list shows an error with retry', (
    tester,
  ) async {
    final repo = FakeQuranContentRepository(failTafsirEditions: true);
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranTafsir: true),
      quranContent: repo,
    );
    await tester.tap(find.byTooltip(l10n.quranTafsir));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorServer), findsOneWidget);

    repo.failTafsirEditions = false;
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.text('Placeholder Tafsir One'), findsOneWidget);
  });
}
