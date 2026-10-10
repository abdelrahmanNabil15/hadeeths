import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/features/quran/domain/quran_search.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

enum QuranStatus { loading, unavailable, ready }

class QuranState {
  const QuranState({
    this.status = QuranStatus.loading,
    this.text,
    this.lastRead,
    this.bookmarks = const [],
  });

  final QuranStatus status;
  final QuranText? text;
  final VerseRef? lastRead;
  final List<VerseRef> bookmarks;

  QuranState copyWith({VerseRef? lastRead, List<VerseRef>? bookmarks}) =>
      QuranState(
        status: status,
        text: text,
        lastRead: lastRead ?? this.lastRead,
        bookmarks: bookmarks ?? this.bookmarks,
      );
}

/// The Quran section: the verified text, where the user stopped, and their bookmarks. Shared by
/// the list, the reader and search, so a bookmark made in the reader shows in the list at once.
class QuranCubit extends Cubit<QuranState> {
  QuranCubit({required this.source, this.userData}) : super(const QuranState());

  final QuranSource source;

  /// Null when the user's storage could not be opened: reading still works, nothing is remembered.
  final QuranUserData? userData;

  QuranSearch? _search;

  QuranSearch? get search {
    final text = state.text;
    if (text == null) return null;
    return _search ??= QuranSearch(text);
  }

  Future<void> load() async {
    try {
      final text = await source.load();
      VerseRef? last;
      var marks = const <VerseRef>[];
      try {
        last = await userData?.lastRead();
        marks = await userData?.bookmarks() ?? const [];
      } on Object {
        // The text is still readable without the user's marks.
      }
      if (isClosed) return;
      emit(
        QuranState(
          status: QuranStatus.ready,
          text: text,
          lastRead: last,
          bookmarks: marks,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(const QuranState(status: QuranStatus.unavailable));
    }
  }

  Future<void> setLastRead(VerseRef place) async {
    if (state.lastRead == place) return;
    emit(state.copyWith(lastRead: place));
    try {
      await userData?.setLastRead(place);
    } on Object {
      // Remembered for this session only.
    }
  }

  bool isBookmarked(VerseRef place) => state.bookmarks.contains(place);

  Future<void> toggleBookmark(VerseRef place) async {
    final on = !isBookmarked(place);
    final next = [...state.bookmarks.where((b) => b != place), if (on) place]
      ..sort();
    emit(state.copyWith(bookmarks: next));
    try {
      await userData?.setBookmark(place, on: on);
    } on Object {
      if (isClosed) return;
      final back = [...state.bookmarks.where((b) => b != place), if (!on) place]
        ..sort();
      emit(state.copyWith(bookmarks: back));
    }
  }
}
