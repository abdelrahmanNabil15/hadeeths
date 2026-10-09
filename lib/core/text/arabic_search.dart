/// Turns text into a form for **matching only**, so a search for `الاسكندريه` finds
/// `الإسكندرية`. The original text is always what is shown; this result is never displayed
/// or stored in place of it.
///
/// Policy (kept deliberately small, so it cannot hide real differences):
/// - Arabic diacritics (tashkeel), the Quranic marks and tatweel are removed;
/// - alef with hamza or madda above or below, and alef wasla, count as a plain alef;
/// - alef maqsura counts as ya, and ta marbuta counts as ha (the usual way people type);
/// - Latin letters are lower-cased and accents on them are not touched;
/// - runs of spaces collapse to one and the ends are trimmed.
///
/// Hamza on waw or ya (ؤ ئ) and the hamza alone (ء) are left as they are.
String normalizeForSearch(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (_isIgnorable(rune)) continue;
    buffer.writeCharCode(_fold(rune));
  }
  return buffer.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isIgnorable(int rune) =>
    (rune >= 0x064B && rune <= 0x065F) || // harakat and other marks
    rune == 0x0670 || // dagger alef
    (rune >= 0x06D6 && rune <= 0x06ED) || // Quranic annotation marks
    rune == 0x0640; // tatweel

int _fold(int rune) {
  switch (rune) {
    case 0x0622: // آ
    case 0x0623: // أ
    case 0x0625: // إ
    case 0x0671: // ٱ
      return 0x0627; // ا
    case 0x0649: // ى
      return 0x064A; // ي
    case 0x0629: // ة
      return 0x0647; // ه
    default:
      return rune;
  }
}
