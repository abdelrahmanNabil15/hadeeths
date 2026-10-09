import 'dart:convert';

import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the preferences as one small JSON text in `shared_preferences`.
///
/// Reading is forgiving: a value that is missing, of the wrong type or out of range falls back to
/// its default instead of failing, and unreadable data as a whole means "not set up yet". The
/// stored position is already rounded (see [PrayerLocation]).
class PrayerPreferencesRepositoryImpl implements PrayerPreferencesRepository {
  PrayerPreferencesRepositoryImpl(this._preferences);

  final SharedPreferences _preferences;

  static const storageKey = 'prayer_preferences_v1';

  @override
  Future<PrayerPreferences> load() async {
    try {
      final text = _preferences.getString(storageKey);
      if (text == null) return PrayerPreferences();
      return _decode(jsonDecode(text));
    } on Object {
      return PrayerPreferences();
    }
  }

  @override
  Future<void> save(PrayerPreferences preferences) async {
    await _preferences.setString(storageKey, jsonEncode(_encode(preferences)));
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(storageKey);
  }

  static Map<String, Object?> _encode(PrayerPreferences p) {
    final place = p.location;
    return {
      'version': 1,
      'origin': p.methodOrigin.name,
      'method': p.settings.method.name,
      'madhab': p.settings.madhab.name,
      'highLatitudeRule': p.settings.highLatitudeRule.name,
      'adjustments': {
        for (final e in p.settings.adjustments.entries) e.key.name: e.value,
      },
      'hijriReference': p.hijri.reference.name,
      'hijriAdjustment': p.hijri.adjustmentDays,
      'location': place == null
          ? null
          : {
              'latitude': place.point.latitude,
              'longitude': place.point.longitude,
              'source': place.source.name,
              'zone': place.zoneId,
              'name': place.name,
              'country': place.countryCode,
            },
    };
  }

  static PrayerPreferences _decode(Object? json) {
    if (json is! Map<String, dynamic>) return PrayerPreferences();
    final adjustments = <Prayer, int>{};
    final stored = json['adjustments'];
    if (stored is Map<String, dynamic>) {
      for (final entry in stored.entries) {
        final prayer = _byName(Prayer.values, entry.key);
        final value = entry.value;
        if (prayer != null &&
            value is int &&
            value.abs() <= CalculationSettings.maxAdjustmentMinutes) {
          adjustments[prayer] = value;
        }
      }
    }
    final settings = CalculationSettings(
      method:
          _byName(CalculationMethodId.values, json['method']) ??
          CalculationSettings.defaultMethod,
      madhab: _byName(Madhab.values, json['madhab']) ?? Madhab.shafii,
      highLatitudeRule:
          _byName(HighLatitudeRule.values, json['highLatitudeRule']) ??
          HighLatitudeRule.middleOfTheNight,
      adjustments: adjustments,
    );
    final location = _decodeLocation(json['location']);
    // A method with no place is the untouched default: "decided" only makes sense once a place exists.
    final origin = location == null
        ? MethodOrigin.notSet
        : _byName(MethodOrigin.values, json['origin']) ?? MethodOrigin.user;
    final adjustment = json['hijriAdjustment'];
    final hijri = HijriSettings(
      reference:
          _byName(HijriReference.values, json['hijriReference']) ??
          HijriReference.ummAlQura,
      adjustmentDays:
          adjustment is int &&
              adjustment.abs() <= HijriSettings.maxAdjustmentDays
          ? adjustment
          : 0,
    );
    return PrayerPreferences(
      location: location,
      settings: settings,
      methodOrigin: origin,
      hijri: hijri,
    );
  }

  static PrayerLocation? _decodeLocation(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final lat = json['latitude'];
    final lon = json['longitude'];
    final source = _byName(LocationSource.values, json['source']);
    final zone = json['zone'];
    if (lat is! num || lon is! num || source == null || zone is! String) {
      return null;
    }
    try {
      final name = json['name'];
      final country = json['country'];
      return PrayerLocation(
        point: GeoPoint(lat.toDouble(), lon.toDouble()),
        source: source,
        zoneId: zone,
        name: name is String ? name : null,
        countryCode: country is String ? country : null,
      );
    } on RangeError {
      return null;
    }
  }

  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
