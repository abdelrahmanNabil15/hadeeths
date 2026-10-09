import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

void main() {
  group('motion tokens', () {
    test('are ordered and none is longer than the emphasis limit', () {
      final ordered = [
        AppMotion.instant,
        AppMotion.short,
        AppMotion.medium,
        AppMotion.page,
        AppMotion.emphasis,
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(ordered[i], greaterThan(ordered[i - 1]));
      }
      expect(
        AppMotion.emphasis,
        lessThanOrEqualTo(Duration(milliseconds: 400)),
      );
    });

    test('going back is never slower than going forward', () {
      expect(AppMotion.pageReverse, lessThanOrEqualTo(AppMotion.page));
    });

    test('the values that existed before are unchanged', () {
      expect(AppMotion.short, const Duration(milliseconds: 150));
      expect(AppMotion.medium, const Duration(milliseconds: 250));
    });
  });

  group('reduced motion', () {
    Future<(bool, Duration)> read(WidgetTester tester, bool disabled) async {
      late bool reduce;
      late Duration duration;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disabled),
          child: Builder(
            builder: (context) {
              reduce = context.reduceMotion;
              duration = context.motion(AppMotion.medium);
              return const SizedBox();
            },
          ),
        ),
      );
      return (reduce, duration);
    }

    testWidgets('durations are kept normally', (tester) async {
      expect(await read(tester, false), (false, AppMotion.medium));
    });

    testWidgets('durations become zero when animations are removed', (
      tester,
    ) async {
      expect(await read(tester, true), (true, Duration.zero));
    });
  });

  group('no animation timing outside the tokens', () {
    // Screens and shared widgets take their durations from AppMotion. State classes and the
    // network layer use their own timeouts and are not animations, so they are not scanned.
    final scanned = <String>[
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          if (RegExp(
            r'lib[\\/](core[\\/]widgets|features[\\/][^\\/]+[\\/]presentation[\\/](pages|widgets)|app[\\/]shell)[\\/]',
          ).hasMatch(entity.path))
            entity.path,
    ];

    test('the scan covers the screens and shared widgets', () {
      expect(scanned.length, greaterThan(20));
    });

    test('they contain no Duration literal', () {
      final offenders = [
        for (final path in scanned)
          if (File(path).readAsStringSync().contains(
            RegExp(r'Duration\(\s*(milliseconds|seconds|microseconds)'),
          ))
            path,
      ];
      expect(offenders, isEmpty);
    });
  });
}
