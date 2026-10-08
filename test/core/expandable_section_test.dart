import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/widgets/expandable_section.dart';

Widget _host({VoidCallback? onShare}) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    // A Column gives the section its natural height (a bare Scaffold body would stretch it).
    body: Column(
      children: [
        ExpandableSection(
          title: 'Title',
          shareTooltip: 'Share',
          onShare: onShare,
          child: const Text('Body text'),
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('starts collapsed and toggles on tap', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('Body text'), findsNothing);
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    expect(find.text('Body text'), findsOneWidget);
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    expect(find.text('Body text'), findsNothing);
  });

  testWidgets('can start expanded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: ExpandableSection(
            title: 'Title',
            initiallyExpanded: true,
            child: Text('Body text'),
          ),
        ),
      ),
    );
    expect(find.text('Body text'), findsOneWidget);
  });

  testWidgets('animates by default', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Title'));
    await tester.pump(); // first frame of the animation
    final size = tester.getSize(find.byType(ExpandableSection));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(ExpandableSection)).height,
      greaterThan(size.height),
    );
  });

  testWidgets(
    'with reduced motion the section is fully open on the very next frame',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(_host());
      await tester.tap(find.text('Title'));
      await tester.pump();
      final openHeight = tester.getSize(find.byType(ExpandableSection)).height;
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(ExpandableSection)).height, openHeight);
    },
  );

  testWidgets('the share button appears only while open', (tester) async {
    var shared = 0;
    await tester.pumpWidget(_host(onShare: () => shared++));
    expect(find.byTooltip('Share'), findsNothing);
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    expect(shared, 1);
  });

  group('chevron direction', () {
    Widget hostIn(TextDirection direction) => MaterialApp(
      theme: AppTheme.light(),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Column(
            children: [
              ExpandableSection(title: 'Title', child: const Text('Body')),
            ],
          ),
        ),
      ),
    );

    double turns(WidgetTester tester) =>
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns;

    testWidgets(
      'left-to-right: quarter turn clockwise when open (right arrow to down)',
      (tester) async {
        await tester.pumpWidget(hostIn(TextDirection.ltr));
        expect(turns(tester), 0);
        await tester.tap(find.text('Title'));
        await tester.pumpAndSettle();
        expect(turns(tester), 0.25);
      },
    );

    testWidgets(
      'right-to-left: the mirrored arrow turns the other way to point down',
      (tester) async {
        await tester.pumpWidget(hostIn(TextDirection.rtl));
        await tester.tap(find.text('Title'));
        await tester.pumpAndSettle();
        expect(turns(tester), -0.25);
      },
    );
  });
}
