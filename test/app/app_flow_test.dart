import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/widgets/state_views.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

const _credit = 'المصدر: HadeethEnc.com';
const _retry = 'إعادة المحاولة';
const _offline = 'لا يوجد اتصال بالإنترنت';

FakeBackend _api({Map<String, dynamic>? details}) => FakeBackend(
  details: details == null ? null : sampleDetails(details),
  pages: {
    '2:1': samplePage(ids: ['101', '102', '103'], totalItems: 500),
    '8:1': samplePage(ids: ['201']),
    '1:1': samplePage(ids: ['301', '302']),
  },
);

void main() {
  group('home', () {
    testWidgets('shows only root categories, with their counts', (
      tester,
    ) async {
      await pumpApp(tester, _api());
      expect(find.text('جذر أول'), findsOneWidget);
      expect(find.text('جذر ثان'), findsOneWidget);
      expect(find.text('197'), findsOneWidget);
      expect(find.text('فرع ثمانية'), findsNothing);
      expect(find.text('حفيد'), findsNothing);
    });

    testWidgets('shows placeholders while loading, then the content', (
      tester,
    ) async {
      final api = _api()..gate = Completer<void>();
      await pumpApp(tester, api, settle: false);
      await tester.pump();
      expect(find.byType(SkeletonList), findsOneWidget);
      api.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonList), findsNothing);
      expect(find.text('جذر أول'), findsOneWidget);
    });

    testWidgets(
      'a failure shows a message and retry, never an endless spinner',
      (tester) async {
        final api = _api()..categoriesFailure = noConnection;
        await pumpApp(tester, api);
        expect(find.text(_offline), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(SkeletonList), findsNothing);

        await tester.tap(find.text(_retry));
        await tester.pumpAndSettle();
        expect(find.text('جذر أول'), findsOneWidget);
        expect(find.text(_offline), findsNothing);
        expect(api.categoriesCalls, 2);
      },
    );

    testWidgets(
      'does not fetch categories again when navigating back and forth',
      (tester) async {
        final api = _api();
        await pumpApp(tester, api);
        await tapText(tester, 'جذر ثان');
        await goBack(tester);
        expect(api.categoriesCalls, 1);
      },
    );
  });

  group('category hierarchy', () {
    testWidgets('a root with children opens its sub-categories', (
      tester,
    ) async {
      await pumpApp(tester, _api());
      await tapText(tester, 'جذر أول');
      expect(find.text('جميع الأحاديث في هذا التصنيف'), findsOneWidget);
      expect(find.text('فرع ثمانية'), findsOneWidget);
      expect(find.text('فرع تسعة'), findsOneWidget);
      expect(find.text('جذر ثان'), findsNothing);
    });

    testWidgets('"all hadiths" opens the list of the parent itself', (
      tester,
    ) async {
      final api = _api();
      await pumpApp(tester, api);
      await tapText(tester, 'جذر أول');
      await tapText(tester, 'جميع الأحاديث في هذا التصنيف');
      expect(api.pageRequests, ['1:1']);
      expect(find.text('حديث 301'), findsOneWidget);
    });

    testWidgets('a leaf root goes straight to its hadith list', (tester) async {
      final api = _api();
      await pumpApp(tester, api);
      await tapText(tester, 'جذر ثان');
      expect(api.pageRequests, ['2:1']);
      expect(find.text('حديث 101'), findsOneWidget);
    });
  });

  group('hadith list', () {
    testWidgets(
      'renders exactly the loaded items even if the server total is larger',
      (tester) async {
        await pumpApp(tester, _api());
        await tapText(tester, 'جذر ثان'); // total_items 500, 3 items
        expect(tester.takeException(), isNull);
        expect(find.text('حديث 101'), findsOneWidget);
        expect(find.text('حديث 103'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('first-page failure offers retry and then shows the list', (
      tester,
    ) async {
      final api = _api()
        ..pageFailure = const Failure(FailureKind.server, statusCode: 500);
      await pumpApp(tester, api);
      await tapText(tester, 'جذر ثان');
      expect(
        find.text('حدث خطأ في الخادم، حاول مرة أخرى لاحقًا'),
        findsOneWidget,
      );
      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();
      expect(find.text('حديث 101'), findsOneWidget);
    });

    testWidgets('an empty category says so', (tester) async {
      final api = _api();
      api.pages['2:1'] = samplePage(ids: []);
      await pumpApp(tester, api);
      await tapText(tester, 'جذر ثان');
      expect(find.text('لا توجد أحاديث في هذا التصنيف'), findsOneWidget);
    });

    FakeBackend twoPages() {
      final api = _api();
      api.pages['2:1'] = samplePage(
        ids: List.generate(20, (i) => '${1000 + i}'),
        page: 1,
        lastPage: 2,
        totalItems: 25,
      );
      api.pages['2:2'] = samplePage(
        ids: List.generate(5, (i) => '${2000 + i}'),
        page: 2,
        lastPage: 2,
        totalItems: 25,
      );
      return api;
    }

    testWidgets('scrolling to the end loads the next page', (tester) async {
      final api = twoPages();
      await pumpApp(tester, api);
      await tapText(tester, 'جذر ثان');
      expect(api.pageRequests, ['2:1']);

      await tester.drag(find.byType(ListView), const Offset(0, -9000));
      await tester.pumpAndSettle();
      expect(api.pageRequests, ['2:1', '2:2']);
      await tester.drag(find.byType(ListView), const Offset(0, -9000));
      await tester.pumpAndSettle();
      expect(find.text('حديث 2004'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'a failed next page shows an inline retry that keeps the list',
      (tester) async {
        final api = twoPages();
        await pumpApp(tester, api);
        await tapText(tester, 'جذر ثان');

        api.pageFailure = noConnection;
        await tester.drag(find.byType(ListView), const Offset(0, -9000));
        await tester.pumpAndSettle();
        expect(find.text(_offline), findsOneWidget);
        expect(find.text(_retry), findsOneWidget);

        await tester.tap(find.text(_retry));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -9000));
        await tester.pumpAndSettle();
        expect(find.text('حديث 2004'), findsOneWidget);
      },
    );
  });

  group('hadith details', () {
    Future<void> openFirstHadith(WidgetTester tester, FakeBackend api) async {
      await pumpApp(tester, api);
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 101');
    }

    testWidgets(
      'loads the selected hadith by id and shows title, text, grade, attribution and credit',
      (tester) async {
        final api = _api();
        await openFirstHadith(tester, api);
        expect(api.detailsRequests, ['101']);
        expect(find.text('عنوان الحديث'), findsOneWidget);
        expect(
          find.text(arabicDetailsJson['hadeeth']! as String),
          findsOneWidget,
        );
        expect(find.text('صحيح'), findsOneWidget);
        expect(find.text('متفق عليه'), findsOneWidget);
        await tester.scrollUntilVisible(find.text(_credit), 300);
        expect(find.text(_credit), findsOneWidget);
      },
    );

    testWidgets('the grade is shown exactly as given, without added brackets', (
      tester,
    ) async {
      await openFirstHadith(tester, _api());
      expect(find.text('[صحيح]'), findsNothing);
      expect(find.text('صحيح'), findsOneWidget);
    });

    testWidgets('sections start collapsed and open in place', (tester) async {
      await openFirstHadith(tester, _api());
      expect(find.text('شرح الحديث'), findsNothing);
      await tapText(tester, 'الشرح');
      expect(find.text('شرح الحديث'), findsOneWidget);
      await tapText(tester, 'الشرح');
      expect(find.text('شرح الحديث'), findsNothing);
    });

    testWidgets('benefits, word meanings and sources are available', (
      tester,
    ) async {
      await openFirstHadith(tester, _api());
      for (final title in ['الفوائد', 'معاني الكلمات', 'المصادر']) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      await tapText(tester, 'الفوائد');
      expect(find.text('1. فائدة أولى'), findsOneWidget);
      expect(find.text('2. فائدة ثانية'), findsOneWidget);
      await tapText(tester, 'المصادر');
      expect(find.text('صحيح البخاري'), findsOneWidget);
    });

    testWidgets(
      'an English response without reference shows no sources or word meanings',
      (tester) async {
        final api = _api(details: englishDetailsJson);
        await openFirstHadith(tester, api);
        expect(tester.takeException(), isNull);
        expect(find.text('Narrated Abdullah ibn Masud'), findsOneWidget);
        expect(find.text('المصادر'), findsNothing);
        expect(find.text('معاني الكلمات'), findsNothing);
        expect(find.text('not data'), findsNothing);
      },
    );

    testWidgets('failure shows retry and recovers', (tester) async {
      final api = _api()..detailsFailure = const Failure(FailureKind.timeout);
      await openFirstHadith(tester, api);
      expect(find.text('انتهت مهلة الاتصال بالخادم'), findsOneWidget);
      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();
      expect(
        find.text(arabicDetailsJson['hadeeth']! as String),
        findsOneWidget,
      );
    });

    testWidgets('a missing hadith is reported without a retry button', (
      tester,
    ) async {
      final api = _api()
        ..detailsFailure = const Failure(FailureKind.notFound, statusCode: 404);
      await openFirstHadith(tester, api);
      expect(find.text('هذا المحتوى غير متوفر'), findsOneWidget);
      expect(find.text(_retry), findsNothing);
    });

    testWidgets(
      'opening a different hadith after another loads the new one (regression: stale details)',
      (tester) async {
        final api = _api();
        await openFirstHadith(tester, api);
        await goBack(tester);
        await tapText(tester, 'حديث 102');
        expect(api.detailsRequests, ['101', '102']);
      },
    );
  });
}
