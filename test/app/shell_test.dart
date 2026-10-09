import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

FakeBackend _backend() => FakeBackend(
  pages: {
    '2:1': samplePage(ids: ['100', '101', '102'], totalItems: 3),
  },
);

const _all = FeatureFlags.all();

Future<void> _pump(
  WidgetTester tester, {
  String locale = 'ar',
  FeatureFlags features = _all,
  AppSettings settings = const AppSettings(),
}) => pumpApp(
  tester,
  _backend(),
  locale: locale,
  features: features,
  settings: settings,
);

Finder get _bar => find.byType(NavigationBar);

Finder _tab(String label) =>
    find.descendant(of: _bar, matching: find.text(label));

void main() {
  group('while no new section is switched on', () {
    testWidgets(
      'the app looks exactly as before: no bottom bar, settings in the app bar',
      (tester) async {
        await _pump(tester, features: const FeatureFlags());
        expect(_bar, findsNothing);
        expect(find.byIcon(Icons.tune), findsOneWidget);
        expect(find.text('المصادر والحقوق'), findsOneWidget);
      },
    );

    test('flags default to off', () {
      const flags = FeatureFlags();
      expect(flags.quran, isFalse);
      expect(flags.prayer, isFalse);
      expect(flags.usesShell, isFalse);
      expect(FeatureFlags.fromEnvironment().usesShell, isFalse);
    });
  });

  group('with the sections switched on', () {
    testWidgets('four destinations in Arabic, Hadiths first on the right', (
      tester,
    ) async {
      await _pump(tester);
      expect(_bar, findsOneWidget);
      for (final label in ['الأحاديث', 'المصحف', 'الصلاة', 'المزيد']) {
        expect(_tab(label), findsOneWidget, reason: label);
      }
      // Right-to-left: the first section is the right-most.
      expect(
        tester.getCenter(_tab('الأحاديث')).dx,
        greaterThan(tester.getCenter(_tab('المزيد')).dx),
      );
    });

    testWidgets('four destinations in English, Hadiths first on the left', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      for (final label in ['Hadiths', 'Quran', 'Prayer', 'More']) {
        expect(_tab(label), findsOneWidget, reason: label);
      }
      expect(
        tester.getCenter(_tab('Hadiths')).dx,
        lessThan(tester.getCenter(_tab('More')).dx),
      );
    });

    testWidgets('only the sections that are on appear', (tester) async {
      await _pump(
        tester,
        locale: 'en',
        features: const FeatureFlags(prayer: true),
      );
      expect(_tab('Hadiths'), findsOneWidget);
      expect(_tab('Prayer'), findsOneWidget);
      expect(_tab('More'), findsOneWidget);
      expect(_tab('Quran'), findsNothing);
    });

    testWidgets('the hadith home does not repeat settings or sources', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      expect(find.byIcon(Icons.tune), findsNothing);
      expect(find.text('Sources and rights'), findsNothing);
      expect(find.text('جذر ثان'), findsOneWidget);
    });

    testWidgets('unfinished sections say so', (tester) async {
      await _pump(tester, locale: 'en');
      await tester.tap(_tab('Quran'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Coming soon'), findsOneWidget);
      await tester.tap(_tab('Prayer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Coming soon'), findsOneWidget);
    });

    testWidgets('More leads to Settings and Sources, and the bar stays', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      await tester.tap(_tab('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
      expect(_bar, findsOneWidget);
      await goBack(tester);
      await tester.tap(find.text('Sources and rights'));
      await tester.pumpAndSettle();
      expect(find.text('Content'), findsOneWidget);
      expect(_bar, findsOneWidget);
    });

    testWidgets('changing the language from More switches the whole app', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      await tester.tap(_tab('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(_tab('الأحاديث'), findsOneWidget);
    });
  });

  group('navigation stacks', () {
    testWidgets('pages opened inside Hadiths keep the bar visible', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      await tapText(tester, 'جذر ثان');
      expect(find.text('حديث 100'), findsOneWidget);
      expect(_bar, findsOneWidget);
    });

    testWidgets('a section keeps its place when you switch away and back', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      await tapText(tester, 'جذر ثان');
      await tester.tap(_tab('More'));
      await tester.pumpAndSettle();
      expect(find.text('حديث 100'), findsNothing);
      await tester.tap(_tab('Hadiths'));
      await tester.pumpAndSettle();
      expect(find.text('حديث 100'), findsOneWidget);
    });

    testWidgets('tapping the current section returns to its first page', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      await tapText(tester, 'جذر ثان');
      await tester.tap(_tab('Hadiths'));
      await tester.pumpAndSettle();
      expect(find.text('حديث 100'), findsNothing);
      expect(find.text('Main categories'), findsOneWidget);
    });

    testWidgets('system back closes the open page first', (tester) async {
      await _pump(tester, locale: 'en');
      await tapText(tester, 'جذر ثان');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('حديث 100'), findsNothing);
      expect(find.text('Main categories'), findsOneWidget);
    });

    testWidgets('system back from another section returns to Hadiths', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      await tester.tap(_tab('More'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Main categories'), findsOneWidget);
      expect(tester.widget<NavigationBar>(_bar).selectedIndex, 0);
    });

    testWidgets(
      'system back closes a page opened in More before leaving More',
      (tester) async {
        await _pump(tester, locale: 'en');
        await tester.tap(_tab('More'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Appearance'), findsNothing);
        expect(tester.widget<NavigationBar>(_bar).selectedIndex, 3);
      },
    );
  });

  group('accessibility and layout', () {
    for (final locale in ['ar', 'en']) {
      for (final theme in [ThemePreference.light, ThemePreference.dark]) {
        testWidgets('guidelines hold in $locale / ${theme.name}', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _pump(
            tester,
            locale: locale,
            settings: AppSettings(theme: theme),
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }

    testWidgets('the bar is announced as a group of main sections', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, locale: 'en');
      expect(find.bySemanticsLabel('Main sections'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the selected section is exposed as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, locale: 'en');
      expect(
        tester.getSemantics(_tab('Hadiths')),
        isSemantics(
          label: 'Hadiths\nTab 1 of 4',
          isSelected: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets(
        'no overflow at ${(scale * 100).round()}% text on a small phone',
        (tester) async {
          useSmallPhone(tester, textScale: scale);
          await _pump(tester);
          expect(tester.takeException(), isNull);
          await tester.tap(_tab('المزيد'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(_bar, findsOneWidget);
        },
      );
    }
  });
}
