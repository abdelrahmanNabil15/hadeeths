import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_counter.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_repository.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

class _Store implements TasbeehRepository {
  _Store([this.stored = const TasbeehCounter()]);

  TasbeehCounter stored;
  Object? failSave;

  @override
  Future<TasbeehCounter> load() async => stored;

  @override
  Future<void> save(TasbeehCounter counter) async {
    if (failSave != null) throw failSave!;
    stored = counter;
  }
}

Future<_Store> _open(
  WidgetTester tester, {
  String locale = 'en',
  _Store? store,
  bool withStore = true,
  bool tall = true,
}) async {
  if (tall) {
    tester.view.physicalSize = const Size(700, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  final repository = store ?? _Store();
  final fixture = PrayerFixture(now: DateTime.utc(2026, 10, 9, 10));
  await pumpApp(
    tester,
    FakeBackend(),
    locale: locale,
    features: const FeatureFlags(prayer: true),
    prayer: fixture.services,
    tasbeeh: withStore ? repository : null,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(locale == 'ar' ? 'المزيد' : 'More'),
    ),
  );
  await tester.pumpAndSettle();
  if (withStore) {
    await tester.tap(
      find.text(locale == 'ar' ? 'عدّاد التسبيح' : 'Tasbeeh counter'),
    );
    await tester.pumpAndSettle();
  }
  return repository;
}

Finder get _circle => find.bySemanticsLabel(RegExp(r'^(Count|العدد) '));

Future<void> _tapCircle(WidgetTester tester, [int times = 1]) async {
  final center = tester.getCenter(find.byType(FittedBox).first);
  for (var i = 0; i < times; i++) {
    final gesture = await tester.startGesture(center);
    await gesture.up();
    await tester.pump();
  }
}

void main() {
  testWidgets('More offers the counter, and it opens at zero', (tester) async {
    await _open(tester);
    expect(find.text('Tasbeeh counter'), findsWidgets);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('No target'), findsOneWidget);
  });

  testWidgets('without storage the counter is not offered', (tester) async {
    await _open(tester, withStore: false);
    expect(find.text('Tasbeeh counter'), findsNothing);
  });

  testWidgets('each tap counts, and the count is saved', (tester) async {
    final store = await _open(tester);
    await _tapCircle(tester, 3);
    expect(find.text('3'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(store.stored.count, 3);
  });

  testWidgets('sixty quick taps in a row lose nothing', (tester) async {
    final store = await _open(tester);
    await _tapCircle(tester, 60);
    expect(find.text('60'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(store.stored.count, 60);
  });

  testWidgets('the count comes back after the app is reopened', (tester) async {
    final store = await _open(tester);
    await _tapCircle(tester, 7);
    await tester.pumpAndSettle();
    await _open(tester, store: store);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('a target shows the round, and says so when it is reached', (
    tester,
  ) async {
    final store = _Store(const TasbeehCounter(count: 31));
    await _open(tester, store: store);
    await tester.tap(find.text('33'));
    await tester.pumpAndSettle();
    expect(store.stored.target, 33);
    expect(find.text('Rounds completed: 0'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await _tapCircle(tester, 2);
    expect(find.text('Target reached'), findsOneWidget);
    // The chosen target already shows one check mark; reaching it adds a second.
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    await _tapCircle(tester);
    expect(find.text('Rounds completed: 1'), findsOneWidget);
  });

  testWidgets('undo takes one off; it is unavailable at zero', (tester) async {
    final store = await _open(tester);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Undo last'),
          )
          .onPressed,
      isNull,
    );
    await _tapCircle(tester, 3);
    await tester.tap(find.text('Undo last'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(store.stored.count, 2);
  });

  testWidgets('reset asks first and keeps the target', (tester) async {
    final store = _Store(const TasbeehCounter(count: 12, target: 99));
    await _open(tester, store: store);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Reset the counter?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(store.stored.count, 12);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(store.stored, const TasbeehCounter(target: 99));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('a failed save is explained and counting goes on', (
    tester,
  ) async {
    final store = _Store()..failSave = StateError('disk');
    await _open(tester, store: store);
    await _tapCircle(tester, 2);
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be saved'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Arabic: Arabic-Indic digits, right to left', (tester) async {
    await _open(tester, locale: 'ar');
    await _tapCircle(tester, 12);
    expect(find.text('١٢'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('١٢'))),
      TextDirection.rtl,
    );
  });

  group('accessibility', () {
    testWidgets('a screen reader hears the count and can tap to count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final store = await _open(tester);
      expect(_circle, findsOneWidget);
      expect(tester.getSemantics(_circle).label, contains('Count 0'));
      tester.semantics.tap(find.semantics.byLabel(RegExp('Count 0')));
      await tester.pumpAndSettle();
      expect(store.stored.count, 1);
      expect(find.bySemanticsLabel(RegExp('Count 1')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('fits at 200% text on a small phone, even with a large count', (
      tester,
    ) async {
      useSmallPhone(tester, textScale: 2);
      await _open(
        tester,
        store: _Store(const TasbeehCounter(count: 999999, target: 100)),
        tall: false,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap targets, labels and contrast hold', (tester) async {
      final handle = tester.ensureSemantics();
      useSmallPhone(tester);
      await _open(tester, tall: false);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('privacy and content', () {
    final files = [
      for (final e in Directory(
        'lib/features/tasbeeh',
      ).listSync(recursive: true))
        if (e is File && e.path.endsWith('.dart')) e,
    ];

    test('the counter code has no network, location or sharing access', () {
      expect(files.length, greaterThan(4));
      for (final file in files) {
        final text = file.readAsStringSync();
        for (final forbidden in [
          'package:dio',
          'package:http',
          'dart:io',
          'HttpClient',
          'package:share_plus',
          'package:geolocator',
        ]) {
          expect(text, isNot(contains(forbidden)), reason: file.path);
        }
      }
    });

    test('the counter carries no phrases of its own', () {
      for (final file in files) {
        expect(
          file.readAsStringSync(),
          isNot(matches(RegExp(r'[؀-ۿ]'))),
          reason: '${file.path} contains Arabic text',
        );
      }
    });
  });
}
