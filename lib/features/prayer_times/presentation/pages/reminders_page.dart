import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/clock_format.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/option_group.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/switch_row.dart';
import 'package:mynewapp/features/prayer_times/domain/place_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/prayer_labels.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/reminders_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Choose which prayer times get a reminder, how long before, and how it sounds.
class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RemindersCubit(
        prayer: context.read<PrayerCubit>(),
        services: context.read<PrayerServices>(),
      )..load(),
      child: const _RemindersScaffold(),
    );
  }
}

class _RemindersScaffold extends StatefulWidget {
  const _RemindersScaffold();

  @override
  State<_RemindersScaffold> createState() => _RemindersScaffoldState();
}

class _RemindersScaffoldState extends State<_RemindersScaffold>
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

  /// Coming back from the system settings: look at the permission again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RemindersCubit>().load();
    }
  }

  Future<bool> _explainExact() async {
    final l10n = context.l10n;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.remindersExactExplainTitle),
        content: Text(l10n.remindersExactExplainBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.continueAction),
          ),
        ],
      ),
    );
    return agreed ?? false;
  }

  Future<bool> _explain() async {
    final l10n = context.l10n;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.remindersExplainTitle),
        content: Text(l10n.remindersExplainBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.continueAction),
          ),
        ],
      ),
    );
    return agreed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final digits = context.digits;
    final cubit = context.read<RemindersCubit>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersHeading)),
      body: ContentWidth(
        child: BlocBuilder<PrayerCubit, PrayerState>(
          builder: (context, prayerState) {
            final settings = prayerState.preferences.reminders;
            return BlocBuilder<RemindersCubit, RemindersState>(
              builder: (context, state) {
                final denied =
                    settings.enabled &&
                    state.permission != null &&
                    state.permission != PermissionState.granted;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    SwitchRow(
                      title: l10n.remindersSwitch,
                      subtitle: _summary(
                        context,
                        settings,
                        state,
                        prayerState,
                        digits,
                      ),
                      value: settings.enabled,
                      onChanged: state.busy
                          ? null
                          : (on) => cubit.setEnabled(on, explain: _explain),
                    ),
                    ..._messages(context, state, denied, settings),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeading(l10n.remindersWhich),
                    const SizedBox(height: AppSpacing.sm),
                    for (final prayer in Prayer.values) ...[
                      SwitchRow(
                        title: prayerName(l10n, prayer),
                        value: settings.prayers.contains(prayer),
                        onChanged: state.busy
                            ? null
                            : (on) => cubit.setPrayer(prayer, on: on),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeading(l10n.remindersLead),
                    const SizedBox(height: AppSpacing.sm),
                    OptionGroup<int>(
                      selected: settings.leadMinutes,
                      onSelected: cubit.setLead,
                      options: [
                        for (final m in ReminderSettings.leadOptions)
                          (
                            m,
                            m == 0
                                ? l10n.remindersLeadNone
                                : digits.localize(l10n.remindersLeadMinutes(m)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (isAndroid) ...[
                      SectionHeading(l10n.remindersExact),
                      const SizedBox(height: AppSpacing.sm),
                      SwitchRow(
                        title: l10n.remindersExact,
                        subtitle: l10n.remindersExactHint,
                        value: settings.exactTiming,
                        onChanged: state.busy
                            ? null
                            : (on) =>
                                  cubit.setExact(on, explain: _explainExact),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    SectionHeading(l10n.remindersSound),
                    const SizedBox(height: AppSpacing.sm),
                    OptionGroup<NotificationSound>(
                      selected: settings.sound,
                      onSelected: cubit.setSound,
                      options: [
                        (NotificationSound.system, l10n.remindersSoundSystem),
                        (NotificationSound.silent, l10n.remindersSoundSilent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchRow(
                      title: l10n.remindersVibrate,
                      value: settings.vibrate,
                      onChanged: (on) => cubit.setVibrate(on: on),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    OutlinedButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => cubit.sendTest(explain: _explain),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(l10n.remindersTest),
                    ),
                    if (isAndroid && !settings.exactTiming) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.remindersTiming,
                        style: TextStyle(
                          fontSize: AppTextSize.meta,
                          height: AppLineHeight.body,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// "Reminders are off", or how many are scheduled and which comes next.
  String _summary(
    BuildContext context,
    ReminderSettings settings,
    RemindersState state,
    PrayerState prayerState,
    Digits digits,
  ) {
    final l10n = context.l10n;
    if (!settings.enabled) return l10n.remindersOff;
    final count = digits.localize(l10n.remindersCount(state.scheduled));
    final next = state.next;
    final place = prayerState.preferences.location;
    if (next == null || place == null) return count;
    final zone = zoneForPlace(place);
    final time = formatClock(
      zone.wallClockAt(
        next.fireAt.add(Duration(minutes: settings.leadMinutes)),
      ),
      arabic: context.apiLanguage == 'ar',
      use24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
      digits: digits,
    );
    final prayerLabel = prayerName(l10n, Prayer.values.byName(next.key));
    return '$count\n${l10n.remindersNext(prayerLabel, time)}';
  }

  List<Widget> _messages(
    BuildContext context,
    RemindersState state,
    bool denied,
    ReminderSettings settings,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<RemindersCubit>();
    String? text;
    var offerSettings = false;
    if (state.problem == ReminderProblem.needsPlace) {
      text = l10n.remindersNeedPlace;
    } else if (state.problem == ReminderProblem.denied ||
        state.problem == ReminderProblem.needsSettings ||
        denied) {
      text = l10n.remindersDenied;
      offerSettings = true;
    } else if (state.problem == ReminderProblem.exactNotAllowed ||
        (settings.exactTiming && state.status.exactDenied)) {
      text = l10n.remindersExactMissing;
      offerSettings = true;
    } else if (state.problem == ReminderProblem.unavailable) {
      text = l10n.locationUnavailable;
    } else if (state.status.failed > 0) {
      text = l10n.remindersFailed;
    }
    if (text == null) return const [];
    return [
      const SizedBox(height: AppSpacing.md),
      Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: AppTextSize.body,
                  height: AppLineHeight.body,
                  color: scheme.onSurface,
                ),
              ),
              if (offerSettings)
                TextButton(
                  onPressed: cubit.openSettings,
                  child: Text(l10n.openSettings),
                ),
            ],
          ),
        ),
      ),
    ];
  }
}
