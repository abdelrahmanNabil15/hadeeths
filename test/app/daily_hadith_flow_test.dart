import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';
import 'package:mynewapp/features/daily_hadith/data/prefs_daily_hadith_store.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_store.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_details_page.dart';
import 'package:mynewapp/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

const _on = FeatureFlags(dailyHadith: true);

/// Both root categories have one page; the second has the hadiths 200 to 204.
FakeBackend _backend() => FakeBackend(
  pages: {
    '1:1': samplePage(
      ids: [for (var i = 100; i < 120; i++) '$i'],
      totalItems: 20,
    ),
    '2:1': samplePage(
      ids: [for (var i = 200; i < 205; i++) '$i'],
      totalItems: 5,
    ),
  },
);

Future<DailyHadithStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return PrefsDailyHadithStore(await SharedPreferences.getInstance());
}

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  required FakeBackend api,
  DailyHadithStore? store,
  FeatureFlags features = _on,
  String locale = 'en',
}) async {
  tester.view.physicalSize = const Size(600, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    api,
    locale: locale,
    features: features,
    dailyHadith: store,
  );
  return lookupAppLocalizations(Locale(locale));
}

final _hadithTitle = find.textContaining(RegExp(r'^حديث \d+$'));

void main() {
  testWidgets('the home screen shows the hadith of the day with its source', (
    tester,
  ) async {
    final l10n = await _pump(tester, api: _backend(), store: await _store());
    expect(find.text(l10n.dailyHadithHeading), findsOneWidget);
    expect(_hadithTitle, findsOneWidget);
    expect(find.textContaining(l10n.dailyHadithFrom('')), findsOneWidget);
    expect(find.text(l10n.sourceCredit), findsWidgets);
  });

  testWidgets('tapping it opens the hadith', (tester) async {
    await _pump(tester, api: _backend(), store: await _store());
    await tester.tap(_hadithTitle);
    await tester.pumpAndSettle();
    expect(find.byType(HadithDetailsPage), findsOneWidget);
  });

  testWidgets('opening a category\'s hadiths is remembered', (tester) async {
    final store = await _store();
    await _pump(tester, api: _backend(), store: store);
    await tapText(tester, categoriesJson[1]['title']!);
    expect(await store.openedCategories(), ['2']);
  });

  testWidgets('without its section: no card and nothing remembered', (
    tester,
  ) async {
    final store = await _store();
    final l10n = await _pump(
      tester,
      api: _backend(),
      store: store,
      features: const FeatureFlags(),
    );
    expect(find.text(l10n.dailyHadithHeading), findsNothing);
    await tapText(tester, categoriesJson[1]['title']!);
    expect(await store.openedCategories(), isEmpty);
  });

  testWidgets('when it cannot load, it says so and can retry', (tester) async {
    final api = _backend()
      ..pageFailure = const Failure(FailureKind.noConnection);
    final l10n = await _pump(tester, api: api, store: await _store());
    expect(find.text(l10n.dailyHadithUnavailable), findsOneWidget);
    await tester.tap(find.text(l10n.retry).last);
    await tester.pumpAndSettle();
    expect(_hadithTitle, findsOneWidget);
  });

  testWidgets('with nothing to choose from, the section is not shown', (
    tester,
  ) async {
    final api = _backend()
      ..categories = [
        const HadithCategory(id: '3', title: 'Empty', hadithCount: 0),
      ];
    final l10n = await _pump(tester, api: api, store: await _store());
    expect(find.text(l10n.dailyHadithHeading), findsNothing);
  });

  testWidgets('settings: the remember switch forgets opened categories', (
    tester,
  ) async {
    final store = await _store();
    await store.recordOpened('2');
    final l10n = await _pump(
      tester,
      api: _backend(),
      store: store,
      features: const FeatureFlags(dailyHadith: true, prayer: true),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navMore),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, l10n.settings);
    await scrollAndTap(tester, find.text(l10n.dailyHadithRemember));
    expect(await store.remembersOpened(), isFalse);
    expect(await store.openedCategories(), isEmpty);
  });

  testWidgets('Delete all my data clears it', (tester) async {
    final store = await _store();
    await store.recordOpened('2');
    final deps = testDependencies(_backend(), dailyHadith: store);
    expect(await deps.eraser.eraseAll(), isTrue);
    expect(await store.openedCategories(), isEmpty);
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('$locale: 200% text, tap targets and labels on home', (
      tester,
    ) async {
      useSmallPhone(tester, textScale: 2);
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _backend(),
        locale: locale,
        features: _on,
        dailyHadith: await _store(),
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
