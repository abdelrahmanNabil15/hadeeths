import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/option_group.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';
import 'package:mynewapp/core/widgets/switch_row.dart';
import 'package:mynewapp/features/prayer_times/domain/salawat_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/notification_explain.dart';
import 'package:mynewapp/features/prayer_times/presentation/salawat_wording.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/reminders_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/widgets/time_of_day_tile.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Salawat reminders: on or off, how often, between which times, and an optional earlier reminder.
/// The reminder text is the owner-approved Arabic, shown here as it will appear.
class SalawatPage extends StatelessWidget {
  const SalawatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final cubit = context.read<RemindersCubit>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.salawatTitle)),
      body: ContentWidth(
        child: BlocBuilder<PrayerCubit, PrayerState>(
          builder: (context, prayerState) {
            final s = prayerState.preferences.reminders.salawat;
            return BlocBuilder<RemindersCubit, RemindersState>(
              builder: (context, state) {
                void setWindow({int? start, int? end}) {
                  final from = start ?? s.windowStartMinute;
                  final to = end ?? s.windowEndMinute;
                  if (to <= from) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.windowInvalid)),
                      );
                    return;
                  }
                  cubit.setSalawat(
                    s.copyWith(windowStartMinute: from, windowEndMinute: to),
                  );
                }

                final refused =
                    state.problem == ReminderProblem.denied ||
                    state.problem == ReminderProblem.needsSettings;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      l10n.salawatIntro,
                      style: AppTypography.of(context).meta,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchRow(
                      title: l10n.salawatSwitch,
                      value: s.enabled,
                      onChanged: state.busy
                          ? null
                          : (on) => cubit.setSalawatEnabled(
                              on,
                              explain: () => explainNotifications(context),
                            ),
                    ),
                    if (refused) ...[
                      const SizedBox(height: AppSpacing.md),
                      StatusBanner(
                        message: l10n.remindersDenied,
                        kind: StatusKind.warning,
                        actionLabel: l10n.openSettings,
                        onAction: cubit.openSettings,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeading(l10n.salawatPreview),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        salawatNowText,
                        textDirection: TextDirection.rtl,
                        style: AppTypography.of(context).body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeading(l10n.salawatInterval),
                    const SizedBox(height: AppSpacing.sm),
                    OptionGroup<int>(
                      selected: s.intervalMinutes,
                      onSelected: (m) =>
                          cubit.setSalawat(s.copyWith(intervalMinutes: m)),
                      options: [
                        for (final m in SalawatSettings.intervalOptions)
                          (m, digits.localize(l10n.salawatEveryHours(m ~/ 60))),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeading(l10n.salawatWindow),
                    const SizedBox(height: AppSpacing.sm),
                    TimeOfDayTile(
                      label: l10n.timeFrom,
                      minute: s.windowStartMinute,
                      onChanged: (m) => setWindow(start: m),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TimeOfDayTile(
                      label: l10n.timeTo,
                      minute: s.windowEndMinute,
                      onChanged: (m) => setWindow(end: m),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeading(l10n.remindersLead),
                    const SizedBox(height: AppSpacing.sm),
                    OptionGroup<int>(
                      selected: s.leadMinutes,
                      onSelected: (m) =>
                          cubit.setSalawat(s.copyWith(leadMinutes: m)),
                      options: [
                        for (final m in SalawatSettings.leadOptions)
                          (
                            m,
                            m == 0
                                ? l10n.salawatLeadNone
                                : digits.localize(l10n.remindersLeadMinutes(m)),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
