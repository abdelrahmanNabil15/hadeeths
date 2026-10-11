import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/features/prayer_times/presentation/countdown_text.dart';
import 'package:mynewapp/features/prayer_times/presentation/widgets/prayer_countdown.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../../support/time_support.dart';

final _ar = lookupAppLocalizations(const Locale('ar'));
final _en = lookupAppLocalizations(const Locale('en'));
const _western = Digits(arabicIndic: false);
const _arabic = Digits(arabicIndic: true);

void main() {
  group('the clock face', () {
    test('rounds up, so zero shows only when the time is reached', () {
      expect(secondsLeft(Duration.zero), 0);
      expect(secondsLeft(const Duration(milliseconds: 1)), 1);
      expect(secondsLeft(const Duration(seconds: 59, milliseconds: 1)), 60);
      expect(secondsLeft(const Duration(seconds: -5)), 0);
    });

    test('hours, minutes and seconds in the user digits', () {
      expect(
        countdownClock(
          const Duration(hours: 1, minutes: 5, seconds: 9),
          _western,
        ),
        '1:05:09',
      );
      expect(countdownClock(const Duration(seconds: 42), _western), '0:00:42');
      expect(countdownClock(Duration.zero, _western), '0:00:00');
      expect(
        countdownClock(const Duration(hours: 12, minutes: 30), _arabic),
        '١٢:٣٠:٠٠',
      );
    });
  });

  test('the next tick comes when the shown second changes', () {
    expect(
      untilNextTick(const Duration(seconds: 5, milliseconds: 300)),
      const Duration(milliseconds: 300),
    );
    expect(
      untilNextTick(const Duration(seconds: 5)),
      const Duration(seconds: 1),
    );
  });

  group('what a screen reader hears', () {
    test('English, to the minute', () {
      String say(Duration d) => countdownSpoken(_en, d, _western);
      expect(say(const Duration(seconds: 30)), 'in less than a minute');
      expect(say(const Duration(minutes: 1)), 'in 1 minute');
      expect(say(const Duration(minutes: 4, seconds: 10)), 'in 5 minutes');
      expect(say(const Duration(hours: 1)), 'in 1 hour');
      expect(
        say(const Duration(hours: 2, minutes: 15)),
        'in 2 hours and 15 minutes',
      );
    });

    test('Arabic uses the dual and the plural after بعد', () {
      String say(Duration d) => countdownSpoken(_ar, d, _arabic);
      expect(say(const Duration(seconds: 10)), 'بعد أقل من دقيقة');
      expect(say(const Duration(minutes: 1)), 'بعد دقيقة');
      expect(say(const Duration(minutes: 2)), 'بعد دقيقتين');
      expect(say(const Duration(minutes: 5)), 'بعد ٥ دقائق');
      expect(say(const Duration(minutes: 25)), 'بعد ٢٥ دقيقة');
      expect(say(const Duration(hours: 2)), 'بعد ساعتين');
      expect(say(const Duration(hours: 3, minutes: 1)), 'بعد ٣ ساعات ودقيقة');
    });

    test('it only changes once a minute', () {
      final a = countdownSpoken(
        _en,
        const Duration(minutes: 9, seconds: 59),
        _western,
      );
      final b = countdownSpoken(
        _en,
        const Duration(minutes: 9, seconds: 1),
        _western,
      );
      expect(a, b);
    });
  });

  group('PrayerCountdown', () {
    late FakeClock clock;
    late int reached;
    late int resumed;
    final start = DateTime.utc(2026, 10, 9, 10);

    Future<void> pump(
      WidgetTester tester, {
      required DateTime nextAt,
      bool tickers = true,
    }) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TickerMode(
          enabled: tickers,
          child: PrayerCountdown(
            nextAt: nextAt,
            clock: clock,
            onReachedZero: () => reached++,
            onResumed: () => resumed++,
            builder: (context, remaining) =>
                Text(countdownClock(remaining, _western)),
          ),
        ),
      ),
    );

    setUp(() {
      clock = FakeClock(start);
      reached = 0;
      resumed = 0;
    });

    /// Moves the clock and the test's timers together.
    Future<void> advance(WidgetTester tester, Duration by) async {
      clock.advance(by);
      await tester.pump(by);
    }

    testWidgets('shows the time left and ticks each second', (tester) async {
      await pump(
        tester,
        nextAt: start.add(const Duration(minutes: 1, seconds: 5)),
      );
      expect(find.text('0:01:05'), findsOneWidget);
      await advance(tester, const Duration(seconds: 1));
      expect(find.text('0:01:04'), findsOneWidget);
      await advance(tester, const Duration(seconds: 3));
      expect(find.text('0:01:01'), findsOneWidget);
    });

    testWidgets('a changed phone clock is picked up on the next tick', (
      tester,
    ) async {
      await pump(tester, nextAt: start.add(const Duration(hours: 1)));
      clock.advance(const Duration(minutes: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:30:00'), findsOneWidget);
    });

    testWidgets(
      'reaching zero calls back once, then a new target starts again',
      (tester) async {
        final first = start.add(const Duration(seconds: 2));
        await pump(tester, nextAt: first);
        await advance(tester, const Duration(seconds: 2));
        await tester.pump();
        expect(find.text('0:00:00'), findsOneWidget);
        expect(reached, 1);
        await advance(tester, const Duration(seconds: 3));
        expect(reached, 1, reason: 'never twice for the same prayer');

        await pump(tester, nextAt: clock.now().add(const Duration(seconds: 1)));
        expect(find.text('0:00:01'), findsOneWidget);
        await advance(tester, const Duration(seconds: 1));
        await tester.pump();
        expect(reached, 2);
      },
    );

    testWidgets('no timer runs while its section is hidden', (tester) async {
      final nextAt = start.add(const Duration(minutes: 10));
      await pump(tester, nextAt: nextAt, tickers: false);
      expect(find.text('0:10:00'), findsOneWidget);
      clock.advance(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('0:10:00'), findsOneWidget, reason: 'not ticking');

      await pump(tester, nextAt: nextAt);
      await tester.pump();
      expect(
        find.text('0:09:55'),
        findsOneWidget,
        reason: 'recomputed at once',
      );
      expect(resumed, 1);
    });

    testWidgets('stops in the background and catches up on return', (
      tester,
    ) async {
      await pump(tester, nextAt: start.add(const Duration(hours: 2)));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock.advance(const Duration(minutes: 45));
      await tester.pump(const Duration(minutes: 45));
      expect(find.text('2:00:00'), findsOneWidget, reason: 'nothing ran');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('1:15:00'), findsOneWidget);
      expect(resumed, 1);
    });

    testWidgets('a page pushed on top stops it', (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: PrayerCountdown(
            nextAt: start.add(const Duration(minutes: 1)),
            clock: clock,
            onResumed: () => resumed++,
            builder: (context, remaining) =>
                Text(countdownClock(remaining, _western)),
          ),
        ),
      );
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        ),
      );
      await tester.pumpAndSettle();
      clock.advance(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('0:00:40'), findsOneWidget);
      expect(resumed, 1);
    });
  });
}
