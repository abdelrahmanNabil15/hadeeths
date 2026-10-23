import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/quran_fakes.dart';
import '../support/quran_reader.dart';
import '../support/test_app.dart';

Future<(AppLocalizations, FakeQuranAudioPlayer)> _openSura1(
  WidgetTester tester, {
  required FeatureFlags features,
  FakeQuranContentRepository? quranContent,
  AppSettings settings = const AppSettings(),
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Created eagerly (not inside the factory closure) so it is always available to assert
  // against, even in tests where the flag being off means the factory is never actually called.
  final player = FakeQuranAudioPlayer();
  await pumpApp(
    tester,
    FakeBackend(),
    locale: 'en',
    settings: settings,
    features: features,
    quran: FakeQuranSource(),
    quranUserData: InMemoryQuranUserData(),
    quranContent: quranContent,
    quranAudioPlayerFactory: () => player,
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
  return (l10n, player);
}

const _chosenReciter = AppSettings(
  quranReciterId: 1,
  quranReciterName: 'Placeholder Reciter One',
);

void main() {
  testWidgets(
    'the flag off: no recitation button, even with content available',
    (tester) async {
      final (l10n, _) = await _openSura1(
        tester,
        features: const FeatureFlags(quran: true),
        quranContent: FakeQuranContentRepository(),
      );
      expect(find.byTooltip(l10n.quranRecitation), findsNothing);
    },
  );

  testWidgets('the flag on but no repository: still no button', (tester) async {
    final (l10n, _) = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranAudio: true),
    );
    expect(find.byTooltip(l10n.quranRecitation), findsNothing);
  });

  testWidgets('audio and tafsir are gated independently', (tester) async {
    final (l10n, _) = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranAudio: true),
      quranContent: FakeQuranContentRepository(),
    );
    expect(find.byTooltip(l10n.quranRecitation), findsOneWidget);
    expect(find.byTooltip(l10n.quranTafsir), findsNothing);
  });

  testWidgets('the recitation button works in mushaf mode too', (tester) async {
    final (l10n, _) = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranAudio: true),
      quranContent: FakeQuranContentRepository(),
    );
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byTooltip(l10n.quranRecitation), findsOneWidget);
  });

  testWidgets(
    'without a chosen reciter, long-pressing a verse offers no listen action',
    (tester) async {
      await _openSura1(
        tester,
        features: const FeatureFlags(quran: true, quranAudio: true),
        quranContent: FakeQuranContentRepository(),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      await longPressVerse(tester, placeholderVerse(1, 1));
      expect(find.text(l10n.quranBookmarkAdd), findsOneWidget);
      expect(find.text(l10n.quranListen), findsNothing);
    },
  );

  testWidgets('choosing a reciter, then listening plays the verse', (
    tester,
  ) async {
    final (l10n, player) = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranAudio: true),
      quranContent: FakeQuranContentRepository(),
    );
    await tester.tap(find.byTooltip(l10n.quranRecitation));
    await tester.pumpAndSettle();
    expect(find.text(l10n.quranChooseReciter), findsOneWidget);
    await tester.tap(find.text('Placeholder Reciter One'));
    await tester.pumpAndSettle();

    await longPressVerse(tester, placeholderVerse(1, 1));
    expect(find.text(l10n.quranListen), findsOneWidget);
    await tester.tap(find.text(l10n.quranListen));
    await tester.pumpAndSettle();

    expect(
      player.playedUrls.single,
      placeholderRecitationUrl(1, const VerseRef(1, 1)),
    );
    // The mini player appears once something has played.
    expect(find.byTooltip(l10n.quranAudioStop), findsOneWidget);
  });

  testWidgets('the mini player: pause, resume, next, previous, stop', (
    tester,
  ) async {
    final (l10n, player) = await _openSura1(
      tester,
      features: const FeatureFlags(quran: true, quranAudio: true),
      quranContent: FakeQuranContentRepository(),
      settings: _chosenReciter,
    );
    await longPressVerse(tester, placeholderVerse(1, 1));
    await tester.tap(find.text(l10n.quranListen));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.quranAudioPause));
    await tester.pumpAndSettle();
    expect(player.pauseCalls, 1);
    expect(find.byTooltip(l10n.quranAudioPlay), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.quranAudioPlay));
    await tester.pumpAndSettle();
    expect(player.resumeCalls, 1);

    await tester.tap(find.byTooltip(l10n.quranAudioNext));
    await tester.pumpAndSettle();
    expect(
      player.playedUrls.last,
      placeholderRecitationUrl(1, const VerseRef(1, 2)),
    );

    await tester.tap(find.byTooltip(l10n.quranAudioPrevious));
    await tester.pumpAndSettle();
    expect(
      player.playedUrls.last,
      placeholderRecitationUrl(1, const VerseRef(1, 1)),
    );

    await tester.tap(find.byTooltip(l10n.quranAudioStop));
    await tester.pumpAndSettle();
    expect(player.stopCalls, 1);
    expect(find.byTooltip(l10n.quranAudioStop), findsNothing);
  });

  testWidgets(
    'finishing a verse on its own advances to the next, and stops at the end',
    (tester) async {
      final (l10n, player) = await _openSura1(
        tester,
        features: const FeatureFlags(quran: true, quranAudio: true),
        quranContent: FakeQuranContentRepository(),
        settings: _chosenReciter,
      );
      await longPressVerse(tester, placeholderVerse(1, 1));
      await tester.tap(find.text(l10n.quranListen));
      await tester.pumpAndSettle();

      player.complete();
      await tester.pumpAndSettle();
      expect(
        player.playedUrls.last,
        placeholderRecitationUrl(1, const VerseRef(1, 2)),
      );
    },
  );

  testWidgets(
    'a failed playback shows an error with retry in the mini player',
    (tester) async {
      final repo = FakeQuranContentRepository(failRecitation: true);
      final (l10n, _) = await _openSura1(
        tester,
        features: const FeatureFlags(quran: true, quranAudio: true),
        quranContent: repo,
        settings: _chosenReciter,
      );
      await longPressVerse(tester, placeholderVerse(1, 1));
      await tester.tap(find.text(l10n.quranListen));
      await tester.pumpAndSettle();
      expect(find.text(l10n.errorServer), findsOneWidget);

      repo.failRecitation = false;
      await tester.tap(find.byTooltip(l10n.retry));
      await tester.pumpAndSettle();
      expect(find.byTooltip(l10n.quranAudioStop), findsOneWidget);
    },
  );
}
