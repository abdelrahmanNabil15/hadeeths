import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
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
  testWidgets('the flag off: no qiraat action, even with content available', (
    tester,
  ) async {
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true),
      quranContent: FakeQuranContentRepository(),
    );
    await longPressVerse(tester, placeholderVerse(1, 1));
    expect(find.text(l10n.quranQiraat), findsNothing);
  });

  testWidgets('the flag on but no repository: still no qiraat action', (
    tester,
  ) async {
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranQiraat: true),
    );
    await longPressVerse(tester, placeholderVerse(1, 1));
    expect(find.text(l10n.quranQiraat), findsNothing);
  });

  testWidgets('qiraat is gated independently of tafsir', (tester) async {
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranQiraat: true),
      quranContent: FakeQuranContentRepository(),
    );
    await longPressVerse(tester, placeholderVerse(1, 1));
    expect(find.text(l10n.quranQiraat), findsOneWidget);
    expect(find.text(l10n.quranTafsirRead), findsNothing);
  });

  testWidgets(
    'a verse with approved variations shows the comparison, its readings and a credit',
    (tester) async {
      final l10n = await _openSura1(
        tester,
        features: const FeatureFlags(quran: true, quranQiraat: true),
        quranContent: FakeQuranContentRepository(),
      );
      await longPressVerse(tester, placeholderVerse(1, 1));
      await tester.tap(find.text(l10n.quranQiraat));
      await tester.pumpAndSettle();

      final juncture = placeholderQiraatMatrix.junctures.single;
      expect(find.text(juncture.text), findsOneWidget);
      expect(find.text(juncture.readings.first.text), findsOneWidget);
      expect(
        find.text(juncture.readings.first.attributions.join(', ')),
        findsOneWidget,
      );
      expect(find.text(l10n.quranQiraatDisclaimer), findsOneWidget);
      expect(find.text(l10n.quranQiraatCredit), findsOneWidget);
    },
  );

  testWidgets('a verse with no approved variations says so, not an error', (
    tester,
  ) async {
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranQiraat: true),
      quranContent: FakeQuranContentRepository(),
    );
    // Sura 1, verse 2: not the one placeholder verse the fake repository treats as having
    // variations.
    await longPressVerse(tester, placeholderVerse(1, 2));
    await tester.tap(find.text(l10n.quranQiraat));
    await tester.pumpAndSettle();
    expect(find.text(l10n.quranQiraatNone), findsOneWidget);
  });

  testWidgets('a failed fetch shows an error with retry in the sheet', (
    tester,
  ) async {
    final repo = FakeQuranContentRepository(failQiraat: true);
    final l10n = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranQiraat: true),
      quranContent: repo,
    );
    await longPressVerse(tester, placeholderVerse(1, 1));
    await tester.tap(find.text(l10n.quranQiraat));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorServer), findsOneWidget);

    repo.failQiraat = false;
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    final juncture = placeholderQiraatMatrix.junctures.single;
    expect(find.text(juncture.text), findsOneWidget);
  });
}
