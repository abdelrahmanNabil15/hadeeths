import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/app.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/widgets/state_views.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';

FakeBackend _backend({Map<String, dynamic>? details}) => FakeBackend(
  details: details == null ? null : sampleDetails(details),
  pages: {
    '2:1': samplePage(ids: ['101', '102']),
  },
);

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

TextDirection _directionAt(WidgetTester tester, Finder finder) =>
    Directionality.of(tester.element(finder.first));

void main() {
  group('language selection', () {
    testWidgets('Arabic device: Arabic UI, right-to-left, Arabic content', (
      tester,
    ) async {
      final api = _backend();
      await _launch(tester, api, locale: 'ar');
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
      await _launch(tester, api, locale: 'en');
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
      await _launch(tester, api, locale: 'fr');
      expect(find.text('التصنيفات الرئيسية'), findsOneWidget);
      expect(api.languages, ['ar']);
    });

    testWidgets(
      'changing the device language reloads the tree in the new language',
      (tester) async {
        final api = _backend();
        await _launch(tester, api, locale: 'ar');
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
      await _launch(tester, api, locale: 'en');
      await tester.tap(find.text('جذر ثان'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حديث 101'));
      await tester.pumpAndSettle();
      // categories, list page, details
      expect(api.languages, ['en', 'en', 'en']);
    });
  });

  group('layout direction', () {
    double heading(WidgetTester tester, String text) =>
        tester.getCenter(find.text(text)).dx;

    testWidgets('the home heading sits at the start edge in both languages', (
      tester,
    ) async {
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      await _launch(tester, _backend(), locale: 'ar');
      expect(heading(tester, 'التصنيفات الرئيسية'), greaterThan(width / 2));

      await _launch(tester, _backend(), locale: 'en');
      expect(heading(tester, 'Main categories'), lessThan(width / 2));
    });

    testWidgets(
      'the details heading and share button swap sides with the language',
      (tester) async {
        Future<void> openDetails(String locale) async {
          await _launch(tester, _backend(), locale: locale);
          await tester.tap(find.text('جذر ثان'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('حديث 101'));
          await tester.pumpAndSettle();
        }

        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        await openDetails('ar');
        expect(heading(tester, 'الحديث:'), greaterThan(width / 2));
        expect(
          tester.getCenter(find.byIcon(Icons.share)).dx,
          lessThan(width / 2),
        );

        await openDetails('en');
        expect(heading(tester, 'Hadith:'), lessThan(width / 2));
        expect(
          tester.getCenter(find.byIcon(Icons.share)).dx,
          greaterThan(width / 2),
        );
      },
    );

    testWidgets('list chevrons mirror with the text direction', (tester) async {
      for (final locale in ['ar', 'en']) {
        await _launch(tester, _backend(), locale: locale);
        await tester.tap(find.text('جذر ثان'));
        await tester.pumpAndSettle();
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
        await _launch(tester, api, locale: 'en');
        await tester.tap(find.text('جذر ثان'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('حديث 101'));
        await tester.pumpAndSettle();
        expect(find.text('Narrated Abdullah ibn Masud'), findsOneWidget);
        expect(find.text('Explanation'), findsOneWidget);
        expect(find.text('Source: HadeethEnc.com'), findsOneWidget);
        expect(
          find.text('Sources'),
          findsNothing,
        ); // no reference in English responses
        expect(find.text('Word meanings:'), findsNothing);
      },
    );

    testWidgets('errors and retry are in English', (tester) async {
      final api = _backend()..categoriesFailure = noConnection;
      await _launch(tester, api, locale: 'en');
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
          await _launch(tester, api, locale: locale);
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
