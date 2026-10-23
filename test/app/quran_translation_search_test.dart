import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/quran_fakes.dart';
import '../support/test_app.dart';

const _chosenEdition = AppSettings(
  quranTranslationEditionId: 1,
  quranTranslationEditionName: 'Placeholder Edition One',
);

Future<AppLocalizations> _openSearch(
  WidgetTester tester, {
  required FeatureFlags features,
  FakeQuranContentRepository? quranContent,
  AppSettings settings = const AppSettings(),
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    FakeBackend(),
    locale: 'en',
    settings: settings,
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
  await tester.tap(find.text(l10n.quranSearchHint));
  await tester.pumpAndSettle();
  return l10n;
}

Future<void> _submit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the flag off: no mode switch, only the on-device field', (
    tester,
  ) async {
    final l10n = await _openSearch(
      tester,
      features: const FeatureFlags(
        quran: true,
        quranTranslations: true,
        quranTranslationSearch: false,
      ),
      quranContent: FakeQuranContentRepository(),
      settings: _chosenEdition,
    );
    expect(find.text(l10n.quranSearchTabQuran), findsNothing);
  });

  testWidgets('the flag on but translations off: still no mode switch', (
    tester,
  ) async {
    final l10n = await _openSearch(
      tester,
      features: const FeatureFlags(
        quran: true,
        quranTranslations: false,
        quranTranslationSearch: true,
      ),
      quranContent: FakeQuranContentRepository(),
      settings: _chosenEdition,
    );
    expect(find.text(l10n.quranSearchTabQuran), findsNothing);
  });

  testWidgets(
    'both flags on: the mode switch appears, and without a chosen edition the '
    'translation tab asks to pick one first',
    (tester) async {
      final l10n = await _openSearch(
        tester,
        features: const FeatureFlags(
          quran: true,
          quranTranslations: true,
          quranTranslationSearch: true,
        ),
        quranContent: FakeQuranContentRepository(),
      );
      expect(find.text(l10n.quranSearchTabQuran), findsOneWidget);

      await tester.tap(find.text(l10n.quranTranslation));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.quranTranslationSearchNeedsEdition),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.quranChooseTranslation));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Placeholder Edition One'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.quranTranslationSearchNeedsEdition), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets(
    'searching a chosen translation shows matches, credit and pagination',
    (tester) async {
      final l10n = await _openSearch(
        tester,
        features: const FeatureFlags(
          quran: true,
          quranTranslations: true,
          quranTranslationSearch: true,
        ),
        quranContent: FakeQuranContentRepository(),
        settings: _chosenEdition,
      );
      await tester.tap(find.text(l10n.quranTranslation));
      await tester.pumpAndSettle();

      await _submit(tester, 'snippet');
      expect(find.text('placeholder snippet alpha'), findsOneWidget);
      expect(find.text('placeholder snippet beta'), findsOneWidget);
      expect(find.text('placeholder snippet gamma'), findsNothing);
      expect(
        find.text(l10n.quranTranslationCredit('Placeholder Edition One')),
        findsNWidgets(2),
      );
      expect(find.text(l10n.quranSearchLoadMore), findsOneWidget);

      await tester.tap(find.text(l10n.quranSearchLoadMore));
      await tester.pumpAndSettle();
      expect(find.text('placeholder snippet gamma'), findsOneWidget);
      expect(find.text(l10n.quranSearchLoadMore), findsNothing);
    },
  );

  testWidgets('no match: the "no results" message is shown', (tester) async {
    final l10n = await _openSearch(
      tester,
      features: const FeatureFlags(
        quran: true,
        quranTranslations: true,
        quranTranslationSearch: true,
      ),
      quranContent: FakeQuranContentRepository(),
      settings: _chosenEdition,
    );
    await tester.tap(find.text(l10n.quranTranslation));
    await tester.pumpAndSettle();

    await _submit(tester, 'nothing matches this');
    expect(find.text(l10n.quranNoResults), findsOneWidget);
  });

  testWidgets('a failed search shows an error with retry', (tester) async {
    final repo = FakeQuranContentRepository(failSearch: true);
    final l10n = await _openSearch(
      tester,
      features: const FeatureFlags(
        quran: true,
        quranTranslations: true,
        quranTranslationSearch: true,
      ),
      quranContent: repo,
      settings: _chosenEdition,
    );
    await tester.tap(find.text(l10n.quranTranslation));
    await tester.pumpAndSettle();

    await _submit(tester, 'snippet');
    expect(find.text(l10n.errorServer), findsOneWidget);

    repo.failSearch = false;
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.text('placeholder snippet alpha'), findsOneWidget);
  });

  testWidgets(
    'a failed "load more" keeps the results already shown, with its own retry',
    (tester) async {
      final repo = FakeQuranContentRepository();
      final l10n = await _openSearch(
        tester,
        features: const FeatureFlags(
          quran: true,
          quranTranslations: true,
          quranTranslationSearch: true,
        ),
        quranContent: repo,
        settings: _chosenEdition,
      );
      await tester.tap(find.text(l10n.quranTranslation));
      await tester.pumpAndSettle();
      await _submit(tester, 'snippet');

      repo.failSearch = true;
      await tester.tap(find.text(l10n.quranSearchLoadMore));
      await tester.pumpAndSettle();
      expect(find.text('placeholder snippet alpha'), findsOneWidget);
      expect(find.text(l10n.quranSearchLoadMoreFailed), findsOneWidget);

      repo.failSearch = false;
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(find.text('placeholder snippet gamma'), findsOneWidget);
    },
  );
}
