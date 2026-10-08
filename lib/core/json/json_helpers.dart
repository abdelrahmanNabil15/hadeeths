// Defensive readers for HadeethEnc JSON. The API sends ids and some meta fields as
// strings and others as numbers, so every reader accepts both.

String asString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

int asInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

List<String> asStringList(Object? value) {
  if (value is List) return value.map((e) => asString(e)).toList();
  return const [];
}

/// Returns [value] as a JSON object or throws a [FormatException].
Map<String, dynamic> asMap(Object? value, String what) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Expected a JSON object for $what');
}

/// Returns [value] as a JSON array or throws a [FormatException].
List<dynamic> asList(Object? value, String what) {
  if (value is List) return value;
  throw FormatException('Expected a JSON array for $what');
}
