// Renders the main screens with fake data and the real fonts, and saves them as PNG files for visual
// review (not part of the normal test run, which only covers `test/`).
//
//   flutter test test_screens/screens_test.dart --dart-define=SHOTS=before
//
// Images land in `build/screens/<SHOTS>/<config>/`. Category and hadith texts are the placeholder
// fixtures used by the tests, never real religious text.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/share/image_sharer.dart';
import 'package:mynewapp/features/favorites/domain/favorites_repository.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/search/presentation/widgets/search_entry.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_counter.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_repository.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../test/support/fake_backend.dart';
import '../test/support/fixtures.dart';
import '../test/support/prayer_fakes.dart';
import '../test/support/test_app.dart';
import '../test/support/tracker_fakes.dart';

const _set = String.fromEnvironment('SHOTS', defaultValue: 'latest');

class _Config {
  const _Config(this.locale, this.theme, {this.textScale = 1.0});

  final String locale;
  final ThemePreference theme;
  final double textScale;

  String get name =>
      '${locale}_${theme.name}${textScale == 1.0 ? '' : '_x${textScale.toStringAsFixed(0)}'}';
}

const _configs = [
  _Config('ar', ThemePreference.light),
  _Config('ar', ThemePreference.dark),
  _Config('en', ThemePreference.light),
  _Config('en', ThemePreference.dark),
  _Config('ar', ThemePreference.light, textScale: 2.0),
];

class _Favorites implements FavoritesRepository {
  final ids = <String>['100', '101'];

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

class _Tasbeeh implements TasbeehRepository {
  TasbeehCounter stored = const TasbeehCounter(count: 21, target: 33);

  @override
  Future<TasbeehCounter> load() async => stored;

  @override
  Future<void> save(TasbeehCounter counter) async => stored = counter;
}

class _NoSharer implements ImageSharer {
  @override
  Future<void> sharePngs(List<Uint8List> pngs, {required String text}) async {}
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Cairo', ['assets/fonts/Cairo.ttf']);
  await load('Amiri', [
    'assets/fonts/Amiri-Regular.ttf',
    'assets/fonts/Amiri-Bold.ttf',
  ]);
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      'D:/StudioProjects/Flutter/flutter';
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

PrayerPreferences _cairo() {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  return PrayerPreferences().withLocation(cairo.toLocation('ar'));
}

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await _loadFonts();
  });

  for (final config in _configs) {
    testWidgets('screens ${config.name}', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final l10n = lookupAppLocalizations(Locale(config.locale));
      final dir = 'build/screens/$_set/${config.name}';
      var index = 0;

      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        final view = tester.binding.renderViews.first;
        final layer = view.debugLayer! as OffsetLayer;
        // The root layer is already in physical pixels.
        await tester.runAsync(() async {
          final image = await layer.toImage(
            Offset.zero & tester.view.physicalSize,
          );
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final number = (++index).toString().padLeft(2, '0');
          File('$dir/${number}_$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        });
      }

      Future<void> tap(Finder finder) async {
        // Rows below the fold of a lazy list are not built until scrolled to.
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            200,
            scrollable: find.byType(Scrollable).hitTestable().first,
          );
        }
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> tab(String label) => tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );

      Future<void> back() async {
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
      }

      // Taps the barrier above a sheet or a dialog.
      Future<void> dismiss() async {
        if (find.byType(ModalBarrier).hitTestable().evaluate().isEmpty) return;
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
      }

      final fixture = PrayerFixture(
        now: DateTime.utc(2026, 10, 9, 10),
        saved: _cairo(),
      );
      await pumpApp(
        tester,
        FakeBackend(
          pages: {
            '2:1': samplePage(
              ids: List.generate(8, (i) => '${100 + i}'),
              totalItems: 8,
            ),
          },
        ),
        locale: config.locale,
        settings: AppSettings(theme: config.theme),
        features: const FeatureFlags(
          prayer: true,
          favorites: true,
          shareCards: true,
        ),
        prayer: fixture.services,
        prayerLog: InMemoryPrayerLog(),
        tasbeeh: _Tasbeeh(),
        favorites: _Favorites(),
        imageSharer: _NoSharer(),
      );

      // Hadiths section.
      await shot('home');
      await tap(find.text(categoriesJson[0]['title']!).first);
      await shot('category');
      await back();
      await tap(find.text(categoriesJson[1]['title']!).first);
      await shot('hadith_list');
      await tap(find.text('حديث 100').first);
      await shot('hadith_details');
      await tap(find.byTooltip(l10n.shareHadith));
      await shot('share_sheet');
      await dismiss();
      await tap(find.byTooltip(l10n.textSize).first);
      await shot('reading_size');
      await dismiss();
      await tab(l10n.navHadiths);
      await tab(l10n.navHadiths);
      await tap(find.byType(SearchEntry));
      await tester.enterText(find.byType(TextField).first, 'صلاة');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await shot('search');
      await back();

      // Prayer section.
      await tab(l10n.navPrayer);
      await shot('prayer');
      await tap(find.text(l10n.remindersHeading));
      await shot('reminders');
      await back();

      // More section.
      await tab(l10n.navMore);
      await shot('more');
      await tap(find.text(l10n.favoritesTitle));
      await shot('favorites');
      await back();
      await tap(find.text(l10n.trackerTitle));
      await shot('tracker');
      await back();
      await tap(find.text(l10n.tasbeehTitle));
      await shot('tasbeeh');
      await back();
      await tap(find.text(l10n.settings));
      await shot('settings');
      await tap(find.text(l10n.deleteAllButton));
      await shot('delete_dialog');
      await tap(find.text(l10n.notNow));
      await back();
      await tap(find.text(l10n.aboutTitle));
      await shot('about');
    });
  }
}
