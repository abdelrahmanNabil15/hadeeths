import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/time/iana_time_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';

import '../../support/prayer_fakes.dart';

void main() {
  final catalog = realCityCatalog();
  final countries = realCountryLookup();

  group('the bundled list', () {
    test('has the expected size and unique ids', () {
      expect(catalog.cities.length, greaterThan(100));
      expect(
        {for (final c in catalog.cities) c.id}.length,
        catalog.cities.length,
      );
    });

    test('every entry is complete and usable', () {
      for (final c in catalog.cities) {
        expect(c.nameEn.trim(), isNotEmpty, reason: '${c.id}');
        expect(c.nameAr.trim(), isNotEmpty, reason: c.nameEn);
        expect(
          RegExp(r'^[A-Z]{2}$').hasMatch(c.countryCode),
          isTrue,
          reason: c.nameEn,
        );
        expect(
          IanaTimeZone.tryParse(c.zoneId),
          isNotNull,
          reason: '${c.nameEn}: unknown zone ${c.zoneId}',
        );
        // Arabic names should be Arabic (letters from the Arabic block), not a leftover Latin name.
        expect(RegExp(r'[؀-ۿ]').hasMatch(c.nameAr), isTrue, reason: c.nameEn);
      }
    });

    test(
      'each city is where its country is (a coarse check against the borders)',
      () {
        // The borders are drawn at a coarse scale and contested places have no single answer, so a
        // small number of differences is expected; a large number would mean wrong data.
        final differing = [
          for (final c in catalog.cities)
            if (countries.countryAt(c.point) != c.countryCode) c.nameEn,
        ];
        expect(differing.length, lessThanOrEqualTo(6), reason: '$differing');
      },
    );

    test('the cities the first users need are present', () {
      for (final name in [
        'Cairo',
        'Alexandria',
        'Makkah',
        'Madinah',
        'Riyadh',
        'London',
        'New York',
      ]) {
        expect(
          catalog.cities.any((c) => c.nameEn == name),
          isTrue,
          reason: name,
        );
      }
    });

    test('Cairo has the right zone and position', () {
      final cairo = catalog.cities.firstWhere((c) => c.nameEn == 'Cairo');
      expect(cairo.zoneId, 'Africa/Cairo');
      expect(cairo.nameAr, 'القاهرة');
      expect(cairo.point.latitude, closeTo(30.05, 0.1));
      expect(cairo.point.longitude, closeTo(31.24, 0.1));
      expect(cairo.countryCode, 'EG');
    });

    test('Makkah and Madinah are named the way people write them', () {
      expect(
        catalog.cities.firstWhere((c) => c.nameEn == 'Makkah').nameAr,
        'مكة المكرمة',
      );
      expect(
        catalog.cities.firstWhere((c) => c.nameEn == 'Madinah').nameAr,
        'المدينة المنورة',
      );
    });
  });

  group('search', () {
    List<String> find(String q) => [
      for (final c in catalog.search(q)) c.nameEn,
    ];

    test('an empty search lists everything', () {
      expect(catalog.search('').length, catalog.cities.length);
      expect(catalog.search('   ').length, catalog.cities.length);
    });

    test('finds by Arabic or English name', () {
      expect(find('القاهرة'), contains('Cairo'));
      expect(find('cairo'), contains('Cairo'));
      expect(find('CAIRO'), contains('Cairo'));
    });

    test('tolerates the usual Arabic spelling variants', () {
      expect(find('الاسكندريه'), contains('Alexandria'));
      expect(find('مكه'), contains('Makkah'));
      expect(find('ابوظبي'), contains('Abu Dhabi'));
      expect(find('المدينه المنوره'), contains('Madinah'));
    });

    test('finds part of a name', () {
      expect(find('اسك'), contains('Alexandria'));
      expect(find('york'), contains('New York'));
    });

    test('no match gives an empty list', () {
      expect(find('zzzz'), isEmpty);
      expect(find('ؤؤؤ'), isEmpty);
    });

    test('the text shown is never the normalised one', () {
      final city = catalog
          .search('الاسكندريه')
          .firstWhere((c) => c.nameEn == 'Alexandria');
      expect(city.nameAr, 'الإسكندرية');
    });
  });

  group('turning a city into a place', () {
    final cairo = catalog.cities.firstWhere((c) => c.nameEn == 'Cairo');

    test('keeps the zone, country and the name in the chosen language', () {
      final ar = cairo.toLocation('ar');
      expect(ar.name, 'القاهرة');
      expect(ar.zoneId, 'Africa/Cairo');
      expect(ar.countryCode, 'EG');
      expect(ar.source, LocationSource.manual);
      expect(ar.usesDeviceZone, isFalse);
      expect(cairo.toLocation('en').name, 'Cairo');
    });

    test('the stored position is rounded', () {
      expect(cairo.toLocation('en').point, cairo.point.rounded());
    });

    test('name() picks the language', () {
      expect(cairo.name('ar'), 'القاهرة');
      expect(cairo.name('en'), 'Cairo');
    });

    test('byId finds a city and returns null for an unknown id', () {
      expect(catalog.byId(cairo.id), cairo);
      expect(catalog.byId(-1), isNull);
    });
  });

  test('City equality is by value', () {
    final a = catalog.cities.first;
    final b = City(
      id: a.id,
      nameEn: a.nameEn,
      nameAr: a.nameAr,
      countryCode: a.countryCode,
      point: a.point,
      zoneId: a.zoneId,
    );
    expect(a, b);
  });
}
