import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_player.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';
import 'package:mynewapp/features/adhan_sounds/presentation/state/adhan_sounds_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/reminders_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The adhan recordings the user can download and play in the app; where the phone supports it
/// (Android 10 and later), also use as the sound of the prayer-time reminders, or delete. Opened
/// from Reminders, with that page's cubits.
class AdhanSoundsPage extends StatelessWidget {
  const AdhanSoundsPage({super.key, required this.library, this.player});

  /// Given by the page that opens this one: a new route does not see the app's own providers.
  final AdhanLibrary library;

  /// Builds the in-app player; null plays nothing (used where [library] came with no player, or
  /// in tests that do not exercise playback).
  final AdhanPlayer Function()? player;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdhanSoundsCubit(library, player?.call())..load(),
      child: const _AdhanSoundsView(),
    );
  }
}

class _AdhanSoundsView extends StatelessWidget {
  const _AdhanSoundsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = AppTypography.of(context);
    final arabic = l10n.localeName.startsWith('ar');
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adhanTitle)),
      body: ContentWidth(
        child: BlocBuilder<AdhanSoundsCubit, AdhanSoundsState>(
          builder: (context, state) => BlocBuilder<PrayerCubit, PrayerState>(
            builder: (context, prayer) {
              final reminders = prayer.preferences.reminders;
              final remindersCubit = context.read<RemindersCubit>();
              final chosen = reminders.adhanId;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(l10n.adhanIntro, style: type.body),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.adhanPrayerOnly, style: type.meta),
                  const SizedBox(height: AppSpacing.lg),
                  // Applies to playing a recording in the app (the preview below, and iOS's "Full
                  // adhan"), not to a downloaded recording used as Android's notification sound,
                  // which follows the phone's own volume.
                  Text(l10n.adhanVolume, style: type.meta),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Semantics(
                          label: l10n.adhanVolume,
                          child: Slider(
                            value: reminders.adhanVolume,
                            label: context.digits.localize(
                              '${(reminders.adhanVolume * 100).round()}%',
                            ),
                            semanticFormatterCallback: (value) => context.digits
                                .localize('${(value * 100).round()}%'),
                            onChanged: remindersCubit.setAdhanVolume,
                          ),
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.loaded && !state.supported) ...[
                    StatusBanner(
                      message: l10n.adhanNoReminderSound,
                      kind: StatusKind.warning,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  for (final item in state.items) ...[
                    _AdhanTile(
                      item: item,
                      arabic: arabic,
                      inUse: chosen == item.sound.id,
                      canUseAsReminder: state.supported,
                      playing: state.playingId == item.sound.id,
                      volume: reminders.adhanVolume,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (state.supported) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.adhanTestHint(l10n.remindersTest),
                      style: type.meta,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.adhanSourceLine(adhanSource), style: type.meta),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdhanTile extends StatelessWidget {
  const _AdhanTile({
    required this.item,
    required this.arabic,
    required this.inUse,
    required this.canUseAsReminder,
    required this.playing,
    required this.volume,
  });

  final AdhanItem item;
  final bool arabic;
  final bool inUse;

  /// Whether this phone can use a downloaded recording as a notification sound at all. When
  /// false, "Use this adhan" is not offered, but the recording can still be played in the app.
  final bool canUseAsReminder;

  /// Whether this recording is playing in the app right now.
  final bool playing;

  /// How loud the preview plays: the user's saved adhan volume.
  final double volume;

  String _size(BuildContext context) {
    final mb = item.sound.bytes / (1024 * 1024);
    final digits = context.digits;
    final text = digits.localize(mb.toStringAsFixed(1));
    return context.l10n.adhanSize(
      digits.arabicIndic ? text.replaceAll('.', '٫') : text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = AppTypography.of(context);
    final scheme = Theme.of(context).colorScheme;
    final place = item.sound.place(arabic);
    final reminders = context.read<RemindersCubit>();
    final cubit = context.read<AdhanSoundsCubit>();
    final failure = item.failure;
    final Widget action = switch (item.status) {
      AdhanStatus.missing => Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilledButton.tonalIcon(
          onPressed: () => cubit.download(item.sound),
          icon: const Icon(Icons.download_rounded),
          label: Text(l10n.adhanDownload(_size(context))),
        ),
      ),
      AdhanStatus.downloading => Semantics(
        label: l10n.adhanDownloading,
        value: '${(item.progress * 100).round()}%',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: item.progress == 0 ? null : item.progress,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.adhanDownloading, style: type.meta),
          ],
        ),
      ),
      AdhanStatus.ready => Row(
        children: [
          Expanded(
            child: !canUseAsReminder
                ? const SizedBox.shrink()
                : inUse
                ? Row(
                    children: [
                      Icon(Icons.check_circle, color: scheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.adhanInUse, style: type.label),
                    ],
                  )
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton(
                      onPressed: () => reminders.setAdhan(item.sound.id),
                      child: Text(l10n.adhanUse),
                    ),
                  ),
          ),
          IconButton(
            tooltip: playing ? l10n.adhanStop : l10n.adhanPlay,
            icon: Icon(
              playing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            ),
            onPressed: () => cubit.preview(item.sound.id, volume: volume),
          ),
          IconButton(
            tooltip: l10n.adhanDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (inUse) await reminders.setAdhan(null);
              await cubit.delete(item.sound.id);
            },
          ),
        ],
      ),
    };
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      emphasized: inUse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.sound.name(arabic), style: type.label),
          if (place != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(place, style: type.meta),
          ],
          const SizedBox(height: AppSpacing.md),
          action,
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure == AdhanDownloadFailure.network
                  ? l10n.adhanFailedNetwork
                  : failure == AdhanDownloadFailure.notAudio
                  ? l10n.adhanFailedFile
                  : l10n.adhanUnsupported,
              style: type.meta.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
