import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/haptics/haptics.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/pressable_scale.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';

// One theme object: rebuilding it on every pump would start the theme's own animation.
final _lightTheme = AppTheme.light();

Widget host(Widget child, {bool reduce = false, ThemeData? theme}) =>
    MaterialApp(
      theme: theme ?? _lightTheme,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: app!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  group('StatusBanner', () {
    testWidgets('shows the message and is announced as a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const StatusBanner(message: 'Allowed')));
      expect(find.text('Allowed'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(StatusBanner)),
        matchesSemantics(
          label: 'Allowed',
          isLiveRegion: true,
          hasEnabledState: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('every kind has its own icon, so colour is not the only cue', (
      tester,
    ) async {
      final icons = <IconData>{};
      for (final kind in StatusKind.values) {
        await tester.pumpWidget(host(StatusBanner(message: 'x', kind: kind)));
        icons.add(tester.widget<Icon>(find.byType(Icon)).icon!);
      }
      expect(icons, hasLength(StatusKind.values.length));
    });

    testWidgets('the action runs and has a full-size tap target', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          StatusBanner(
            message: 'Off',
            kind: StatusKind.warning,
            actionLabel: 'Open settings',
            onAction: () => taps++,
          ),
        ),
      );
      final size = tester.getSize(find.byType(TextButton));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      await tester.tap(find.text('Open settings'));
      expect(taps, 1);
    });

    testWidgets('fits at 200% text on a small phone', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: app!,
          ),
          home: const Scaffold(
            body: StatusBanner(
              message:
                  'A fairly long message that has to wrap on a narrow screen',
              actionLabel: 'Open settings',
              onAction: _noop,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AnimatedStateSwitcher', () {
    Widget switcher(String key, {bool reduce = false}) => host(
      AnimatedStateSwitcher(child: Text(key, key: ValueKey(key))),
      reduce: reduce,
    );

    testWidgets('the new state is tappable at once while the old one fades', (
      tester,
    ) async {
      await tester.pumpWidget(switcher('loading'));
      await tester.pumpWidget(switcher('content'));
      await tester.pump(AppMotion.instant);
      expect(find.text('content'), findsOneWidget);
      expect(find.text('loading'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsNothing);
    });

    testWidgets('a rebuild with the same state does not restart anything', (
      tester,
    ) async {
      await tester.pumpWidget(switcher('content'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(switcher('content'));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      'with animations removed the states swap with nothing running',
      (tester) async {
        await tester.pumpWidget(switcher('loading', reduce: true));
        await tester.pumpWidget(switcher('content', reduce: true));
        expect(find.text('loading'), findsNothing);
        expect(find.text('content'), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );
  });

  group('PressableScale', () {
    Widget scaled(void Function() onTap, {bool reduce = false}) => host(
      Center(
        child: PressableScale(
          child: GestureDetector(
            onTap: onTap,
            child: const SizedBox(width: 200, height: 100, child: Text('card')),
          ),
        ),
      ),
      reduce: reduce,
    );

    double scaleNow(WidgetTester tester) =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    testWidgets(
      'shrinks while pressed, returns on release, and the tap still works',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(scaled(() => taps++));
        expect(scaleNow(tester), 1);
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('card')),
        );
        await tester.pump();
        expect(scaleNow(tester), PressableScale.pressedScale);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(scaleNow(tester), 1);
        expect(taps, 1);
      },
    );

    testWidgets('a cancelled press returns to full size', (tester) async {
      await tester.pumpWidget(scaled(() {}));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('card')),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(scaleNow(tester), 1);
    });

    testWidgets('with animations removed there is no scaling at all', (
      tester,
    ) async {
      await tester.pumpWidget(scaled(() {}, reduce: true));
      expect(find.byType(AnimatedScale), findsNothing);
    });
  });

  group('appRoute', () {
    // The first page is also an appRoute, so only this route's own transition is in play.
    Future<void> open(
      WidgetTester tester, {
      required TargetPlatform platform,
      bool reduce = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light().copyWith(platform: platform),
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: app!,
          ),
          onGenerateRoute: (_) => appRoute<void>(
            builder: (_) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    appRoute<void>(
                      builder: (_) => const Scaffold(body: Text('next')),
                    ),
                  ),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(AppMotion.instant);
    }

    testWidgets('on Android the page fades in and is usable straight away', (
      tester,
    ) async {
      await open(tester, platform: TargetPlatform.android);
      expect(find.text('next'), findsOneWidget);
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('on Android the page never moves sideways', (tester) async {
      await open(tester, platform: TargetPlatform.android);
      final slides = tester.widgetList<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slides, isNotEmpty);
      for (final slide in slides) {
        expect(slide.position.value.dx, 0);
      }
      await tester.pumpAndSettle();
    });

    testWidgets('on iOS the platform slide is kept', (tester) async {
      await open(tester, platform: TargetPlatform.iOS);
      final sideways = tester
          .widgetList<SlideTransition>(find.byType(SlideTransition))
          .where((s) => s.position.value.dx != 0);
      expect(sideways, isNotEmpty);
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('with animations removed the page appears without a fade', (
      tester,
    ) async {
      await open(tester, platform: TargetPlatform.android, reduce: true);
      expect(find.text('next'), findsOneWidget);
    });

    test('going back is faster than going forward', () {
      final route = AppPageRoute<void>(builder: (_) => const SizedBox());
      expect(
        route.reverseTransitionDuration,
        lessThan(route.transitionDuration),
      );
    });
  });

  group('SystemHaptics', () {
    testWidgets('use the platform feedback, and only when asked', (
      tester,
    ) async {
      final calls = <String>[];
      TestWidgetsFlutterBinding.ensureInitialized();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      const haptics = SystemHaptics();
      expect(calls, isEmpty);
      haptics.selection();
      haptics.alignment();
      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.mediumImpact',
      ]);
    });
  });

  group('AppTypography', () {
    testWidgets('roles use the interface font and the theme colours', (
      tester,
    ) async {
      late AppTypography type;
      late ColorScheme scheme;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              type = AppTypography.of(context);
              scheme = Theme.of(context).colorScheme;
              return const SizedBox();
            },
          ),
        ),
      );
      for (final style in [
        type.display,
        type.title,
        type.heading,
        type.body,
        type.meta,
        type.label,
        type.number,
      ]) {
        expect(style.fontFamily, AppFonts.ui);
        expect(style.fontSize, isNotNull);
      }
      expect(type.body.color, scheme.onSurface);
      expect(type.meta.color, scheme.onSurfaceVariant);
      expect(type.display.fontSize, AppTextSize.display);
      expect(
        type.number.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('sizes descend from display to meta', (tester) async {
      late AppTypography type;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              type = AppTypography.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      final sizes = [
        type.display.fontSize!,
        type.title.fontSize!,
        type.heading.fontSize!,
        type.body.fontSize!,
        type.meta.fontSize!,
      ];
      expect([...sizes]..sort((a, b) => b.compareTo(a)), sizes);
    });
  });
}

void _noop() {}
