import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/licences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Quran font is bundled and declared', () {
    final font = File('assets/fonts/AmiriQuran.ttf');
    expect(font.existsSync(), isTrue);
    expect(font.lengthSync(), greaterThan(100000));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: ${AppFonts.quran}'));
    expect(pubspec, contains('assets/fonts/AmiriQuran.ttf'));
  });

  test('its licence is the Amiri family licence (SIL OFL 1.1)', () {
    final licence = File('assets/licenses/OFL-Amiri.txt').readAsStringSync();
    expect(licence, contains('The Amiri Project Authors'));
    expect(licence, contains('SIL OPEN FONT LICENSE Version 1.1'));
  });

  test('the licence page names the Quran font', () async {
    registerFontLicences();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    expect(
      packages,
      containsAll(['Amiri font', 'Amiri Quran font', 'Cairo font']),
    );
  });
}
