import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';
import 'package:mynewapp/core/widgets/switch_row.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/presentation/date_labels.dart';
import 'package:mynewapp/features/prayer_times/presentation/prayer_labels.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';
import 'package:mynewapp/features/tracker/domain/prayer_log_repository.dart';
import 'package:mynewapp/features/tracker/presentation/state/tracker_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Mark which of the five prayers were prayed, for today and the six days before. Everything stays
/// on the phone. There are no streaks, scores or reminders to "catch up": a day simply shows what
/// was marked.
class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key, required this.log, required this.services});

  final PrayerLogRepository log;
  final PrayerServices services;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackerCubit(log: log, services: services)..load(),
      child: const _TrackerScaffold(),
    );
  }
}

class _TrackerScaffold extends StatefulWidget {
  const _TrackerScaffold();

  @override
  State<_TrackerScaffold> createState() => _TrackerScaffoldState();
}

class _TrackerScaffoldState extends State<_TrackerScaffold>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back in front, possibly after midnight: look at the date again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TrackerCubit>().load();
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final cubit = context.read<TrackerCubit>();
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.trackerDeleteTitle),
        content: Text(l10n.trackerDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trackerDeleteConfirm),
          ),
        ],
      ),
    );
    if (agreed ?? false) await cubit.deleteAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trackerTitle)),
      body: ContentWidth(
        child: BlocBuilder<TrackerCubit, TrackerState>(
          builder: (context, state) {
            switch (state.status) {
              case TrackerStatus.loading:
                return const LoadingView();
              case TrackerStatus.unavailable:
                return EmptyView(
                  message: l10n.trackerUnavailable,
                  icon: Icons.storage_outlined,
                );
              case TrackerStatus.ready:
                return _Ready(state: state, onDelete: _confirmDelete);
            }
          },
        ),
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state, required this.onDelete});

  final TrackerState state;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final cubit = context.read<TrackerCubit>();
    final type = AppTypography.of(context);
    final selected = state.selected!;
    final total = TrackerState.prayers.length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.trackerIntro, style: type.meta),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final day in state.days)
              _DayChip(
                day: day,
                isToday: day == state.today,
                isSelected: day == selected,
                marked: state.doneOn(day).length,
                total: total,
                onTap: () => cubit.select(day),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(gregorianDateText(l10n, digits, selected.date)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.trackerCount(
            digits.format(state.doneOn(selected).length),
            digits.format(total),
          ),
          style: type.meta,
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.saveFailed) ...[
          StatusBanner(
            message: l10n.trackerSaveFailed,
            kind: StatusKind.warning,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final prayer in TrackerState.prayers) ...[
          SwitchRow(
            title: prayerName(l10n, prayer),
            value: state.doneOn(selected).contains(prayer),
            onChanged: (on) => cubit.toggle(prayer, on: on),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.trackerDelete),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.marked,
    required this.total,
    required this.onTap,
  });

  final DayKey day;
  final bool isToday;
  final bool isSelected;
  final int marked;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final scheme = Theme.of(context).colorScheme;
    final name = isToday ? l10n.trackerToday : weekdayName(l10n, day.weekday);
    final label = '$name ${digits.format(day.day)}';
    final count = '${digits.format(marked)}/${digits.format(total)}';
    final background = isSelected
        ? scheme.primaryContainer
        : scheme.surfaceContainerLowest;
    final foreground = isSelected
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: l10n.trackerDayLabel(
        label,
        digits.format(marked),
        digits.format(total),
      ),
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motion(AppMotion.short),
        curve: AppMotion.standard,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTouchTarget,
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTextSize.meta,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                  Text(
                    count,
                    style: AppTypography.of(context).number.copyWith(
                      fontSize: AppTextSize.meta,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
