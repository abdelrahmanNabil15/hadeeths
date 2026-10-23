import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_audio_cubit.dart';

import '../../support/quran_fakes.dart';

void main() {
  group('play', () {
    test('resolves the url through the repository and plays it', () async {
      final repo = FakeQuranContentRepository();
      final player = FakeQuranAudioPlayer();
      final cubit = QuranAudioCubit(repo, player);
      const verse = VerseRef(1, 1);

      await cubit.play(reciterId: 1, verse: verse, firstVerse: 1, lastVerse: 7);
      expect(repo.recitationCalls, 1);
      expect(player.playedUrls.single, placeholderRecitationUrl(1, verse));
      expect(cubit.state.status, AudioPlaybackStatus.playing);
      expect(cubit.state.verse, verse);
    });

    test('a resolution failure is reported, not thrown', () async {
      final repo = FakeQuranContentRepository(failRecitation: true);
      final player = FakeQuranAudioPlayer();
      final cubit = QuranAudioCubit(repo, player);

      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 7,
      );
      expect(cubit.state.status, AudioPlaybackStatus.failure);
      expect(cubit.state.failure?.kind, FailureKind.server);
      expect(player.playedUrls, isEmpty);
    });

    test('a player failure is reported as unexpected', () async {
      final repo = FakeQuranContentRepository();
      final player = FakeQuranAudioPlayer()..failPlay = true;
      final cubit = QuranAudioCubit(repo, player);

      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 7,
      );
      expect(cubit.state.status, AudioPlaybackStatus.failure);
      expect(cubit.state.failure?.kind, FailureKind.unexpected);
    });

    test('starting a new verse replaces whatever was playing', () async {
      final repo = FakeQuranContentRepository();
      final player = FakeQuranAudioPlayer();
      final cubit = QuranAudioCubit(repo, player);

      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 7,
      );
      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 2),
        firstVerse: 1,
        lastVerse: 7,
      );
      expect(cubit.state.verse, const VerseRef(1, 2));
      expect(player.playedUrls, hasLength(2));
    });
  });

  group('pause and resume', () {
    test('pause stops the player and the state reflects it', () async {
      final player = FakeQuranAudioPlayer();
      final cubit = QuranAudioCubit(FakeQuranContentRepository(), player);
      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 7,
      );

      await cubit.pause();
      expect(player.pauseCalls, 1);
      expect(cubit.state.status, AudioPlaybackStatus.paused);

      await cubit.resume();
      expect(player.resumeCalls, 1);
      expect(cubit.state.status, AudioPlaybackStatus.playing);
    });
  });

  group('stop', () {
    test('resets to idle and stops the player', () async {
      final player = FakeQuranAudioPlayer();
      final cubit = QuranAudioCubit(FakeQuranContentRepository(), player);
      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 7,
      );

      await cubit.stop();
      expect(player.stopCalls, 1);
      expect(cubit.state.status, AudioPlaybackStatus.idle);
      expect(cubit.state.verse, isNull);
    });
  });

  group('next and previous', () {
    test('hasNext/hasPrevious respect the sura bounds', () async {
      final cubit = QuranAudioCubit(
        FakeQuranContentRepository(),
        FakeQuranAudioPlayer(),
      );
      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 3,
      );
      expect(cubit.hasPrevious, isFalse);
      expect(cubit.hasNext, isTrue);

      await cubit.next();
      expect(cubit.state.verse, const VerseRef(1, 2));
      expect(cubit.hasPrevious, isTrue);
      expect(cubit.hasNext, isTrue);

      await cubit.next();
      expect(cubit.state.verse, const VerseRef(1, 3));
      expect(cubit.hasNext, isFalse);

      // At the last verse, next() is a no-op.
      await cubit.next();
      expect(cubit.state.verse, const VerseRef(1, 3));
    });

    test('previous() is a no-op before the first verse', () async {
      final cubit = QuranAudioCubit(
        FakeQuranContentRepository(),
        FakeQuranAudioPlayer(),
      );
      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 3,
      );
      await cubit.previous();
      expect(cubit.state.verse, const VerseRef(1, 1));
    });
  });

  group('auto-advance on completion', () {
    test('a finished verse advances to the next one on its own', () async {
      final repo = FakeQuranContentRepository();
      final player = FakeQuranAudioPlayer();
      final cubit = QuranAudioCubit(repo, player);
      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 3,
      );

      player.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.verse, const VerseRef(1, 2));
      expect(cubit.state.status, AudioPlaybackStatus.playing);
    });

    test('finishing the last verse of the sura stops instead', () async {
      final player = FakeQuranAudioPlayer();
      final cubit = QuranAudioCubit(FakeQuranContentRepository(), player);
      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 3),
        firstVerse: 1,
        lastVerse: 3,
      );

      player.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AudioPlaybackStatus.idle);
      expect(player.stopCalls, 1);
    });
  });

  group('retry', () {
    test(
      'replays the same verse, reciter and bounds that just failed',
      () async {
        final repo = FakeQuranContentRepository(failRecitation: true);
        final player = FakeQuranAudioPlayer();
        final cubit = QuranAudioCubit(repo, player);
        await cubit.play(
          reciterId: 1,
          verse: const VerseRef(1, 1),
          firstVerse: 1,
          lastVerse: 7,
        );
        expect(cubit.state.status, AudioPlaybackStatus.failure);

        repo.failRecitation = false;
        await cubit.retry();
        expect(cubit.state.status, AudioPlaybackStatus.playing);
        expect(
          player.playedUrls.single,
          placeholderRecitationUrl(1, const VerseRef(1, 1)),
        );
      },
    );
  });

  group('position and duration', () {
    test('tick through to the state', () async {
      final player = FakeQuranAudioPlayer();
      final cubit = QuranAudioCubit(FakeQuranContentRepository(), player);
      await cubit.play(
        reciterId: 1,
        verse: const VerseRef(1, 1),
        firstVerse: 1,
        lastVerse: 7,
      );
      expect(cubit.state.duration, const Duration(seconds: 10));

      player.emitPosition(const Duration(seconds: 3));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.position, const Duration(seconds: 3));
    });
  });

  test('close disposes the player', () async {
    final player = FakeQuranAudioPlayer();
    final cubit = QuranAudioCubit(FakeQuranContentRepository(), player);
    await cubit.close();
    expect(player.disposeCalls, 1);
  });
}
