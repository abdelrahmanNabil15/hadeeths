import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/features/hadiths/presentation/widgets/reading_surface.dart';

/// Fully voweled text with honorific marks, as the source gives it.
const _arabic =
    'عَنْ عَبْدِ اللهِ بْنِ مَسْعُودٍ رَضِيَ اللهُ عَنْهُ قَالَ: قَالَ رَسُولُ اللهِ ﷺ: '
    '«إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى»';

final _themes = {'light': AppTheme.light(), 'dark': AppTheme.dark()};

Widget _app(
  String text, {
  required String locale,
  required ThemeData theme,
  double textScale = 1,
  double readingScale = 1,
  bool reduce = false,
}) => MaterialApp(
  theme: theme,
  locale: Locale(locale),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduce,
    ),
    child: app!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: ReadingSurface(text: text, scale: readingScale),
    ),
  ),
);

void main() {
  group('the reading surface', () {
    for (final entry in _themes.entries) {
      testWidgets(
        '${entry.key}: shows the source text exactly, vowels and marks included',
        (tester) async {
          await tester.pumpWidget(
            _app(_arabic, locale: 'ar', theme: entry.value),
          );
          final shown = tester.widget<Text>(
            find.descendant(
              of: find.byType(ReadingSurface),
              matching: find.byType(Text),
            ),
          );
          expect(shown.data, _arabic);
          expect(shown.overflow, isNull);
          expect(shown.maxLines, isNull);
        },
      );
    }

    testWidgets('Arabic uses the reading font with full-vowel line height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_arabic, locale: 'ar', theme: _themes['light']!),
      );
      final style = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(ReadingSurface),
              matching: find.byType(Text),
            ),
          )
          .style!;
      expect(style.fontFamily, AppFonts.reading);
      expect(style.height, AppLineHeight.readingArabic);
      expect(style.fontSize, AppTextSize.readingArabic);
    });

    testWidgets('English uses the interface font', (tester) async {
      await tester.pumpWidget(
        _app('Islam is built on five', locale: 'en', theme: _themes['light']!),
      );
      final style = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(ReadingSurface),
              matching: find.byType(Text),
            ),
          )
          .style!;
      expect(style.fontFamily, AppFonts.ui);
      expect(style.height, AppLineHeight.readingLatin);
    });

    testWidgets('the reading-size setting scales the text', (tester) async {
      await tester.pumpWidget(
        _app(
          _arabic,
          locale: 'ar',
          theme: _themes['light']!,
          readingScale: 1.5,
        ),
      );
      final style = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(ReadingSurface),
              matching: find.byType(Text),
            ),
          )
          .style!;
      expect(style.fontSize, AppTextSize.readingArabic * 1.5);
    });

    for (final entry in _themes.entries) {
      testWidgets(
        '${entry.key}: fits a small phone at 200% text and stays selectable',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _app(_arabic, locale: 'ar', theme: entry.value, textScale: 2),
          );
          expect(tester.takeException(), isNull);
          expect(
            find.descendant(
              of: find.byType(ReadingSurface),
              matching: find.byType(SelectionArea),
            ),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets(
      'nothing around the text animates, with or without reduced motion',
      (tester) async {
        for (final reduce in [false, true]) {
          await tester.pumpWidget(
            _app(
              _arabic,
              locale: 'ar',
              theme: _themes['light']!,
              reduce: reduce,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.hasRunningAnimations, isFalse);
          for (final type in [
            AnimatedOpacity,
            AnimatedSwitcher,
            AnimatedScale,
            AnimatedSlide,
            AnimatedRotation,
            BackdropFilter,
          ]) {
            expect(
              find.descendant(
                of: find.byType(ReadingSurface),
                matching: find.byType(type),
              ),
              findsNothing,
              reason: '$type inside the reading surface',
            );
          }
        }
      },
    );
  });
}
