import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/full_adhan_coordinator.dart';
import 'package:mynewapp/core/platform/full_adhan_channel.dart';

import '../support/adhan_fakes.dart';

/// A channel in memory: a test calls [fire] instead of native code invoking the method.
class _FakeFullAdhanChannel implements FullAdhanChannel {
  void Function(String adhanId)? _onPlay;

  @override
  void listen(void Function(String adhanId) onPlay) => _onPlay = onPlay;

  void fire(String adhanId) => _onPlay!(adhanId);
}

void main() {
  test('plays the full recording the native side asks for', () async {
    final channel = _FakeFullAdhanChannel();
    final library = FakeAdhanLibrary()..have.add('rifaat');
    final player = FakeAdhanPlayer();
    FullAdhanCoordinator(channel: channel, library: library, player: player);

    channel.fire('rifaat');
    await Future<void>.delayed(Duration.zero);

    expect(player.played, ['/fake/adhan/rifaat.mp3']);
  });

  test('does nothing for a recording that is not on the phone', () async {
    final channel = _FakeFullAdhanChannel();
    final library = FakeAdhanLibrary();
    final player = FakeAdhanPlayer();
    FullAdhanCoordinator(channel: channel, library: library, player: player);

    channel.fire('gone');
    await Future<void>.delayed(Duration.zero);

    expect(player.played, isEmpty);
  });

  test('plays at full volume by default, or at the given volume', () async {
    final channel = _FakeFullAdhanChannel();
    final library = FakeAdhanLibrary()..have.add('rifaat');
    final player = FakeAdhanPlayer();
    FullAdhanCoordinator(channel: channel, library: library, player: player);
    channel.fire('rifaat');
    await Future<void>.delayed(Duration.zero);
    expect(player.volumes, [1]);

    final quiet = _FakeFullAdhanChannel();
    FullAdhanCoordinator(
      channel: quiet,
      library: library,
      player: player,
      volume: () async => 0.5,
    );
    quiet.fire('rifaat');
    await Future<void>.delayed(Duration.zero);
    expect(player.volumes, [1, 0.5]);
  });
}
