/// A short, stable fingerprint of some bytes: 64-bit FNV-1a as 16 hex digits.
///
/// It detects a damaged, truncated or different file (for example a different edition of a
/// bundled text). It is not a defence against deliberate tampering; the bundled files ship inside
/// the signed app, so that is not what it is for.
String fingerprint(List<int> bytes) {
  var hash = 0xcbf29ce484222325;
  for (final b in bytes) {
    hash ^= b & 0xFF;
    hash *= 0x100000001b3; // wraps around at 64 bits
  }
  String half(int value) => value.toRadixString(16).padLeft(8, '0');
  return half((hash >>> 32) & 0xFFFFFFFF) + half(hash & 0xFFFFFFFF);
}
