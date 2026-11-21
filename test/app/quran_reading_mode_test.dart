import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_marker.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/quran_fakes.dart';
import '../support/quran_reader.dart';
import '../support/test_app.dart';

Future<(AppLocalizations, InMemorySettingsRepository)> _openSura1(
  WidgetTester tester, {
  AppSettings settings = const AppSettings(),
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = InMemorySettingsRepository(settings);
  await pumpApp(
    tester,
    FakeBackend(),
    locale: 'en',
    settings: settings,
    repository: repository,
    features: const FeatureFlags(quran: true),
    quran: FakeQuranSource(),
    quranUserData: InMemoryQuranUserData(),
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
  return (l10n, repository);
}

void main() {
  testWidgets('mushaf is the default layout, with its toggle selected', (
    tester,
  ) async {
    final (l10n, _) = await _openSura1(tester);
    expect(find.byType(PageView), findsOneWidget);
    final toggle = tester.widget<SegmentedButton<QuranReadingMode>>(
      find.byType(SegmentedButton<QuranReadingMode>),
    );
    expect(toggle.selected, {QuranReadingMode.mushaf});
    expect(find.byTooltip(l10n.quranReadingModeVerseByVerse), findsOneWidget);
  });

  testWidgets(
    'switching to verse by verse shows every verse of the sura at once, unpaged',
    (tester) async {
      final (l10n, repository) = await _openSura1(tester);
      await tester.tap(find.byTooltip(l10n.quranReadingModeVerseByVerse));
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(VerseMarker), findsNWidgets(7));
      expect(verseTexts(tester), [
        for (var v = 1; v <= 7; v++) placeholderVerse(1, v),
      ]);
      // The choice is saved, so reopening the reader keeps it.
      expect(repository.stored.quranReadingMode, QuranReadingMode.verseByVerse);
      expect(repository.saves, greaterThan(0));
    },
  );

  testWidgets(
    'verse-by-verse text stays right to left in the English interface',
    (tester) async {
      final (l10n, _) = await _openSura1(tester);
      await tester.tap(find.byTooltip(l10n.quranReadingModeVerseByVerse));
      await tester.pumpAndSettle();
      final verseText = find
          .byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains(placeholderVerse(1, 1)),
          )
          .first;
      expect(
        tester
            .widget<Directionality>(
              find
                  .ancestor(
                    of: verseText,
                    matching: find.byType(Directionality),
                  )
                  .first,
            )
            .textDirection,
        TextDirection.rtl,
      );
    },
  );

  testWidgets('a long press still bookmarks a verse in verse-by-verse mode', (
    tester,
  ) async {
    final (l10n, _) = await _openSura1(tester);
    await tester.tap(find.byTooltip(l10n.quranReadingModeVerseByVerse));
    await tester.pumpAndSettle();

    expect(
      tester.widget<VerseMarker>(find.byType(VerseMarker).first).bookmarked,
      isFalse,
    );
    await longPressVerse(tester, placeholderVerse(1, 1));
    await tester.tap(find.text(l10n.quranBookmarkAdd));
    await tester.pumpAndSettle();
    expect(
      tester.widget<VerseMarker>(find.byType(VerseMarker).first).bookmarked,
      isTrue,
    );
  });

  testWidgets(
    'opening the reader with verse by verse already chosen skips the mushaf page view',
    (tester) async {
      final (_, _) = await _openSura1(
        tester,
        settings: const AppSettings(
          quranReadingMode: QuranReadingMode.verseByVerse,
        ),
      );
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(VerseMarker), findsNWidgets(7));
    },
  );

  testWidgets('switching back to mushaf returns the toggle to that selection', (
    tester,
  ) async {
    final (l10n, _) = await _openSura1(tester);
    await tester.tap(find.byTooltip(l10n.quranReadingModeVerseByVerse));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.quranReadingModeMushaf));
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    final toggle = tester.widget<SegmentedButton<QuranReadingMode>>(
      find.byType(SegmentedButton<QuranReadingMode>),
    );
    expect(toggle.selected, {QuranReadingMode.mushaf});
  });

  testWidgets('verse by verse fits at 200% text', (tester) async {
    useSmallPhone(tester, textScale: 2);
    final l10n = lookupAppLocalizations(const Locale('en'));
    await pumpApp(
      tester,
      FakeBackend(),
      locale: 'en',
      features: const FeatureFlags(quran: true),
      quran: FakeQuranSource(),
      quranUserData: InMemoryQuranUserData(),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navQuran),
      ),
    );
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('1. ${SuraNames.latin(1)}'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.quranReadingModeVerseByVerse));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
