import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';
import 'package:mynewapp/features/categories/presentation/widgets/home_hero.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('shows date, title as a heading, introduction and the slots', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const HomeHero(
          title: 'Hadeeths',
          intro: 'Browse by category.',
          date: 'Friday 9 October 2026',
          action: Icon(Icons.tune),
          bottom: Text('search'),
        ),
      ),
    );
    expect(find.text('Friday 9 October 2026'), findsOneWidget);
    expect(find.text('Browse by category.'), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.text('search'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Hadeeths')),
      isSemantics(label: 'Hadeeths', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('the compact form leaves out the introduction', (tester) async {
    await tester.pumpWidget(
      _host(const HomeHero(title: 'Hadeeths', date: 'today')),
    );
    expect(find.text('Hadeeths'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
  });

  for (final (name, theme, colors) in [
    ('light', AppTheme.light(), AppColors.light),
    ('dark', AppTheme.dark(), AppColors.dark),
  ]) {
    testWidgets('$name: emerald panel, faint pattern, light status bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const HomeHero(title: 'T', date: 'd'),
          theme: theme,
        ),
      );
      expect(
        tester
            .widget<ColoredBox>(
              find
                  .descendant(
                    of: find.byType(HomeHero),
                    matching: find.byType(ColoredBox),
                  )
                  .first,
            )
            .color,
        colors.hero,
      );
      final pattern = tester.widget<GeometricPattern>(
        find.byType(GeometricPattern),
      );
      expect(pattern.color.a, lessThanOrEqualTo(0.08 + 1e-6));
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
    });
  }
}
