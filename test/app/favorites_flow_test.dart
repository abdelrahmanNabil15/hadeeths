import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/favorites/domain/favorites_repository.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

class _Favorites implements FavoritesRepository {
  final List<String> ids = [];

  @override
  Future<bool> contains(String hadithId) async => ids.contains(hadithId);

  @override
  Future<void> setFavorite(String hadithId, {required bool favorite}) async {
    ids.remove(hadithId);
    if (favorite) ids.insert(0, hadithId);
  }

  @override
  Future<List<String>> all() async => [...ids];

  @override
  Future<void> clear() async => ids.clear();
}

FakeBackend _backend() => FakeBackend(
  pages: {
    '2:1': samplePage(
      ids: List.generate(8, (i) => '${100 + i}'),
      totalItems: 8,
    ),
  },
);

const _on = FeatureFlags(prayer: true, favorites: true);

Future<_Favorites> _start(
  WidgetTester tester, {
  FeatureFlags features = _on,
  _Favorites? favorites,
  String locale = 'ar',
  FakeBackend? backend,
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final store = favorites ?? _Favorites();
  await pumpApp(
    tester,
    backend ?? _backend(),
    locale: locale,
    features: features,
    favorites: store,
  );
  return store;
}

Future<void> _openHadith(WidgetTester tester) async {
  await tapText(tester, 'جذر ثان');
  await tapText(tester, 'حديث 100');
}

Future<void> _openFavorites(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('المزيد'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('المفضلة'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the released app (sections off) shows no bookmark', (
    tester,
  ) async {
    await _start(tester, features: const FeatureFlags());
    await _openHadith(tester);
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
    expect(find.byIcon(Icons.bookmark), findsNothing);
  });

  testWidgets('favourites switched off keep the bookmark hidden too', (
    tester,
  ) async {
    await _start(tester, features: const FeatureFlags(prayer: true));
    await _openHadith(tester);
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
  });

  testWidgets('the bookmark keeps a hadith, and tapping again removes it', (
    tester,
  ) async {
    final store = await _start(tester);
    await _openHadith(tester);
    expect(find.byTooltip('إضافة إلى المفضلة'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();
    expect(store.ids, ['100']);
    expect(find.byTooltip('إزالة من المفضلة'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(store.ids, isEmpty);
  });

  testWidgets('a kept hadith is shown as kept when opened again', (
    tester,
  ) async {
    final store = _Favorites()..ids.add('100');
    await _start(tester, favorites: store);
    await _openHadith(tester);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('More lists the favourites by title and opens them', (
    tester,
  ) async {
    final store = _Favorites()..ids.addAll(['100', '101']);
    await _start(tester, favorites: store);
    await _openFavorites(tester);
    // The fake server gives every id the same title.
    expect(find.text('عنوان الحديث'), findsNWidgets(2));
    await tester.tap(find.text('عنوان الحديث').last);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('removing a favourite on its page updates the list', (
    tester,
  ) async {
    final store = _Favorites()..ids.add('100');
    await _start(tester, favorites: store);
    await _openFavorites(tester);
    await tester.tap(find.text('عنوان الحديث'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    await goBack(tester);
    expect(find.textContaining('لا توجد أحاديث في المفضلة'), findsOneWidget);
  });

  testWidgets('an empty list explains how to add', (tester) async {
    await _start(tester);
    await _openFavorites(tester);
    expect(find.textContaining('لا توجد أحاديث في المفضلة'), findsOneWidget);
  });

  testWidgets('clearing asks first and then empties the list', (tester) async {
    final store = _Favorites()..ids.addAll(['100', '101']);
    await _start(tester, favorites: store);
    await _openFavorites(tester);
    await tester.tap(find.text('مسح المفضلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ليس الآن'));
    await tester.pumpAndSettle();
    expect(store.ids, hasLength(2));
    await tester.tap(find.text('مسح المفضلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إزالة'));
    await tester.pumpAndSettle();
    expect(store.ids, isEmpty);
  });

  testWidgets('a hadith that cannot be loaded is still listed, by number', (
    tester,
  ) async {
    final store = _Favorites()..ids.add('99999');
    final backend = _backend()..detailsFailure = noConnection;
    await _start(tester, favorites: store, backend: backend);
    await _openFavorites(tester);
    expect(find.text('حديث 99999'), findsOneWidget);
  });

  testWidgets('the bookmark announces its state', (tester) async {
    final handle = tester.ensureSemantics();
    await _start(tester);
    await _openHadith(tester);
    expect(
      tester.getSemantics(find.byIcon(Icons.bookmark_border)),
      isSemantics(isToggled: false, hasToggledState: true),
    );
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byIcon(Icons.bookmark)),
      isSemantics(isToggled: true, hasToggledState: true),
    );
    handle.dispose();
  });

  test('favourites store ids only and have no network code of their own', () {
    for (final e in Directory(
      'lib/features/favorites',
    ).listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final text = e.readAsStringSync();
      expect(text, isNot(contains('package:dio')), reason: e.path);
      expect(text, isNot(contains('dart:io')), reason: e.path);
    }
  });
}
