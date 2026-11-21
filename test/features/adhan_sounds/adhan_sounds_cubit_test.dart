import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';
import 'package:mynewapp/features/adhan_sounds/presentation/state/adhan_sounds_cubit.dart';

import '../../support/adhan_fakes.dart';

AdhanItem _item(AdhanSoundsCubit c, String id) =>
    c.state.items.firstWhere((i) => i.sound.id == id);

void main() {
  test(
    'loading shows what is on the phone and whether the phone supports it',
    () async {
      final lib = FakeAdhanLibrary()..have.add('rifaat');
      final cubit = AdhanSoundsCubit(lib);
      expect(cubit.state.loaded, isFalse);
      await cubit.load();
      expect(cubit.state.loaded, isTrue);
      expect(cubit.state.supported, isTrue);
      expect(_item(cubit, 'rifaat').status, AdhanStatus.ready);
      expect(_item(cubit, 'tokhi').status, AdhanStatus.missing);
      expect(cubit.state.items, hasLength(adhanCatalogue.length));
      await cubit.close();
    },
  );

  test(
    'a phone that cannot use it as a notification sound still lists a downloaded recording, '
    'for preview',
    () async {
      final lib = FakeAdhanLibrary()
        ..supported = false
        ..have.add('rifaat');
      final cubit = AdhanSoundsCubit(lib);
      await cubit.load();
      expect(cubit.state.supported, isFalse);
      expect(_item(cubit, 'rifaat').status, AdhanStatus.ready);
      await cubit.close();
    },
  );

  test('a download shows its progress, then is ready', () async {
    final lib = FakeAdhanLibrary()..hold = Completer<void>();
    final cubit = AdhanSoundsCubit(lib);
    await cubit.load();
    final sound = adhanById('rifaat')!;
    final done = cubit.download(sound);
    await Future<void>.delayed(Duration.zero);
    expect(_item(cubit, 'rifaat').status, AdhanStatus.downloading);
    expect(_item(cubit, 'rifaat').progress, 0.5);
    lib.hold!.complete();
    await done;
    expect(_item(cubit, 'rifaat').status, AdhanStatus.ready);
    await cubit.close();
  });

  test('a failed download goes back to missing with the reason', () async {
    final lib = FakeAdhanLibrary()..fail = AdhanDownloadFailure.network;
    final cubit = AdhanSoundsCubit(lib);
    await cubit.load();
    await cubit.download(adhanById('haddad')!);
    expect(_item(cubit, 'haddad').status, AdhanStatus.missing);
    expect(_item(cubit, 'haddad').failure, AdhanDownloadFailure.network);
    // Trying again clears the old failure.
    lib.fail = null;
    await cubit.download(adhanById('haddad')!);
    expect(_item(cubit, 'haddad').status, AdhanStatus.ready);
    expect(_item(cubit, 'haddad').failure, isNull);
    await cubit.close();
  });

  test('asking twice while downloading does not download twice', () async {
    final lib = FakeAdhanLibrary()..hold = Completer<void>();
    var calls = 0;
    final counting = _CountingLibrary(lib, () => calls++);
    final cubit = AdhanSoundsCubit(counting);
    await cubit.load();
    final first = cubit.download(adhanById('mulla')!);
    await Future<void>.delayed(Duration.zero);
    await cubit.download(adhanById('mulla')!);
    lib.hold!.complete();
    await first;
    expect(calls, 1);
    await cubit.close();
  });

  test('deleting makes it missing again', () async {
    final lib = FakeAdhanLibrary()..have.add('tokhi');
    final cubit = AdhanSoundsCubit(lib);
    await cubit.load();
    await cubit.delete('tokhi');
    expect(lib.deleted, ['tokhi']);
    expect(_item(cubit, 'tokhi').status, AdhanStatus.missing);
    await cubit.close();
  });

  test('previewing a downloaded recording plays its local file', () async {
    final lib = FakeAdhanLibrary()..have.add('rifaat');
    final player = FakeAdhanPlayer();
    final cubit = AdhanSoundsCubit(lib, player);
    await cubit.load();
    await cubit.preview('rifaat');
    expect(player.played, ['/fake/adhan/rifaat.mp3']);
    expect(cubit.state.playingId, 'rifaat');
    await cubit.close();
  });

  test(
    'previewing plays at the given volume, full volume by default',
    () async {
      final lib = FakeAdhanLibrary()..have.add('rifaat');
      final player = FakeAdhanPlayer();
      final cubit = AdhanSoundsCubit(lib, player);
      await cubit.load();
      await cubit.preview('rifaat');
      expect(player.volumes, [1]);
      await cubit.preview('rifaat'); // stop
      await cubit.preview('rifaat', volume: 0.25);
      expect(player.volumes, [1, 0.25]);
      await cubit.close();
    },
  );

  test('previewing the one already playing stops it', () async {
    final lib = FakeAdhanLibrary()..have.add('rifaat');
    final player = FakeAdhanPlayer();
    final cubit = AdhanSoundsCubit(lib, player);
    await cubit.load();
    await cubit.preview('rifaat');
    await cubit.preview('rifaat');
    expect(player.stopped, hasLength(1));
    expect(cubit.state.playingId, isNull);
    await cubit.close();
  });

  test('previewing a recording that is not downloaded does nothing', () async {
    final lib = FakeAdhanLibrary();
    final player = FakeAdhanPlayer();
    final cubit = AdhanSoundsCubit(lib, player);
    await cubit.load();
    await cubit.preview('rifaat');
    expect(player.played, isEmpty);
    expect(cubit.state.playingId, isNull);
    await cubit.close();
  });

  test('playback finishing on its own clears the playing state', () async {
    final lib = FakeAdhanLibrary()..have.add('rifaat');
    final player = FakeAdhanPlayer();
    final cubit = AdhanSoundsCubit(lib, player);
    await cubit.load();
    await cubit.preview('rifaat');
    player.completeNow();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.playingId, isNull);
    await cubit.close();
  });

  test('deleting what is playing stops it first', () async {
    final lib = FakeAdhanLibrary()..have.add('rifaat');
    final player = FakeAdhanPlayer();
    final cubit = AdhanSoundsCubit(lib, player);
    await cubit.load();
    await cubit.preview('rifaat');
    await cubit.delete('rifaat');
    expect(player.stopped, hasLength(1));
    expect(cubit.state.playingId, isNull);
    await cubit.close();
  });

  test('closing the cubit disposes the player', () async {
    final lib = FakeAdhanLibrary();
    final player = FakeAdhanPlayer();
    final cubit = AdhanSoundsCubit(lib, player);
    await cubit.close();
    expect(player.disposed, isTrue);
  });
}

class _CountingLibrary implements AdhanLibrary {
  _CountingLibrary(this._inner, this._onDownload);

  final FakeAdhanLibrary _inner;
  final void Function() _onDownload;

  @override
  bool get downloading => _inner.downloading;

  @override
  Future<bool> isSupported() => _inner.isSupported();

  @override
  Future<Set<String>> downloaded() => _inner.downloaded();

  @override
  Future<void> download(
    AdhanSound sound, {
    void Function(double fraction)? onProgress,
  }) {
    _onDownload();
    return _inner.download(sound, onProgress: onProgress);
  }

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<String?> uriFor(String id) => _inner.uriFor(id);

  @override
  Future<String?> localPathFor(String id) => _inner.localPathFor(id);

  @override
  Future<String?> iosSoundFileFor(String id) => _inner.iosSoundFileFor(id);
}
