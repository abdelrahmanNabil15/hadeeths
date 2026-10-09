import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/shell/app_shell.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/pressable_scale.dart';

final _theme = AppTheme.light();

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
  theme: _theme,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
    child: app!,
  ),
  home: Scaffold(body: child),
);

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(TabFade),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

void main() {
  group('TabFade', () {
    Widget fade(bool active, {bool reduce = false}) => _host(
      TabFade(active: active, child: const Text('tab')),
      reduce: reduce,
    );

    testWidgets('a section that was never switched away from is fully shown', (
      tester,
    ) async {
      await tester.pumpWidget(fade(true));
      expect(_opacity(tester), 1);
    });

    testWidgets(
      'fades in when selected, and is readable and tappable at once',
      (tester) async {
        await tester.pumpWidget(fade(false));
        await tester.pumpWidget(fade(true));
        await tester.pump(AppMotion.instant);
        expect(find.text('tab'), findsOneWidget);
        expect(_opacity(tester), lessThan(1));
        expect(_opacity(tester), greaterThan(0));
        await tester.pumpAndSettle();
        expect(_opacity(tester), 1);
      },
    );

    testWidgets('being deselected does not start an animation', (tester) async {
      await tester.pumpWidget(fade(true));
      await tester.pumpWidget(fade(false));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('with animations removed it just appears', (tester) async {
      await tester.pumpWidget(fade(false, reduce: true));
      await tester.pumpWidget(fade(true, reduce: true));
      expect(_opacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('AppTile press feedback', () {
    Widget tile({required bool feedback}) =>
        _host(AppTile(title: 'Row', onTap: () {}, pressFeedback: feedback));

    testWidgets('is off unless asked for, so existing screens look as before', (
      tester,
    ) async {
      await tester.pumpWidget(tile(feedback: false));
      expect(find.byType(PressableScale), findsNothing);
    });

    testWidgets('can be turned on', (tester) async {
      await tester.pumpWidget(tile(feedback: true));
      expect(find.byType(PressableScale), findsOneWidget);
    });

    testWidgets('the tap still works with feedback on', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AppTile(title: 'Row', onTap: () => taps++, pressFeedback: true)),
      );
      await tester.tap(find.text('Row'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });
}
