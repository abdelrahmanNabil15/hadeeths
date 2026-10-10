import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';
import 'package:mynewapp/core/widgets/switch_row.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/reminders_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/widgets/time_of_day_tile.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Quiet hours: a daily period on the phone's clock in which salawat reminders are not sent. Prayer
/// reminders always arrive; with the second switch they arrive silently in that period. The page
/// always says how many reminders quiet hours are holding back.
class QuietHoursPage extends StatefulWidget {
  const QuietHoursPage({super.key});

  @override
  State<QuietHoursPage> createState() => _QuietHoursPageState();
}

class _QuietHoursPageState extends State<QuietHoursPage> {
  @override
  void initState() {
    super.initState();
    // Plan once on opening, so the count of held-back reminders is current.
    context.read<RemindersCubit>().refreshPlan();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final cubit = context.read<RemindersCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quietTitle)),
      body: ContentWidth(
        child: BlocBuilder<PrayerCubit, PrayerState>(
          builder: (context, prayerState) {
            final r = prayerState.preferences.reminders;
            return BlocBuilder<RemindersCubit, RemindersState>(
              builder: (context, state) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(l10n.quietIntro, style: AppTypography.of(context).meta),
                  const SizedBox(height: AppSpacing.md),
                  SwitchRow(
                    title: l10n.quietSwitch,
                    value: r.quietEnabled,
                    onChanged: state.busy
                        ? null
                        : (on) => cubit.setQuiet(enabled: on),
                  ),
                  if (r.quietEnabled) ...[
                    const SizedBox(height: AppSpacing.md),
                    StatusBanner(
                      message: digits.localize(
                        l10n.quietHeldBack(state.status.heldBackByQuietHours),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeading(l10n.salawatWindow),
                  const SizedBox(height: AppSpacing.sm),
                  TimeOfDayTile(
                    label: l10n.timeFrom,
                    minute: r.quietStartMinute,
                    onChanged: (m) => cubit.setQuiet(startMinute: m),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TimeOfDayTile(
                    label: l10n.timeTo,
                    minute: r.quietEndMinute,
                    onChanged: (m) => cubit.setQuiet(endMinute: m),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SwitchRow(
                    title: l10n.quietPrayersSilent,
                    value: r.quietForPrayers,
                    onChanged: state.busy
                        ? null
                        : (on) => cubit.setQuiet(forPrayers: on),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
