import 'package:equatable/equatable.dart';

/// A place in the Quran: sura and verse.
class VerseRef extends Equatable implements Comparable<VerseRef> {
  const VerseRef(this.sura, this.verse);

  final int sura;
  final int verse;

  @override
  int compareTo(VerseRef other) =>
      sura != other.sura ? sura - other.sura : verse - other.verse;

  @override
  List<Object?> get props => [sura, verse];

  @override
  String toString() => '$sura:$verse';
}

/// The reader's own marks: where the user stopped, and the verses they bookmarked. Positions only,
/// never text. Stored on the device only.
abstract interface class QuranUserData {
  Future<VerseRef?> lastRead();

  Future<void> setLastRead(VerseRef place);

  /// Bookmarked verses, in Mushaf order.
  Future<List<VerseRef>> bookmarks();

  Future<bool> isBookmarked(VerseRef place);

  Future<void> setBookmark(VerseRef place, {required bool on});
}
