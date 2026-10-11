import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/app_icons.dart';
import 'package:mynewapp/core/widgets/app_sheet.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';
import 'package:mynewapp/core/widgets/ornament_divider.dart';
import 'package:mynewapp/core/widgets/state_views.dart';

final _light = AppTheme.light();
final _dark = AppTheme.dark();

Widget _host(Widget child, {ThemeData? theme, TextDirection? direction}) =>
    MaterialApp(
      theme: theme ?? _light,
      home: Directionality(
        textDirection: direction ?? TextDirection.ltr,
        child: Scaffold(body: Center(child: child)),
      ),
    );

Material _cardMaterial(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(AppCard), matching: find.byType(Material)),
);

void main() {
  group('AppCard', () {
    testWidgets('a flat card on the card colour with a hairline edge', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppCard(child: Text('x'))));
      final material = _cardMaterial(tester);
      final shape = material.shape! as RoundedRectangleBorder;
      expect(material.color, AppPalette.light.surfaceContainerLowest);
      expect(shape.side.color, AppPalette.light.outlineVariant);
      expect(shape.side.width, AppBorders.hairline);
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
      expect(
        find.descendant(
          of: find.byType(AppCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('tapping calls back; raised adds the one soft shadow', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AppCard(raised: true, onTap: () => taps++, child: const Text('x')),
        ),
      );
      await tester.tap(find.text('x'));
      expect(taps, 1);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (box.decoration as BoxDecoration).boxShadow,
        AppShadows.soft(AppPalette.light),
      );
    });

    testWidgets('emphasised uses the sage container; a border can be given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AppCard(
            emphasized: true,
            borderColor: Colors.red,
            child: Text('x'),
          ),
        ),
      );
      final material = _cardMaterial(tester);
      expect(material.color, AppPalette.light.primaryContainer);
      expect(
        (material.shape! as RoundedRectangleBorder).side.color,
        Colors.red,
      );
    });

    testWidgets('follows the dark theme', (tester) async {
      await tester.pumpWidget(
        _host(const AppCard(child: Text('x')), theme: _dark),
      );
      expect(
        _cardMaterial(tester).color,
        AppPalette.dark.surfaceContainerLowest,
      );
    });
  });

  group('AppTile', () {
    testWidgets('shows the count in a sage pill and keeps one button label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          AppTile(
            title: 'Faith',
            trailingText: '12',
            semanticLabel: 'Faith, 12 hadiths',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      final pill = tester.widget<DecoratedBox>(
        find
            .ancestor(of: find.text('12'), matching: find.byType(DecoratedBox))
            .first,
      );
      expect((pill.decoration as BoxDecoration).color, AppColors.light.sage);
      expect(
        tester.getSemantics(find.byType(AppTile)),
        isSemantics(label: 'Faith, 12 hadiths', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('the chevron points toward the end in both directions', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 300,
              child: AppTile(title: 'T', onTap: () {}),
            ),
            direction: direction,
          ),
        );
        final chevron = tester.getCenter(find.byIcon(AppIcons.chevron)).dx;
        final title = tester.getCenter(find.text('T')).dx;
        expect(
          direction == TextDirection.ltr ? chevron > title : chevron < title,
          isTrue,
          reason: '$direction',
        );
        expect(AppIcons.chevron.matchTextDirection, isTrue);
      }
    });

    testWidgets('an optional leading icon is drawn in the brand colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(AppTile(title: 'T', leadingIcon: Icons.star, onTap: () {})),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.star)).color,
        AppPalette.light.primary,
      );
    });
  });

  group('decoration is invisible to screen readers', () {
    testWidgets('pattern, ornament and state medallion add no semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 60,
                child: GeometricPattern(color: Colors.black),
              ),
              SizedBox(width: 200, child: OrnamentDivider()),
              StateMedallion(icon: Icons.inbox),
            ],
          ),
        ),
      );
      for (final type in [GeometricPattern, OrnamentDivider, StateMedallion]) {
        final node = tester.getSemantics(find.byType(type).first);
        expect(node.label, isEmpty, reason: '$type');
        expect(node.childrenCount, 0, reason: '$type');
      }
      handle.dispose();
    });

    testWidgets('the pattern is painted into its own layer', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 100,
            height: 60,
            child: GeometricPattern(color: Colors.black),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(GeometricPattern),
          matching: find.byType(RepaintBoundary),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a short ornament keeps its width', (tester) async {
      await tester.pumpWidget(_host(const OrnamentDivider(width: 120)));
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(OrnamentDivider),
                matching: find.byType(Row),
              ),
            )
            .width,
        120,
      );
    });
  });

  group('star geometry', () {
    test('the star stays within its radius and has sixteen corners', () {
      final path = eightPointStar(const Offset(50, 50), 20);
      final bounds = path.getBounds();
      expect(bounds.left, greaterThanOrEqualTo(30 - 1e-9));
      expect(bounds.right, lessThanOrEqualTo(70 + 1e-9));
      expect(bounds.top, closeTo(30, 1e-9));
      expect(bounds.bottom, closeTo(70, 1e-9));
      final metrics = path.computeMetrics().toList();
      expect(metrics, hasLength(1));
      expect(metrics.single.isClosed, isTrue);
    });

    test('the lattice repaints only when its look changes', () {
      const a = StarLatticePainter(
        color: Colors.black,
        tileSize: 56,
        strokeWidth: 1,
      );
      expect(
        a.shouldRepaint(
          const StarLatticePainter(
            color: Colors.black,
            tileSize: 56,
            strokeWidth: 1,
          ),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          const StarLatticePainter(
            color: Colors.white,
            tileSize: 56,
            strokeWidth: 1,
          ),
        ),
        isTrue,
      );
    });
  });

  group('options sheet', () {
    Future<void> open(
      WidgetTester tester,
      void Function(String?) onResult,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(
                await showOptionsSheet<String>(
                  context,
                  title: 'Share',
                  options: const [
                    SheetOption(
                      value: 'a',
                      label: 'As text',
                      icon: Icons.notes,
                    ),
                    SheetOption(
                      value: 'b',
                      label: 'As image',
                      icon: Icons.image_outlined,
                    ),
                  ],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('returns the chosen value; rows are at least 56 high', (
      tester,
    ) async {
      String? result = 'unset';
      await open(tester, (value) => result = value);
      expect(
        tester.getSize(find.widgetWithText(ListTile, 'As image')).height,
        greaterThanOrEqualTo(AppSizes.minTileHeight),
      );
      await tester.tap(find.text('As image'));
      await tester.pumpAndSettle();
      expect(result, 'b');
    });

    testWidgets('the title is a heading; dismissing returns nothing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? result = 'unset';
      await open(tester, (value) => result = value);
      expect(
        tester.getSemantics(find.text('Share')),
        isSemantics(label: 'Share', isHeader: true),
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(result, isNull);
      handle.dispose();
    });
  });
}
