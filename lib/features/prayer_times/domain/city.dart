import 'package:equatable/equatable.dart';
import 'package:mynewapp/core/text/arabic_search.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';

/// A city the user can pick by hand. No location permission is needed for this.
class City extends Equatable {
  City({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.countryCode,
    required this.point,
    required this.zoneId,
  }) : _searchKey =
           '${normalizeForSearch(nameAr)}|${normalizeForSearch(nameEn)}';

  /// The GeoNames identifier.
  final int id;
  final String nameEn;
  final String nameAr;

  /// ISO 3166-1 alpha-2, used only to propose a calculation method; never shown.
  final String countryCode;
  final GeoPoint point;

  /// IANA zone name, for example `Africa/Cairo`.
  final String zoneId;

  final String _searchKey;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  /// Whether the text the user typed matches this city in either language (see
  /// [normalizeForSearch]).
  bool matches(String query) {
    final q = normalizeForSearch(query);
    return q.isEmpty || _searchKey.contains(q);
  }

  /// The place to calculate prayer times for, named in the language the user is using.
  PrayerLocation toLocation(String languageCode) => PrayerLocation(
    point: point,
    source: LocationSource.manual,
    zoneId: zoneId,
    name: name(languageCode),
    countryCode: countryCode,
  );

  @override
  List<Object?> get props => [id, nameEn, nameAr, countryCode, point, zoneId];
}

/// The cities that ship with the app.
class CityCatalog {
  CityCatalog(List<City> cities) : cities = List.unmodifiable(cities);

  /// Reads `assets/data/cities.json`.
  factory CityCatalog.fromJson(Map<String, dynamic> json) => CityCatalog([
    for (final c in (json['cities'] as List).cast<Map<String, dynamic>>())
      City(
        id: c['id'] as int,
        nameEn: c['en'] as String,
        nameAr: c['ar'] as String,
        countryCode: c['cc'] as String,
        point: GeoPoint(
          (c['lat'] as num).toDouble(),
          (c['lon'] as num).toDouble(),
        ),
        zoneId: c['tz'] as String,
      ),
  ]);

  final List<City> cities;

  /// Cities matching [query] in either language, in catalogue order. An empty query returns all.
  List<City> search(String query) => [
    for (final city in cities)
      if (city.matches(query)) city,
  ];

  City? byId(int id) {
    for (final city in cities) {
      if (city.id == id) return city;
    }
    return null;
  }
}
