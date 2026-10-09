import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/features/hadiths/presentation/widgets/reading_surface.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

FakeBackend _backend() => FakeBackend(
  pages: {
    '2:1': samplePage(
      ids: List.generate(8, (i) => '${100 + i}'),
      totalItems: 8,
    ),
  },
);

/// Runs [body] with the system's "remove animations" setting on for the whole app.
Future<void> _withoutAnimations(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await body();
}

void main() {
  group('with animations removed, the hadith flow', () {
    testWidgets('shows each page straight away, with nothing left running', (
      tester,
    ) async {
      await _withoutAnimations(tester, () async {
        await pumpApp(tester, _backend(), locale: 'ar');
        expect(tester.hasRunningAnimations, isFalse);

        await tester.tap(find.text('جذر ثان'));
        await tester.pump();
        await tester.pump();
        expect(find.text('حديث 100'), findsOneWidget);

        await tester.tap(find.text('حديث 100'));
        await tester.pump();
        await tester.pump();
        expect(find.byType(ReadingSurface), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('going back is just as immediate', (tester) async {
      await _withoutAnimations(tester, () async {
        await pumpApp(tester, _backend(), locale: 'ar');
        await tester.tap(find.text('جذر ثان'));
        await tester.pump();
        await tester.pump();
        await goBack(tester);
        expect(find.text('جذر ثان'), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
      });
    });
  });

  testWidgets('a route read with animations on keeps its normal durations', (
    tester,
  ) async {
    late AppPageRoute<void> route;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              route = AppPageRoute<void>(builder: (_) => const SizedBox());
              Navigator.of(context).push(route);
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(route.transitionDuration, const Duration(milliseconds: 280));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
  });

  testWidgets('with animations removed the route durations are zero', (
    tester,
  ) async {
    late AppPageRoute<void> route;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: app!,
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              route = AppPageRoute<void>(builder: (_) => const SizedBox());
              Navigator.of(context).push(route);
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    await tester.pumpAndSettle();
  });

  group('with animations removed, the sections', () {
    testWidgets('switch without fading', (tester) async {
      await _withoutAnimations(tester, () async {
        final fixture = PrayerFixture(now: DateTime.utc(2026, 10, 9, 10));
        await pumpApp(
          tester,
          FakeBackend(),
          locale: 'en',
          features: const FeatureFlags(prayer: true),
          prayer: fixture.services,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Prayer'),
          ),
        );
        await tester.pump();
        // The tab is shown at once: nothing is waiting for a fade to finish.
        expect(find.text('Prayer times'), findsWidgets);
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
      });
    });
  });
}
