import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/widgets/state_views.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

FakeBackend _backend({Map<String, dynamic>? details}) => FakeBackend(
  details: details == null ? null : sampleDetails(details),
  pages: {
    '2:1': samplePage(ids: ['101', '102']),
  },
);

TextDirection _directionAt(WidgetTester tester, Finder finder) =>
    Directionality.of(tester.element(finder.first));

void main() {
  group('language selection', () {
    testWidgets('Arabic device: Arabic UI, right-to-left, Arabic content', (
      tester,
    ) async {
      final api = _backend();
      await pumpApp(tester, api, locale: 'ar');
      expect(find.text('التصنيفات الرئيسية'), findsOneWidget);
      expect(
        _directionAt(tester, find.text('التصنيفات الرئيسية')),
        TextDirection.rtl,
      );
      expect(api.languages, ['ar']);
    });

    testWidgets('English device: English UI, left-to-right, English content', (
      tester,
    ) async {
      final api = _backend();
      await pumpApp(tester, api, locale: 'en');
      expect(find.text('Main categories'), findsOneWidget);
      expect(find.text('التصنيفات الرئيسية'), findsNothing);
      expect(
        _directionAt(tester, find.text('Main categories')),
        TextDirection.ltr,
      );
      expect(api.languages, ['en']);
    });

    testWidgets('any other device language falls back to Arabic', (
      tester,
    ) async {
      final api = _backend();
      await pumpApp(tester, api, locale: 'fr');
      expect(find.text('التصنيفات الرئيسية'), findsOneWidget);
      expect(api.languages, ['ar']);
    });

    testWidgets(
      'changing the device language reloads the tree in the new language',
      (tester) async {
        final api = _backend();
        await pumpApp(tester, api, locale: 'ar');
        tester.platformDispatcher.localesTestValue = const [Locale('en')];
        await tester.pumpAndSettle();
        expect(find.text('Main categories'), findsOneWidget);
        expect(api.languages, ['ar', 'en']);
      },
    );

    testWidgets('list and details requests carry the UI language', (
      tester,
    ) async {
      final api = _backend();
      await pumpApp(tester, api, locale: 'en');
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 101');
      // categories, list page, details
      expect(api.languages, ['en', 'en', 'en']);
    });
  });

  group('layout direction', () {
    double centre(WidgetTester tester, Finder f) =>
        tester.getCenter(f.first).dx;

    testWidgets(
      'tile chevrons sit at the end edge and the settings action at the end of the bar',
      (tester) async {
        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        await pumpApp(tester, _backend(), locale: 'ar');
        expect(
          centre(tester, find.byIcon(Icons.arrow_forward_ios)),
          lessThan(width / 2),
        );
        expect(centre(tester, find.byIcon(Icons.tune)), lessThan(width / 2));

        await pumpApp(tester, _backend(), locale: 'en');
        expect(
          centre(tester, find.byIcon(Icons.arrow_forward_ios)),
          greaterThan(width / 2),
        );
        expect(centre(tester, find.byIcon(Icons.tune)), greaterThan(width / 2));
      },
    );

    testWidgets(
      'the back button and the share action swap sides with the language',
      (tester) async {
        Future<void> openDetails(String locale) async {
          await pumpApp(tester, _backend(), locale: locale);
          await tapText(tester, 'جذر ثان');
          await tapText(tester, 'حديث 101');
        }

        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        await openDetails('ar');
        expect(centre(tester, find.byType(BackButton)), greaterThan(width / 2));
        expect(centre(tester, find.byIcon(Icons.share)), lessThan(width / 2));

        await openDetails('en');
        expect(centre(tester, find.byType(BackButton)), lessThan(width / 2));
        expect(
          centre(tester, find.byIcon(Icons.share)),
          greaterThan(width / 2),
        );
      },
    );

    testWidgets('tile chevrons mirror with the text direction', (tester) async {
      for (final locale in ['ar', 'en']) {
        await pumpApp(tester, _backend(), locale: locale);
        final icon = tester.widget<Icon>(
          find.byIcon(Icons.arrow_forward_ios).first,
        );
        expect(icon.icon!.matchTextDirection, isTrue);
      }
    });
  });

  group('English content and messages', () {
    testWidgets(
      'English details: English labels, credit, no Arabic-only sections',
      (tester) async {
        final api = _backend(details: englishDetailsJson);
        await pumpApp(tester, api, locale: 'en');
        await tapText(tester, 'جذر ثان');
        await tapText(tester, 'حديث 101');
        expect(find.text('Narrated Abdullah ibn Masud'), findsOneWidget);
        expect(find.text('Explanation'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Source: HadeethEnc.com'),
          300,
        );
        expect(find.text('Source: HadeethEnc.com'), findsOneWidget);
        expect(
          find.text('Sources'),
          findsNothing,
        ); // no reference in English responses
        expect(find.text('Word meanings'), findsNothing);
      },
    );

    testWidgets('errors and retry are in English', (tester) async {
      final api = _backend()..categoriesFailure = noConnection;
      await pumpApp(tester, api, locale: 'en');
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Main categories'), findsOneWidget);
    });

    testWidgets('every failure kind has its own message in both languages', (
      tester,
    ) async {
      for (final locale in ['ar', 'en']) {
        final messages = <String>{};
        for (final kind in FailureKind.values) {
          final api = _backend()..categoriesFailure = Failure(kind);
          await pumpApp(tester, api, locale: locale);
          final message = tester
              .widget<Text>(
                find
                    .descendant(
                      of: find.byType(ErrorView),
                      matching: find.byType(Text),
                    )
                    .first,
              )
              .data!;
          messages.add(message);
        }
        expect(messages, hasLength(FailureKind.values.length), reason: locale);
      }
    });
  });
}
