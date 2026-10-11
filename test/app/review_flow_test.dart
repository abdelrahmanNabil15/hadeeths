import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/app/review_coordinator.dart';
import 'package:mynewapp/features/app_review/domain/review_state.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_counter.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_repository.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/review_fakes.dart';
import '../support/test_app.dart';
import '../support/time_support.dart';

const _all = FeatureFlags(quran: true, inAppReview: true);
final _start = DateTime.utc(2026, 10, 1, 9);

FakeBackend _backend() => FakeBackend(
  pages: {
    '2:1': samplePage(
      ids: List.generate(8, (i) => '${100 + i}'),
      totalItems: 8,
    ),
  },
);

/// 14 actions so far, nothing waiting: one more qualifying action makes a request possible.
ReviewState _almost() => ReviewState(
  firstSeen: _start,
  usageDays: const ['2026-10-01', '2026-10-04', '2026-10-08', '2026-10-10'],
  actions: 14,
);

class _Review {
  _Review([ReviewState? state, bool automatic = true])
    : store = InMemoryReviewStore(state ?? _almost()),
      gateway = FakeReviewGateway(),
      clock = FakeClock(_start.add(const Duration(days: 10))) {
    coordinator = ReviewCoordinator(
      store: store,
      gateway: gateway,
      versions: FakeAppVersion(),
      clock: clock,
      automatic: automatic,
    );
  }

  final InMemoryReviewStore store;
  final FakeReviewGateway gateway;
  final FakeClock clock;
  late final ReviewCoordinator coordinator;
}

class _Counter implements TasbeehRepository {
  _Counter(this.stored);

  TasbeehCounter stored;

  @override
  Future<TasbeehCounter> load() async => stored;

  @override
  Future<void> save(TasbeehCounter counter) async => stored = counter;
}

Future<void> _openMore(WidgetTester tester, {String locale = 'en'}) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(locale == 'ar' ? 'المزيد' : 'More'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openHadith(WidgetTester tester) async {
  await tapText(tester, 'جذر ثان');
  await tapText(tester, 'حديث 100');
}

void main() {
  group('the Rate entry', () {
    testWidgets('More offers it in English, and it opens the store page', (
      tester,
    ) async {
      final r = _Review();
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        features: _all,
        review: r.coordinator,
      );
      await _openMore(tester);
      expect(find.text('Rate Sakina'), findsOneWidget);
      await tester.tap(find.text('Rate Sakina'));
      await tester.pumpAndSettle();
      expect(r.gateway.storeOpens, 1);
      expect(r.gateway.requests, 0);
    });

    testWidgets('and in Arabic', (tester) async {
      final r = _Review();
      await pumpApp(
        tester,
        _backend(),
        locale: 'ar',
        features: _all,
        review: r.coordinator,
      );
      await _openMore(tester, locale: 'ar');
      expect(find.text('قيّم سكينة'), findsOneWidget);
    });

    testWidgets('it works even when automatic requests are off', (
      tester,
    ) async {
      final r = _Review(null, false);
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        features: _all,
        review: r.coordinator,
      );
      await _openMore(tester);
      await tester.tap(find.text('Rate Sakina'));
      await tester.pumpAndSettle();
      expect(r.gateway.storeOpens, 1);
    });

    testWidgets('About offers it too', (tester) async {
      final r = _Review();
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        features: _all,
        review: r.coordinator,
      );
      await _openMore(tester);
      await tapText(tester, 'Sources and rights');
      await tester.scrollUntilVisible(find.text('Rate Sakina'), 300);
      await tester.tap(find.text('Rate Sakina'));
      await tester.pumpAndSettle();
      expect(r.gateway.storeOpens, 1);
    });

    testWidgets('it is absent while the feature is off', (tester) async {
      final r = _Review();
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        features: const FeatureFlags(quran: true),
        review: r.coordinator,
      );
      await _openMore(tester);
      expect(find.text('Rate Sakina'), findsNothing);
    });

    testWidgets('and where there is no store page to open', (tester) async {
      final r = _Review();
      r.gateway.canOpen = false;
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        features: _all,
        review: r.coordinator,
      );
      await _openMore(tester);
      expect(find.text('Rate Sakina'), findsNothing);
    });

    testWidgets('and without any review set up (the released app)', (
      tester,
    ) async {
      await pumpApp(tester, _backend(), locale: 'en', features: _all);
      await _openMore(tester);
      expect(find.text('Rate Sakina'), findsNothing);
    });

    testWidgets('a long Arabic label fits at 200% text on a small phone', (
      tester,
    ) async {
      final r = _Review();
      useSmallPhone(tester, textScale: 2);
      await pumpApp(
        tester,
        _backend(),
        locale: 'ar',
        features: _all,
        review: r.coordinator,
      );
      await _openMore(tester, locale: 'ar');
      expect(find.text('قيّم سكينة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('asking after a completed action, back on the home screen', () {
    testWidgets('reading a hadith and coming back asks the system once', (
      tester,
    ) async {
      final r = _Review();
      await pumpApp(tester, _backend(), features: _all, review: r.coordinator);
      await _openHadith(tester);
      // Reading counts, but nothing is shown while the hadith is open.
      expect((await r.coordinator.state).actions, 15);
      expect(r.gateway.requests, 0);

      await goBack(tester); // to the list
      expect(r.gateway.requests, 0);
      await goBack(tester); // to the home screen
      await tester.pumpAndSettle();
      expect(r.gateway.requests, 1);
      expect(r.store.saved!.requests.single.version, '1.1.0+2');

      // Another hadith and another return: the same version does not ask again.
      await _openHadith(tester);
      await goBack(tester);
      await goBack(tester);
      await tester.pumpAndSettle();
      expect(r.gateway.requests, 1);
    });

    testWidgets('opening the same hadith again the same day counts once', (
      tester,
    ) async {
      final r = _Review(_almost().copyWith(actions: 0));
      await pumpApp(tester, _backend(), features: _all, review: r.coordinator);
      await _openHadith(tester);
      await goBack(tester);
      await tapText(tester, 'حديث 100');
      expect((await r.coordinator.state).actions, 1);
    });

    testWidgets('going back without having read anything asks nothing', (
      tester,
    ) async {
      final r = _Review(_almost().copyWith(actions: 40));
      await pumpApp(tester, _backend(), features: _all, review: r.coordinator);
      await tapText(tester, 'جذر ثان');
      await goBack(tester);
      await tester.pumpAndSettle();
      expect(r.gateway.requests, 0);
    });

    testWidgets('automatic requests off: reading never asks', (tester) async {
      final r = _Review(null, false);
      await pumpApp(tester, _backend(), features: _all, review: r.coordinator);
      await _openHadith(tester);
      await goBack(tester);
      await goBack(tester);
      await tester.pumpAndSettle();
      expect(r.gateway.requests, 0);
    });

    testWidgets('the feature off: reading counts nothing and asks nothing', (
      tester,
    ) async {
      final r = _Review();
      await pumpApp(
        tester,
        _backend(),
        features: const FeatureFlags(quran: true),
        review: r.coordinator,
      );
      await _openHadith(tester);
      await goBack(tester);
      await goBack(tester);
      await tester.pumpAndSettle();
      expect((await r.coordinator.state).actions, 14);
      expect(r.gateway.requests, 0);
    });

    testWidgets('finishing a tasbeeh round, then selecting Hadiths, asks', (
      tester,
    ) async {
      final r = _Review();
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        features: _all,
        review: r.coordinator,
        tasbeeh: _Counter(const TasbeehCounter(count: 32, target: 33)),
      );
      await _openMore(tester);
      await tapText(tester, 'Tasbeeh counter');
      final center = tester.getCenter(find.byType(FittedBox).first);
      final gesture = await tester.startGesture(center);
      await gesture.up();
      await tester.pumpAndSettle();
      expect((await r.coordinator.state).actions, 15);
      // Still counting: nothing is shown.
      expect(r.gateway.requests, 0);

      await goBack(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Hadiths'),
        ),
      );
      await tester.pumpAndSettle();
      expect(r.gateway.requests, 1);
    });

    testWidgets('selecting Hadiths with nothing completed asks nothing', (
      tester,
    ) async {
      final r = _Review(_almost().copyWith(actions: 40));
      await pumpApp(
        tester,
        _backend(),
        locale: 'en',
        features: _all,
        review: r.coordinator,
      );
      await _openMore(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Hadiths'),
        ),
      );
      await tester.pumpAndSettle();
      expect(r.gateway.requests, 0);
    });
  });
}
