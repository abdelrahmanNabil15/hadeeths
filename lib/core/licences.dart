import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licence texts of the bundled fonts to Flutter's licence page.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final font in const ['Cairo', 'Amiri']) {
      final text = await rootBundle.loadString('assets/licenses/OFL-$font.txt');
      yield LicenseEntryWithLineBreaks(['$font font'], text);
    }
  });
}
