import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/categories/presentation/pages/category_page.dart';
import 'package:mynewapp/features/categories/presentation/pages/home_page.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_details_page.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_list_page.dart';
import 'package:mynewapp/features/hadiths/presentation/widgets/reading_surface.dart';

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

Route<dynamic>? _routeOf(WidgetTester tester, Type page) =>
    ModalRoute.of(tester.element(find.byType(page)));

void main() {
  group('every screen uses the app transition', () {
    test('no screen builds a platform page route by hand', () {
      final offenders = [
        for (final entity in Directory('lib').listSync(recursive: true))
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !entity.path
                  .replaceAll(r'\', '/')
                  .endsWith('core/navigation/app_route.dart') &&
              entity.readAsStringSync().contains('MaterialPageRoute'))
            entity.path,
      ];
      expect(offenders, isEmpty);
    });

    testWidgets('the first page, a category, a list and a hadith all do', (
      tester,
    ) async {
      await pumpApp(tester, _backend(), locale: 'ar');
      expect(_routeOf(tester, HomePage), isA<AppPageRoute<dynamic>>());
      await tapText(tester, 'جذر أول');
      expect(_routeOf(tester, CategoryPage), isA<AppPageRoute<dynamic>>());
      await goBack(tester);
      await tapText(tester, 'جذر ثان');
      expect(_routeOf(tester, HadithListPage), isA<AppPageRoute<dynamic>>());
      await tapText(tester, 'حديث 100');
      expect(_routeOf(tester, HadithDetailsPage), isA<AppPageRoute<dynamic>>());
    });

    testWidgets('going back from a hadith returns to the same list', (
      tester,
    ) async {
      await pumpApp(tester, _backend(), locale: 'ar');
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 100');
      await goBack(tester);
      expect(find.text('حديث 100'), findsOneWidget);
      expect(find.byType(HadithDetailsPage), findsNothing);
    });
  });

  group('loading to content', () {
    testWidgets('the home screen fades from the skeleton to the categories', (
      tester,
    ) async {
      await pumpApp(tester, _backend(), locale: 'ar', settle: false);
      expect(
        find.ancestor(
          of: find.byType(SkeletonList),
          matching: find.byType(AnimatedStateSwitcher),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonList), findsNothing);
      expect(find.text('جذر أول'), findsOneWidget);
    });

    testWidgets('the list does not fade again while it stays loaded', (
      tester,
    ) async {
      await pumpApp(tester, _backend(), locale: 'ar');
      await tapText(tester, 'جذر ثان');
      await tester.pumpAndSettle();
      expect(find.text('حديث 100'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the hadith text is never inside a fading switcher', (
      tester,
    ) async {
      await pumpApp(tester, _backend(), locale: 'ar');
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 100');
      await tester.pumpAndSettle();
      expect(find.byType(ReadingSurface), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(ReadingSurface),
          matching: find.byType(AnimatedSwitcher),
        ),
        findsNothing,
      );
    });
  });
}
