import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/features/settings/data/settings_repository_impl.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

FakeBackend _backend() => FakeBackend(
  pages: {
    '2:1': samplePage(ids: ['100', '101', '102'], totalItems: 3),
  },
);

void main() {
  group('Digits', () {
    test('Western leaves text alone', () {
      expect(Digits.western.format(197), '197');
      expect(Digits.western.localize('٣ results, 12%'), '٣ results, 12%');
    });

    test('Arabic-Indic rewrites every ASCII digit and nothing else', () {
      const d = Digits.arabicIndicDigits;
      expect(d.format(0), '٠');
      expect(d.format(1234567890), '١٢٣٤٥٦٧٨٩٠');
      expect(d.localize('175% وَ 3'), '١٧٥% وَ ٣');
      expect(d.localize('بلا أرقام'), 'بلا أرقام');
      expect(d.format(-5), '-٥');
    });

    test('equality is by value', () {
      expect(const Digits(arabicIndic: true), Digits.arabicIndicDigits);
      expect(Digits.western == Digits.arabicIndicDigits, isFalse);
    });
  });

  group('in the app', () {
    testWidgets('Arabic interface uses Arabic-Indic digits by default', (
      tester,
    ) async {
      await pumpApp(tester, _backend());
      expect(find.text('١٩٧'), findsOneWidget);
      expect(find.text('197'), findsNothing);
    });

    testWidgets('English interface uses Western digits by default', (
      tester,
    ) async {
      await pumpApp(tester, _backend(), locale: 'en');
      expect(find.text('197'), findsOneWidget);
    });

    testWidgets('the user can force Western digits in Arabic', (tester) async {
      await pumpApp(
        tester,
        _backend(),
        settings: const AppSettings(digits: DigitStyle.western),
      );
      expect(find.text('197'), findsOneWidget);
    });

    testWidgets('the user can force Arabic-Indic digits in English', (
      tester,
    ) async {
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        settings: const AppSettings(digits: DigitStyle.arabicIndic),
      );
      expect(find.text('١٩٧'), findsOneWidget);
    });

    testWidgets('digits in the content itself are never changed', (
      tester,
    ) async {
      await pumpApp(tester, _backend());
      await tapText(tester, 'جذر ثان');
      // The hadith titles contain a Western number as published; it must stay exactly so.
      expect(find.text('حديث 100'), findsOneWidget);
      expect(find.text('حديث ١٠٠'), findsNothing);
    });

    testWidgets(
      'choosing the numerals in Settings applies at once and is saved',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = SettingsRepositoryImpl(prefs);
        await pumpApp(tester, _backend(), repository: repo);
        expect(find.text('١٩٧'), findsOneWidget);

        await tapVisible(tester, find.byIcon(Icons.tune));
        await tapText(tester, 'الأرقام الغربية (0123)');
        await goBack(tester);
        expect(find.text('197'), findsOneWidget);
        expect((await repo.load()).digits, DigitStyle.western);
      },
    );
  });

  group('saved setting', () {
    test('unknown or missing values mean automatic', () async {
      SharedPreferences.setMockInitialValues({
        SettingsRepositoryImpl.digitsKey: 'eastern',
      });
      final repo = SettingsRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      expect((await repo.load()).digits, DigitStyle.automatic);
    });

    test('each choice round-trips', () async {
      for (final style in DigitStyle.values) {
        SharedPreferences.setMockInitialValues({});
        final repo = SettingsRepositoryImpl(
          await SharedPreferences.getInstance(),
        );
        await repo.save(AppSettings(digits: style));
        expect((await repo.load()).digits, style);
      }
    });
  });
}
