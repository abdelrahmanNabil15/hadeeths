import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/app.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/fake_server.dart';
import '../support/test_app.dart';

const _offline = 'لا يوجد اتصال بالإنترنت';

/// Starts the real app (real repositories, data sources and cache) over [server].
Future<SwitchableResponseCache> _launch(
  WidgetTester tester,
  FakeServer server, {
  SwitchableResponseCache? cache,
  AppSettings settings = const AppSettings(),
}) async {
  tester.platformDispatcher.localesTestValue = [const Locale('ar')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final shared = cache ?? SwitchableResponseCache(InMemoryResponseCache());
  final dependencies = await server.dependencies(shared);
  await tester.pumpWidget(
    MyApp(
      key: UniqueKey(),
      dependencies: dependencies,
      initialSettings: settings,
    ),
  );
  await tester.pumpAndSettle();
  return shared;
}

void main() {
  testWidgets(
    'read online, then offline after a restart: the same screens work',
    (tester) async {
      final server = FakeServer();
      final cache = await _launch(tester, server);
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 101');
      expect(find.text('عنوان 101'), findsOneWidget);

      // Lose the connection and restart the app.
      server.online = false;
      final before = server.requests.length;
      await _launch(tester, server, cache: cache);
      expect(
        find.text('جذر ثان'),
        findsOneWidget,
        reason: 'categories from the saved copy',
      );
      await tapText(tester, 'جذر ثان');
      expect(
        find.text('حديث 101'),
        findsOneWidget,
        reason: 'list from the saved copy',
      );
      await tapText(tester, 'حديث 101');
      expect(
        find.text('عنوان 101'),
        findsOneWidget,
        reason: 'hadith from the saved copy',
      );
      expect(find.text(_offline), findsNothing);
      expect(server.requests.length, greaterThanOrEqualTo(before));
    },
  );

  testWidgets(
    'a hadith that was never opened shows the offline error with retry',
    (tester) async {
      final server = FakeServer();
      final cache = await _launch(tester, server);
      await tapText(tester, 'جذر ثان'); // opens the list online, never a hadith
      server.online = false;
      await _launch(tester, server, cache: cache);
      await tapText(tester, 'جذر ثان');
      await tapText(tester, 'حديث 102');
      expect(find.text(_offline), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      server.online = true; // the connection comes back
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(find.text('عنوان 102'), findsOneWidget);
    },
  );

  testWidgets(
    'pull-to-refresh offline keeps the saved list and says why nothing changed',
    (tester) async {
      final server = FakeServer();
      await _launch(tester, server);
      await tapText(tester, 'جذر ثان');
      server.online = false;
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('حديث 101'), findsOneWidget, reason: 'the list stays');
    },
  );

  testWidgets(
    'search is never saved: offline it reports the connection problem',
    (tester) async {
      final server = FakeServer();
      await _launch(tester, server);
      await tapVisible(tester, find.byIcon(Icons.search));
      server.online = false;
      await tester.enterText(find.byType(TextField), 'الحديث');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text(_offline), findsOneWidget);
      expect(server.count('hadeeths/search'), greaterThan(0));
    },
  );

  group('the Settings switch and the clear button', () {
    testWidgets('turning saved copies off clears them and stops saving', (
      tester,
    ) async {
      final server = FakeServer();
      final inner = InMemoryResponseCache();
      final cache = await _launch(
        tester,
        server,
        cache: SwitchableResponseCache(inner),
      );
      await tapText(tester, 'جذر ثان');
      expect(inner.length, greaterThan(0));

      await goBack(tester);
      await tapVisible(tester, find.byIcon(Icons.tune));
      await tester.scrollUntilVisible(find.byType(SwitchListTile), 200);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(cache.enabled, isFalse);
      expect(inner.length, 0, reason: 'existing copies are removed');

      // From now on nothing is saved, so a restart offline has nothing to show.
      await goBack(tester);
      await tapText(tester, 'جذر ثان');
      expect(inner.length, 0);
    });

    testWidgets('the saved choice is applied before anything is fetched', (
      tester,
    ) async {
      final server = FakeServer();
      final inner = InMemoryResponseCache();
      await _launch(
        tester,
        server,
        cache: SwitchableResponseCache(inner),
        settings: const AppSettings(offlineCopies: false),
      );
      await tapText(tester, 'جذر ثان');
      expect(inner.length, 0);
    });

    testWidgets('the clear button removes the saved copies and confirms', (
      tester,
    ) async {
      final server = FakeServer();
      final inner = InMemoryResponseCache();
      await _launch(tester, server, cache: SwitchableResponseCache(inner));
      await tapText(tester, 'جذر ثان');
      expect(inner.length, greaterThan(0));
      await goBack(tester);

      await tapVisible(tester, find.byIcon(Icons.tune));
      await scrollAndTap(tester, find.text('مسح النسخ المحفوظة'));
      expect(inner.length, 0);
      expect(find.text('تم مسح النسخ المحفوظة'), findsOneWidget);
      // The switch itself stays on.
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });
  });
}
