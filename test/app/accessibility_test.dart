import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/app.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';

FakeBackend _backend() => FakeBackend(
  pages: {
    // Long titles and many items exercise wrapping and scrolling.
    '2:1': samplePage(
      ids: List.generate(8, (i) => '${100 + i}'),
      totalItems: 8,
    ),
  },
);

/// A small phone: 360x640 logical pixels.
void _smallPhone(WidgetTester tester, {double textScale = 1.0}) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _launch(
  WidgetTester tester,
  FakeBackend api, {
  required String locale,
}) async {
  tester.platformDispatcher.localesTestValue = [Locale(locale)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    MyApp(
      key: UniqueKey(),
      dependencies: AppDependencies(categories: api, hadiths: api),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls [text] into view (at large text sizes cards move below the fold), then taps it.
Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Walks the four screens and runs [check] on each.
Future<void> _forEachScreen(
  WidgetTester tester,
  String locale,
  Future<void> Function(String screen) check,
) async {
  final api = _backend();
  await _launch(tester, api, locale: locale);
  await check('home');

  await _tapText(tester, 'جذر أول');
  await check('category');
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();

  await _tapText(tester, 'جذر ثان');
  await check('list');

  await _tapText(tester, 'حديث 100');
  await check('details');
}

double _contrast(Color foreground, Color background) {
  final bg = Color.alphaBlend(background, Colors.white);
  final fg = Color.alphaBlend(foreground, bg);
  final a = fg.computeLuminance() + 0.05;
  final b = bg.computeLuminance() + 0.05;
  return a > b ? a / b : b / a;
}

void main() {
  group('text scaling and small screens', () {
    for (final locale in ['ar', 'en']) {
      testWidgets('no overflow at 200% text on a 360x640 phone ($locale)', (
        tester,
      ) async {
        _smallPhone(tester, textScale: 2.0);
        await _forEachScreen(tester, locale, (screen) async {
          expect(tester.takeException(), isNull, reason: 'overflow on $screen');
        });
      });

      testWidgets('no overflow at 130% text, as on the test phone ($locale)', (
        tester,
      ) async {
        _smallPhone(tester, textScale: 1.3);
        await _forEachScreen(tester, locale, (screen) async {
          expect(tester.takeException(), isNull, reason: 'overflow on $screen');
        });
      });
    }

    testWidgets('error state fits at 200% text', (tester) async {
      _smallPhone(tester, textScale: 2.0);
      await _launch(
        tester,
        _backend()..categoriesFailure = noConnection,
        locale: 'ar',
      );
      expect(tester.takeException(), isNull);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });

  group('Flutter accessibility guidelines', () {
    for (final locale in ['ar', 'en']) {
      testWidgets('tap targets are large enough and labelled ($locale)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        _smallPhone(tester);
        await _forEachScreen(tester, locale, (screen) async {
          await expectLater(
            tester,
            meetsGuideline(androidTapTargetGuideline),
            reason: screen,
          );
          await expectLater(
            tester,
            meetsGuideline(labeledTapTargetGuideline),
            reason: screen,
          );
        });
        handle.dispose();
      });
    }
  });

  group('rendered text contrast (Flutter textContrastGuideline)', () {
    for (final locale in ['ar', 'en']) {
      testWidgets('list, details and category screens ($locale)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        _smallPhone(tester);
        await _forEachScreen(tester, locale, (screen) async {
          // Home sits on the photographic backdrop, which the pixel sampler cannot judge.
          if (screen == 'home') return;
          await expectLater(
            tester,
            meetsGuideline(textContrastGuideline),
            reason: screen,
          );
        });
        handle.dispose();
      });
    }
  });

  group('semantics', () {
    testWidgets('category cards announce title and count', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(tester, _backend(), locale: 'en');
      expect(find.bySemanticsLabel('جذر أول, 197'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('headings are marked as headers', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(tester, _backend(), locale: 'en');
      expect(
        tester.getSemantics(find.text('Main categories')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('the share button has a label', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(tester, _backend(), locale: 'en');
      await tester.tap(find.text('جذر ثان'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حديث 100'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Share hadith'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an error is announced as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(
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
  });

  group('colour contrast of the design tokens (WCAG AA: 4.5:1 for text)', () {
    final appBarOverWhite = Color.alphaBlend(AppColors.appBar, Colors.white);
    final homeBarOverWhite = Color.alphaBlend(
      AppColors.homeAppBar,
      Colors.white,
    );
    final cardOverWhite = Color.alphaBlend(AppColors.cardFill, Colors.white);

    final pairs = <String, (Color, Color)>{
      'app bar title': (AppColors.onAppBar, appBarOverWhite),
      'home app bar title': (AppColors.onAppBar, homeBarOverWhite),
      'ink on white': (AppColors.ink, Colors.white),
      'muted text on white': (AppColors.inkMuted, Colors.white),
      'muted text on cards': (AppColors.inkMuted, cardOverWhite),
      'headings on white': (AppColors.heading, Colors.white),
      'grade and attribution on white': (AppColors.accent, Colors.white),
      'list titles on white': (AppColors.listTitle, Colors.white),
    };

    pairs.forEach((name, pair) {
      test(name, () {
        final ratio = _contrast(pair.$1, pair.$2);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: 'was $ratio');
      });
    });

    test(
      'the original white app-bar title failed, which is why it changed',
      () {
        expect(_contrast(Colors.white, appBarOverWhite), lessThan(1.5));
      },
    );
  });
}
