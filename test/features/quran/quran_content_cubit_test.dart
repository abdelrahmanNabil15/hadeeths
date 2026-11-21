import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_content_cubit.dart';

import '../../support/quran_fakes.dart';

void main() {
  group('loadTranslationEditions', () {
    test('success fills the list and the status', () async {
      final cubit = QuranContentCubit(FakeQuranContentRepository());
      await cubit.loadTranslationEditions();
      expect(cubit.state.translationEditionsStatus, LoadStatus.success);
      expect(cubit.state.translationEditions, placeholderTranslationEditions);
      expect(cubit.state.translationEditionsFailure, isNull);
    });

    test('a server failure is reported, not thrown', () async {
      final cubit = QuranContentCubit(
        FakeQuranContentRepository(failEditions: true),
      );
      await cubit.loadTranslationEditions();
      expect(cubit.state.translationEditionsStatus, LoadStatus.failure);
      expect(cubit.state.translationEditionsFailure?.kind, FailureKind.server);
    });

    test(
      'retrying after a failure clears the old failure on success',
      () async {
        final repo = FakeQuranContentRepository(failEditions: true);
        final cubit = QuranContentCubit(repo);
        await cubit.loadTranslationEditions();
        expect(cubit.state.translationEditionsStatus, LoadStatus.failure);

        repo.failEditions = false;
        await cubit.loadTranslationEditions();
        expect(cubit.state.translationEditionsStatus, LoadStatus.success);
        expect(cubit.state.translationEditionsFailure, isNull);
      },
    );

    test('a second call while loading does not request twice', () async {
      final repo = FakeQuranContentRepository();
      final cubit = QuranContentCubit(repo);
      final first = cubit.loadTranslationEditions();
      final second = cubit.loadTranslationEditions();
      await Future.wait([first, second]);
      expect(cubit.state.translationEditionsStatus, LoadStatus.success);
    });
  });

  group('translation text', () {
    test('is fetched once and then held', () async {
      final repo = FakeQuranContentRepository();
      final cubit = QuranContentCubit(repo);
      const verse = VerseRef(2, 255);
      expect(cubit.translationFor(1, verse), isNull);

      await cubit.loadTranslation(editionId: 1, verse: verse);
      expect(cubit.translationFor(1, verse), placeholderTranslation(1, verse));
      expect(repo.translationCalls, 1);

      await cubit.loadTranslation(editionId: 1, verse: verse);
      expect(
        repo.translationCalls,
        1,
        reason: 'already held, not fetched again',
      );
    });

    test(
      'a different edition for the same verse is fetched separately',
      () async {
        final repo = FakeQuranContentRepository();
        final cubit = QuranContentCubit(repo);
        const verse = VerseRef(1, 1);
        await cubit.loadTranslation(editionId: 1, verse: verse);
        await cubit.loadTranslation(editionId: 2, verse: verse);
        expect(
          cubit.translationFor(1, verse),
          placeholderTranslation(1, verse),
        );
        expect(
          cubit.translationFor(2, verse),
          placeholderTranslation(2, verse),
        );
        expect(repo.translationCalls, 2);
      },
    );

    test('a failed fetch is silent: nothing held, no exception', () async {
      final cubit = QuranContentCubit(
        FakeQuranContentRepository(failTranslation: true),
      );
      const verse = VerseRef(1, 1);
      await cubit.loadTranslation(editionId: 1, verse: verse);
      expect(cubit.translationFor(1, verse), isNull);
    });

    test(
      'loading a translation does not disturb the editions-list state',
      () async {
        final cubit = QuranContentCubit(FakeQuranContentRepository());
        await cubit.loadTranslationEditions();
        await cubit.loadTranslation(editionId: 1, verse: const VerseRef(1, 1));
        expect(cubit.state.translationEditionsStatus, LoadStatus.success);
        expect(cubit.state.translationEditions, placeholderTranslationEditions);
      },
    );
  });

  group('loadTafsirEditions', () {
    test('success fills the list and the status', () async {
      final cubit = QuranContentCubit(FakeQuranContentRepository());
      await cubit.loadTafsirEditions();
      expect(cubit.state.tafsirEditionsStatus, LoadStatus.success);
      expect(cubit.state.tafsirEditions, placeholderTafsirEditions);
      expect(cubit.state.tafsirEditionsFailure, isNull);
    });

    test('a server failure is reported, not thrown', () async {
      final cubit = QuranContentCubit(
        FakeQuranContentRepository(failTafsirEditions: true),
      );
      await cubit.loadTafsirEditions();
      expect(cubit.state.tafsirEditionsStatus, LoadStatus.failure);
      expect(cubit.state.tafsirEditionsFailure?.kind, FailureKind.server);
    });

    test(
      'does not disturb the translation-editions state, or the reverse',
      () async {
        final cubit = QuranContentCubit(FakeQuranContentRepository());
        await cubit.loadTranslationEditions();
        await cubit.loadTafsirEditions();
        expect(cubit.state.translationEditionsStatus, LoadStatus.success);
        expect(cubit.state.translationEditions, placeholderTranslationEditions);
        expect(cubit.state.tafsirEditionsStatus, LoadStatus.success);
        expect(cubit.state.tafsirEditions, placeholderTafsirEditions);
      },
    );
  });

  group('tafsir text', () {
    test('is fetched once and then held', () async {
      final repo = FakeQuranContentRepository();
      final cubit = QuranContentCubit(repo);
      const verse = VerseRef(2, 255);
      expect(cubit.tafsirFor(10, verse), isNull);

      await cubit.loadTafsir(editionId: 10, verse: verse);
      expect(cubit.tafsirFor(10, verse), placeholderTafsir(10, verse));
      expect(repo.tafsirCalls, 1);

      await cubit.loadTafsir(editionId: 10, verse: verse);
      expect(repo.tafsirCalls, 1, reason: 'already held, not fetched again');
    });

    test('a failure is held, not silent, unlike a translation', () async {
      final cubit = QuranContentCubit(
        FakeQuranContentRepository(failTafsir: true),
      );
      const verse = VerseRef(1, 1);
      await cubit.loadTafsir(editionId: 10, verse: verse);
      expect(cubit.tafsirFor(10, verse), isNull);
      expect(cubit.tafsirFailureFor(10, verse)?.kind, FailureKind.server);
    });

    test('a failed fetch is not retried on its own', () async {
      final repo = FakeQuranContentRepository(failTafsir: true);
      final cubit = QuranContentCubit(repo);
      const verse = VerseRef(1, 1);
      await cubit.loadTafsir(editionId: 10, verse: verse);
      await cubit.loadTafsir(editionId: 10, verse: verse);
      expect(repo.tafsirCalls, 1);
    });

    test('retryTafsir clears the failure so loadTafsir tries again', () async {
      final repo = FakeQuranContentRepository(failTafsir: true);
      final cubit = QuranContentCubit(repo);
      const verse = VerseRef(1, 1);
      await cubit.loadTafsir(editionId: 10, verse: verse);
      expect(cubit.tafsirFailureFor(10, verse), isNotNull);

      repo.failTafsir = false;
      cubit.retryTafsir(10, verse);
      expect(cubit.tafsirFailureFor(10, verse), isNull);
      await cubit.loadTafsir(editionId: 10, verse: verse);
      expect(cubit.tafsirFor(10, verse), placeholderTafsir(10, verse));
      expect(repo.tafsirCalls, 2);
    });
  });

  group('loadReciters', () {
    test('success fills the list and the status', () async {
      final cubit = QuranContentCubit(FakeQuranContentRepository());
      await cubit.loadReciters();
      expect(cubit.state.reciterStatus, LoadStatus.success);
      expect(cubit.state.reciters, placeholderReciters);
      expect(cubit.state.reciterFailure, isNull);
    });

    test('a server failure is reported, not thrown', () async {
      final cubit = QuranContentCubit(
        FakeQuranContentRepository(failReciters: true),
      );
      await cubit.loadReciters();
      expect(cubit.state.reciterStatus, LoadStatus.failure);
      expect(cubit.state.reciterFailure?.kind, FailureKind.server);
    });

    test(
      'does not disturb translation or tafsir edition state, or the reverse',
      () async {
        final cubit = QuranContentCubit(FakeQuranContentRepository());
        await cubit.loadTranslationEditions();
        await cubit.loadTafsirEditions();
        await cubit.loadReciters();
        expect(cubit.state.translationEditions, placeholderTranslationEditions);
        expect(cubit.state.tafsirEditions, placeholderTafsirEditions);
        expect(cubit.state.reciters, placeholderReciters);
      },
    );
  });
}
