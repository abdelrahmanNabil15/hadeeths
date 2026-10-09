import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/features/prayer_times/presentation/angle_smoothing.dart';

void main() {
  group('unwrapAngle', () {
    test('keeps a value that is already within half a turn', () {
      expect(unwrapAngle(10, 20), 20);
      expect(unwrapAngle(100, -50), -50);
    });

    test('takes the short way across north', () {
      expect(unwrapAngle(359, 1), 361);
      expect(unwrapAngle(1, 359), -1);
    });

    test('keeps adding turns instead of resetting', () {
      expect(unwrapAngle(361, 3), 363);
      expect(unwrapAngle(-1, 358), -2);
    });

    test('the result is always within 180 degrees of the previous value', () {
      for (var previous = -720.0; previous <= 720; previous += 37) {
        for (var next = -360.0; next <= 360; next += 23) {
          final result = unwrapAngle(previous, next);
          expect((result - previous).abs(), lessThanOrEqualTo(180));
          expect((result - next) % 360, closeTo(0, 1e-9));
        }
      }
    });
  });

  group('SmoothAngle', () {
    Widget host(double? angle, List<double?> seen, {bool reduce = false}) =>
        MaterialApp(
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: app!,
          ),
          home: SmoothAngle(
            angle: angle,
            builder: (context, value) {
              seen.add(value);
              return const SizedBox();
            },
          ),
        );

    testWidgets('starts at the first value with no sweep', (tester) async {
      final seen = <double?>[];
      await tester.pumpWidget(host(40, seen));
      expect(seen.last, 40);
    });

    testWidgets('crossing north never swings the long way round', (
      tester,
    ) async {
      final seen = <double?>[];
      await tester.pumpWidget(host(359, seen));
      await tester.pumpAndSettle();
      seen.clear();
      await tester.pumpWidget(host(1, seen));
      await tester.pump(AppMotion.instant ~/ 2);
      for (final value in seen.whereType<double>()) {
        expect(value, inInclusiveRange(359, 361));
      }
      await tester.pumpAndSettle();
      expect(seen.last, closeTo(361, 1e-6));
    });

    testWidgets(
      'a missing angle shows at once, and the next one does not sweep in',
      (tester) async {
        final seen = <double?>[];
        await tester.pumpWidget(host(200, seen));
        await tester.pumpAndSettle();
        await tester.pumpWidget(host(null, seen));
        expect(seen.last, isNull);
        seen.clear();
        await tester.pumpWidget(host(10, seen));
        expect(seen.last, 10);
      },
    );

    testWidgets('with animations removed it follows the reading directly', (
      tester,
    ) async {
      final seen = <double?>[];
      await tester.pumpWidget(host(10, seen, reduce: true));
      await tester.pumpWidget(host(50, seen, reduce: true));
      expect(seen.last, 50);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
