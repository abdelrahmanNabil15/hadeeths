import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_audio_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

String _clock(Digits digits, Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds.remainder(60);
  return digits.localize('$minutes:${seconds.toString().padLeft(2, '0')}');
}

/// A bar docked at the bottom of the reader once a verse has started playing: play/pause,
/// previous/next verse, elapsed and remaining time, and a close button. Foreground playback
/// only -- see `docs/QURAN_API_REFACTOR_PLAN.md` flag D. Shows nothing ([SizedBox.shrink]) until
/// something has been played.
class AudioMiniPlayer extends StatelessWidget {
  const AudioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranAudioCubit>().state;
    if (state.status == AudioPlaybackStatus.idle) {
      return const SizedBox.shrink();
    }
    final cubit = context.read<QuranAudioCubit>();
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: state.status == AudioPlaybackStatus.failure
              ? _FailureRow(
                  failure: state.failure!,
                  onRetry: cubit.retry,
                  onClose: cubit.stop,
                )
              : _TransportRow(state: state, cubit: cubit),
        ),
      ),
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({required this.state, required this.cubit});

  final QuranAudioState state;
  final QuranAudioCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final verse = state.verse;
    final duration = state.duration;
    final remaining = duration == null ? null : duration - state.position;
    final loading = state.status == AudioPlaybackStatus.loading;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.quranAudioPrevious,
          icon: const Icon(Icons.skip_previous),
          onPressed: cubit.hasPrevious ? cubit.previous : null,
        ),
        IconButton(
          tooltip: state.status == AudioPlaybackStatus.playing
              ? l10n.quranAudioPause
              : l10n.quranAudioPlay,
          icon: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  state.status == AudioPlaybackStatus.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
          onPressed: switch (state.status) {
            AudioPlaybackStatus.playing => cubit.pause,
            AudioPlaybackStatus.paused => cubit.resume,
            AudioPlaybackStatus.loading || AudioPlaybackStatus.failure => null,
            AudioPlaybackStatus.idle => null,
          },
        ),
        IconButton(
          tooltip: l10n.quranAudioNext,
          icon: const Icon(Icons.skip_next),
          onPressed: cubit.hasNext ? cubit.next : null,
        ),
        Expanded(
          child: verse == null
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quranVerseLabel(digits.format(verse.verse)),
                      style: AppTypography.of(context).label,
                    ),
                    if (duration != null)
                      Text(
                        '${_clock(digits, state.position)} / '
                        '-${_clock(digits, remaining!)}',
                        style: AppTypography.of(context).meta,
                      ),
                  ],
                ),
        ),
        IconButton(
          tooltip: l10n.quranAudioStop,
          icon: const Icon(Icons.close),
          onPressed: cubit.stop,
        ),
      ],
    );
  }
}

class _FailureRow extends StatelessWidget {
  const _FailureRow({
    required this.failure,
    required this.onRetry,
    required this.onClose,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              failureMessage(l10n, failure),
              style: AppTypography.of(context).meta,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.retry,
          icon: const Icon(Icons.refresh),
          onPressed: onRetry,
        ),
        IconButton(
          tooltip: l10n.quranAudioStop,
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }
}
