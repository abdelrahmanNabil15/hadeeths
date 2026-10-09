import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

FakeBackend _backend() => FakeBackend(
  pages: {
    '2:1': samplePage(
      ids: List.generate(8, (i) => '${100 + i}'),
      totalItems: 8,
    ),
  },
);

/// Walks every screen of the app and runs [check] on each.
Future<void> _forEachScreen(
  WidgetTester tester, {
  required String locale,
  required ThemePreference theme,
  required Future<void> Function(String screen) check,
}) async {
  final api = _backend();
  await pumpApp(
    tester,
    api,
    locale: locale,
    settings: AppSettings(theme: theme),
  );
  await check('home');

  await tapVisible(tester, find.byIcon(Icons.tune));
  await check('settings');
  await goBack(tester);

  await scrollAndTap(
    tester,
    find.text(locale == 'ar' ? 'المصادر والحقوق' : 'Sources and rights'),
  );
  await check('about');
  await goBack(tester);

  await tapVisible(tester, find.byIcon(Icons.search));
  await check('search');
  await tester.enterText(find.byType(TextField), 'ني');
  await tester.pump(const Duration(milliseconds: 100));
  await check('search-too-short');
  await tester.enterText(find.byType(TextField), 'النية');
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
  await check('search-results');
  await goBack(tester);

  await tapText(tester, 'جذر أول');
  await check('category');
  await goBack(tester);

  await tapText(tester, 'جذر ثان');
  await check('list');

  await tapText(tester, 'حديث 100');
  await check('details');
  await tapText(tester, locale == 'ar' ? 'الشرح' : 'Explanation');
  await check('details-expanded');
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance() + 0.05;
  final lb = b.computeLuminance() + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  group('text scaling and small screens', () {
    for (final locale in ['ar', 'en']) {
      for (final theme in [ThemePreference.light, ThemePreference.dark]) {
        for (final scale in [1.3, 2.0]) {
          testWidgets(
            'no overflow at ${(scale * 100).round()}% text on 360x640 ($locale, ${theme.name})',
            (tester) async {
              useSmallPhone(tester, textScale: scale);
              await _forEachScreen(
                tester,
                locale: locale,
                theme: theme,
                check: (screen) async {
                  expect(
                    tester.takeException(),
                    isNull,
                    reason: 'overflow on $screen',
                  );
                },
              );
            },
          );
        }
      }
    }

    testWidgets('error state fits at 200% text', (tester) async {
      useSmallPhone(tester, textScale: 2.0);
      await pumpApp(tester, _backend()..categoriesFailure = noConnection);
      expect(tester.takeException(), isNull);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });

  group('Flutter accessibility guidelines', () {
    for (final locale in ['ar', 'en']) {
      for (final theme in [ThemePreference.light, ThemePreference.dark]) {
        testWidgets(
          'tap targets, labels and contrast on every screen ($locale, ${theme.name})',
          (tester) async {
            final handle = tester.ensureSemantics();
            useSmallPhone(tester);
            await _forEachScreen(
              tester,
              locale: locale,
              theme: theme,
              check: (screen) async {
                await expectLater(
                  tester,
                  meetsGuideline(androidTapTargetGuideline),
                  reason: '$screen tap targets',
                );
                await expectLater(
                  tester,
                  meetsGuideline(labeledTapTargetGuideline),
                  reason: '$screen labels',
                );
                await expectLater(
                  tester,
                  meetsGuideline(textContrastGuideline),
                  reason: '$screen contrast',
                );
              },
            );
            handle.dispose();
          },
        );
      }
    }
  });

  group('semantics', () {
    testWidgets('category tiles announce title and count', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _backend(), locale: 'en');
      expect(find.bySemanticsLabel('جذر أول, 197'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('headings are marked as headers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _backend(), locale: 'en');
      expect(
        tester.getSemantics(find.text('Main categories')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('the share and text-size buttons have labels', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _backend(), locale: 'en');
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 100');
      expect(find.byTooltip('Share hadith'), findsOneWidget);
      expect(find.byTooltip('Text size'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an error is announced as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _backend()..categoriesFailure = noConnection,
        locale: 'en',
      );
      expect(
        tester.getSemantics(find.text('No internet connection')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('expandable sections announce expanded and collapsed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _backend(), locale: 'en');
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 100');
      expect(
        tester.getSemantics(find.text('Explanation')),
        isSemantics(isExpanded: false, isButton: true),
      );
      await tapText(tester, 'Explanation');
      expect(
        tester.getSemantics(find.text('Explanation')),
        isSemantics(isExpanded: true, isButton: true),
      );
      handle.dispose();
    });
  });

  group('colour contrast of the palettes (WCAG AA)', () {
    for (final entry in {
      'light': AppPalette.light,
      'dark': AppPalette.dark,
    }.entries) {
      final s = entry.value;
      final text = <String, (Color, Color)>{
        'body on canvas': (s.onSurface, s.surface),
        'body on reading surface': (s.onSurface, s.surfaceContainerLowest),
        'secondary text on canvas': (s.onSurfaceVariant, s.surface),
        'secondary text on cards': (
          s.onSurfaceVariant,
          s.surfaceContainerLowest,
        ),
        'brand colour on canvas': (s.primary, s.surface),
        'brand colour on cards': (s.primary, s.surfaceContainerLowest),
        'text on brand buttons': (s.onPrimary, s.primary),
        'text on the emphasised tile': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'grade chip text': (s.onSecondaryContainer, s.secondaryContainer),
        'gold on canvas': (s.secondary, s.surface),
        'error text on canvas': (s.error, s.surface),
        'snackbar text': (s.onInverseSurface, s.inverseSurface),
        'navigation bar: unselected label': (
          s.onSurfaceVariant,
          s.surfaceContainer,
        ),
        'navigation bar: selected label': (s.onSurface, s.surfaceContainer),
        'navigation bar: selected icon': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
      };
      text.forEach((name, pair) {
        test('${entry.key}: $name is at least 4.5:1', () {
          expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        });
      });

      test(
        '${entry.key}: control borders are at least 3:1 against the canvas and cards',
        () {
          expect(_contrast(s.outline, s.surface), greaterThanOrEqualTo(3.0));
          expect(
            _contrast(s.outline, s.surfaceContainerLowest),
            greaterThanOrEqualTo(3.0),
          );
        },
      );
    }
  });
}
