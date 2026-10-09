import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  final variants = {
    'light': (AppColors.light, AppPalette.light),
    'dark': (AppColors.dark, AppPalette.dark),
  };

  for (final entry in variants.entries) {
    final (colors, scheme) = entry.value;
    final pairs = <String, (Color, Color)>{
      'success text on the canvas': (colors.success, scheme.surface),
      'success text on the reading surface': (
        colors.success,
        colors.readingSurface,
      ),
      'warning text on the canvas': (colors.warning, scheme.surface),
      'warning text on the reading surface': (
        colors.warning,
        colors.readingSurface,
      ),
      'text on the success container': (
        colors.onSuccessContainer,
        colors.successContainer,
      ),
      'text on the warning container': (
        colors.onWarningContainer,
        colors.warningContainer,
      ),
    };
    for (final pair in pairs.entries) {
      test('${entry.key}: ${pair.key} is at least 4.5:1', () {
        final (fg, bg) = pair.value;
        expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
      });
    }
  }

  test('the reading surface is the card colour the app already uses', () {
    expect(
      AppColors.light.readingSurface,
      AppPalette.light.surfaceContainerLowest,
    );
    expect(
      AppColors.dark.readingSurface,
      AppPalette.dark.surfaceContainerLowest,
    );
  });

  test('each theme carries its own roles', () {
    expect(AppTheme.light().extension<AppColors>(), AppColors.light);
    expect(AppTheme.dark().extension<AppColors>(), AppColors.dark);
  });

  testWidgets('a theme without the roles falls back to the light ones', (
    tester,
  ) async {
    late AppColors found;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            found = AppColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(found, AppColors.light);
  });

  test('colours blend between themes', () {
    final mid = AppColors.light.lerp(AppColors.dark, 0.5);
    expect(
      mid.success,
      Color.lerp(AppColors.light.success, AppColors.dark.success, 0.5),
    );
    expect(AppColors.light.lerp(null, 0.5), AppColors.light);
  });
}
