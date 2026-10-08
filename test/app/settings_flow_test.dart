import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

FakeBackend _backend() => FakeBackend(
  pages: {
    '2:1': samplePage(ids: ['101', '102']),
  },
);

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

Future<void> _openSettings(WidgetTester tester) =>
    tapVisible(tester, find.byIcon(Icons.tune));

/// Font size of the Text showing [content].
double _fontSizeOf(WidgetTester tester, String content) =>
    tester.widget<Text>(find.text(content)).style!.fontSize!;

void main() {
  group('language', () {
    testWidgets(
      'choosing English switches the UI and reloads the content in English',
      (tester) async {
        final api = _backend();
        final repo = InMemorySettingsRepository();
        await pumpApp(tester, api, locale: 'ar', repository: repo);
        await _openSettings(tester);
        await tapText(tester, 'English');

        expect(find.text('Settings'), findsOneWidget);
        expect(repo.stored.language, AppLanguage.english);
        await goBack(tester);
        expect(find.text('Main categories'), findsOneWidget);
        expect(api.languages, ['ar', 'en']);
      },
    );

    testWidgets('choosing Arabic on an English device switches to Arabic', (
      tester,
    ) async {
      final api = _backend();
      await pumpApp(tester, api, locale: 'en');
      await _openSettings(tester);
      await tapText(tester, 'العربية');
      await goBack(tester);
      expect(find.text('التصنيفات الرئيسية'), findsOneWidget);
      expect(api.languages, ['en', 'ar']);
    });

    testWidgets('the chosen option shows a check mark', (tester) async {
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        settings: const AppSettings(language: AppLanguage.english),
      );
      await _openSettings(tester);
      final checks = find.byIcon(Icons.check_circle);
      // one for the language, one for the appearance (system by default)
      expect(checks, findsNWidgets(2));
    });
  });

  group('appearance', () {
    testWidgets('light, dark and device follow the choice', (tester) async {
      final repo = InMemorySettingsRepository();
      await pumpApp(tester, _backend(), locale: 'en', repository: repo);
      expect(_brightness(tester), Brightness.light); // the test device is light

      await _openSettings(tester);
      await tapText(tester, 'Dark');
      expect(_brightness(tester), Brightness.dark);
      expect(repo.stored.theme, ThemePreference.dark);

      await tapText(tester, 'Light');
      expect(_brightness(tester), Brightness.light);
      expect(repo.stored.theme, ThemePreference.light);
    });

    testWidgets('the dark theme uses the dark palette', (tester) async {
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        settings: const AppSettings(theme: ThemePreference.dark),
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).colorScheme.surface, AppPalette.dark.surface);
      expect(scaffold.backgroundColor, isNull); // taken from the theme
    });
  });

  group('saved settings', () {
    testWidgets('are applied at launch, before the first frame shows content', (
      tester,
    ) async {
      final api = _backend();
      await pumpApp(
        tester,
        api,
        locale: 'ar', // the device says Arabic, the saved choice says English
        settings: const AppSettings(
          language: AppLanguage.english,
          theme: ThemePreference.dark,
        ),
      );
      expect(find.text('Main categories'), findsOneWidget);
      expect(_brightness(tester), Brightness.dark);
      expect(api.languages, ['en']); // never loaded in the wrong language first
    });
  });

  group('reading size', () {
    const hadith = 'عَنْ عَبْدِ اللهِ بنِ مَسْعُودٍ رضي الله عنه';

    Future<void> openDetails(
      WidgetTester tester, {
      String locale = 'ar',
      AppSettings settings = const AppSettings(),
      InMemorySettingsRepository? repo,
    }) async {
      await pumpApp(
        tester,
        _backend(),
        locale: locale,
        settings: settings,
        repository: repo,
      );
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 101');
    }

    testWidgets('the hadith starts at the base size', (tester) async {
      await openDetails(tester);
      expect(_fontSizeOf(tester, hadith), AppTextSize.readingArabic);
    });

    testWidgets(
      'the size button makes the hadith larger and smaller, and saves it',
      (tester) async {
        final repo = InMemorySettingsRepository();
        await openDetails(tester, repo: repo);
        await tapVisible(tester, find.byTooltip('حجم النص'));
        await tester.tap(find.byIcon(Icons.text_increase));
        await tester.pumpAndSettle();
        expect(repo.stored.readingScale, 1.15);

        await tester.tap(find.byIcon(Icons.text_decrease));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.text_decrease));
        await tester.pumpAndSettle();
        expect(repo.stored.readingScale, 0.85);
        // at the smallest step the button is disabled
        final button = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.text_decrease),
        );
        expect(button.onPressed, isNull);

        // close the sheet and look at the hadith itself
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(
          _fontSizeOf(tester, hadith),
          closeTo(AppTextSize.readingArabic * 0.85, 0.001),
        );
      },
    );

    testWidgets('a saved size is used when the hadith opens', (tester) async {
      await openDetails(tester, settings: const AppSettings(readingScale: 1.5));
      expect(
        _fontSizeOf(tester, hadith),
        closeTo(AppTextSize.readingArabic * 1.5, 0.001),
      );
    });

    testWidgets('Arabic uses the Naskh reading font with generous leading', (
      tester,
    ) async {
      await openDetails(tester);
      final style = tester.widget<Text>(find.text(hadith)).style!;
      expect(style.fontFamily, AppFonts.reading);
      expect(style.height, AppLineHeight.readingArabic);
    });

    testWidgets('English uses the UI font', (tester) async {
      await pumpApp(
        tester,
        FakeBackend(
          details: sampleDetails(englishDetailsJson),
          pages: {
            '2:1': samplePage(ids: ['101']),
          },
        ),
        locale: 'en',
      );
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 101');
      final style = tester
          .widget<Text>(find.text('Narrated Abdullah ibn Masud'))
          .style!;
      expect(style.fontFamily, AppFonts.ui);
      expect(style.fontSize, AppTextSize.readingLatin);
    });
  });

  group('about', () {
    testWidgets(
      'credits HadeethEnc, lists the fonts and states the privacy position',
      (tester) async {
        await pumpApp(tester, _backend(), locale: 'en');
        await scrollAndTap(tester, find.text('Sources and rights'));
        expect(find.text('Source: HadeethEnc.com'), findsOneWidget);
        expect(
          find.textContaining('shown exactly as published'),
          findsOneWidget,
        );
        expect(find.textContaining('Cairo and Amiri'), findsOneWidget);
        expect(
          find.textContaining('collects no personal data'),
          findsOneWidget,
        );
      },
    );

    testWidgets('opens the licence page with the bundled fonts', (
      tester,
    ) async {
      await pumpApp(tester, _backend(), locale: 'en');
      await scrollAndTap(tester, find.text('Sources and rights'));
      await tapText(tester, 'Open-source licences');
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
