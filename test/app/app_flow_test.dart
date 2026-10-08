import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/app.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/features/categories/presentation/widgets/category_grid.dart';
import 'package:mynewapp/features/hadiths/presentation/share_text.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';

const _retry = 'إعادة المحاولة';
const _offline = 'لا يوجد اتصال بالإنترنت';

FakeBackend _api({Map<String, dynamic>? details}) => FakeBackend(
  details: details == null ? null : sampleDetails(details),
  pages: {
    '2:1': samplePage(ids: ['101', '102', '103'], totalItems: 500),
    '8:1': samplePage(ids: ['201'], page: 1, lastPage: 1),
    '1:1': samplePage(ids: ['301', '302'], page: 1, lastPage: 1),
  },
);

Future<void> _pump(WidgetTester tester, FakeBackend api) async {
  await tester.pumpWidget(
    MyApp(
      dependencies: AppDependencies(categories: api, hadiths: api),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('home', () {
    testWidgets('shows only root categories, not sub-categories', (
      tester,
    ) async {
      await _pump(tester, _api());
      expect(find.text('جذر أول'), findsOneWidget);
      expect(find.text('جذر ثان'), findsOneWidget);
      expect(find.text('فرع ثمانية'), findsNothing);
      expect(find.text('حفيد'), findsNothing);
    });

    testWidgets(
      'the backdrop fills the screen even when there are few categories',
      (tester) async {
        await _pump(tester, _api()); // 2 roots: far less than a screenful
        final body = tester.getSize(find.byType(CategoryBackdrop));
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(body.width, screen.width);
        expect(body.height, screen.height - kToolbarHeight);
      },
    );

    testWidgets('shows a spinner while loading, then the content', (
      tester,
    ) async {
      final api = _api()..gate = Completer<void>();
      await tester.pumpWidget(
        MyApp(
          dependencies: AppDependencies(categories: api, hadiths: api),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      api.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('جذر أول'), findsOneWidget);
    });

    testWidgets(
      'a failure shows a message and retry, never an endless spinner',
      (tester) async {
        final api = _api()..categoriesFailure = noConnection;
        await _pump(tester, api);
        expect(find.text(_offline), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

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
        await _pump(tester, api);
        await tester.tap(find.text('جذر ثان'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(api.categoriesCalls, 1);
      },
    );
  });

  group('category hierarchy', () {
    testWidgets('a root with children opens its sub-categories', (
      tester,
    ) async {
      await _pump(tester, _api());
      await tester.tap(find.text('جذر أول'));
      await tester.pumpAndSettle();
      expect(find.text('جميع الأحاديث في هذا التصنيف'), findsOneWidget);
      expect(find.text('فرع ثمانية'), findsOneWidget);
      expect(find.text('فرع تسعة'), findsOneWidget);
      expect(find.text('جذر ثان'), findsNothing);
    });

    testWidgets('"all hadiths" opens the list of the parent itself', (
      tester,
    ) async {
      final api = _api();
      await _pump(tester, api);
      await tester.tap(find.text('جذر أول'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('جميع الأحاديث في هذا التصنيف'));
      await tester.pumpAndSettle();
      expect(api.pageRequests, ['1:1']);
      expect(find.text('حديث 301'), findsOneWidget);
    });

    testWidgets('a leaf root goes straight to its hadith list', (tester) async {
      final api = _api();
      await _pump(tester, api);
      await tester.tap(find.text('جذر ثان'));
      await tester.pumpAndSettle();
      expect(api.pageRequests, ['2:1']);
      expect(find.text('حديث 101'), findsOneWidget);
    });
  });

  group('hadith list', () {
    testWidgets(
      'renders exactly the loaded items even if the server total is larger',
      (tester) async {
        await _pump(tester, _api());
        await tester.tap(find.text('جذر ثان')); // total_items 500, 3 items
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Card), findsNWidgets(3));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('first-page failure offers retry and then shows the list', (
      tester,
    ) async {
      final api = _api()
        ..pageFailure = const Failure(FailureKind.server, statusCode: 500);
      await _pump(tester, api);
      await tester.tap(find.text('جذر ثان'));
      await tester.pumpAndSettle();
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
      await _pump(tester, api);
      await tester.tap(find.text('جذر ثان'));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد أحاديث في هذا التصنيف'), findsOneWidget);
    });

    testWidgets('scrolling to the end loads the next page', (tester) async {
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
      await _pump(tester, api);
      await tester.tap(find.text('جذر ثان'));
      await tester.pumpAndSettle();
      expect(api.pageRequests, ['2:1']);

      await tester.drag(find.byType(ListView), const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(api.pageRequests, ['2:1', '2:2']);
      await tester.drag(find.byType(ListView), const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(find.text('حديث 2004'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'a failed next page shows an inline retry that keeps the list',
      (tester) async {
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
        await _pump(tester, api);
        await tester.tap(find.text('جذر ثان'));
        await tester.pumpAndSettle();

        api.pageFailure = noConnection;
        await tester.drag(find.byType(ListView), const Offset(0, -6000));
        await tester.pumpAndSettle();
        expect(find.text(_offline), findsOneWidget);
        expect(find.text(_retry), findsOneWidget);

        await tester.tap(find.text(_retry));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -6000));
        await tester.pumpAndSettle();
        expect(find.text('حديث 2004'), findsOneWidget);
      },
    );
  });

  group('hadith details', () {
    Future<void> openFirstHadith(WidgetTester tester, FakeBackend api) async {
      await _pump(tester, api);
      await tester.tap(find.text('جذر ثان'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حديث 101'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'loads the selected hadith by id and shows text, grade, attribution, credit',
      (tester) async {
        final api = _api();
        await openFirstHadith(tester, api);
        expect(api.detailsRequests, ['101']);
        expect(
          find.text(arabicDetailsJson['hadeeth']! as String),
          findsOneWidget,
        );
        expect(find.text('[صحيح]'), findsOneWidget);
        expect(find.text('[متفق عليه]'), findsOneWidget);
        expect(find.text(hadeethEncCredit), findsOneWidget);
        expect(find.text('الشرح'), findsOneWidget);
        expect(find.text('المصادر'), findsOneWidget);
      },
    );

    testWidgets(
      'an English response without reference does not crash and omits that row',
      (tester) async {
        final api = _api(details: englishDetailsJson);
        await openFirstHadith(tester, api);
        expect(tester.takeException(), isNull);
        expect(find.text('Narrated Abdullah ibn Masud'), findsOneWidget);
        expect(find.text('المصادر'), findsNothing);
        expect(find.text('معاني الكلمات:'), findsNothing);
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
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('حديث 102'));
        await tester.pumpAndSettle();
        expect(api.detailsRequests, ['101', '102']);
      },
    );
  });
}
