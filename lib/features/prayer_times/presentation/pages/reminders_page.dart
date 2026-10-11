import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/clock_format.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/option_group.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';
import 'package:mynewapp/core/widgets/switch_row.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';
import 'package:mynewapp/features/adhan_sounds/presentation/pages/adhan_sounds_page.dart';
import 'package:mynewapp/features/prayer_times/domain/place_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/notification_explain.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/quiet_hours_page.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/salawat_page.dart';
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

/// How the reminders sound in the choice shown on the page. The adhan is one of the system-sound
/// settings (a downloaded recording in place of the system sound).
enum _SoundChoice { system, adhan, silent }

class _RemindersScaffoldState extends State<_RemindersScaffold>
    with WidgetsBindingObserver {
  /// Whether downloaded adhan recordings can be used on this phone (Android 10 and later, with the
  /// feature on). Asked once.
  late final Future<bool> _adhanSupported =
      context.read<PrayerServices>().adhan?.isSupported() ??
      Future<bool>.value(false);

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

  Future<bool> _explain() => explainNotifications(context);

  void _openAdhan() {
    final library = context.read<PrayerServices>().adhan;
    if (library != null) _openSub(AdhanSoundsPage(library: library));
  }

  /// Opens a reminders sub-page that shares this page's state.
  void _openSub(Widget page) {
    Navigator.of(context).push(
      appRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<PrayerCubit>()),
            BlocProvider.value(value: context.read<RemindersCubit>()),
          ],
          child: page,
        ),
      ),
    );
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
                    if (settings.leadMinutes > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.remindersNearHint,
                        style: AppTypography.of(context).meta,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeading(l10n.wakeUpHeading),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchRow(
                      title: l10n.wakeUpSwitch,
                      subtitle: l10n.wakeUpHint,
                      value: settings.wakeUp,
                      onChanged: state.busy
                          ? null
                          : (on) => cubit.setWakeUp(on: on),
                    ),
                    if (settings.wakeUp) ...[
                      const SizedBox(height: AppSpacing.md),
                      OptionGroup<int>(
                        selected: settings.wakeUpMinutes,
                        onSelected: cubit.setWakeUpMinutes,
                        options: [
                          for (final m in ReminderSettings.wakeUpOptions)
                            (m, digits.localize(l10n.wakeUpBefore(m))),
                        ],
                      ),
                      if (isAndroid && !settings.exactTiming) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.wakeUpExactHint(l10n.remindersExact),
                          style: AppTypography.of(context).meta,
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeading(l10n.remindersMore),
                    const SizedBox(height: AppSpacing.sm),
                    AppTile(
                      title: l10n.salawatTitle,
                      leadingIcon: Icons.notifications_none_rounded,
                      trailingText: settings.salawat.enabled
                          ? l10n.statusOn
                          : l10n.statusOff,
                      onTap: () => _openSub(const SalawatPage()),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTile(
                      title: l10n.quietTitle,
                      leadingIcon: Icons.bedtime_outlined,
                      trailingText: settings.quietEnabled
                          ? l10n.statusOn
                          : l10n.statusOff,
                      onTap: () => _openSub(const QuietHoursPage()),
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
                    FutureBuilder<bool>(
                      future: _adhanSupported,
                      builder: (context, adhan) {
                        final withAdhan = adhan.data ?? false;
                        final choice =
                            settings.sound == NotificationSound.silent
                            ? _SoundChoice.silent
                            : settings.adhanId != null
                            ? _SoundChoice.adhan
                            : _SoundChoice.system;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OptionGroup<_SoundChoice>(
                              selected: choice,
                              onSelected: (picked) {
                                switch (picked) {
                                  case _SoundChoice.system:
                                    cubit.setSound(NotificationSound.system);
                                  case _SoundChoice.silent:
                                    cubit.setSound(NotificationSound.silent);
                                  case _SoundChoice.adhan:
                                    // Nothing chosen yet: go and choose one.
                                    _openAdhan();
                                }
                              },
                              options: [
                                (
                                  _SoundChoice.system,
                                  l10n.remindersSoundSystem,
                                ),
                                if (withAdhan)
                                  (
                                    _SoundChoice.adhan,
                                    l10n.remindersSoundAdhan,
                                  ),
                                (
                                  _SoundChoice.silent,
                                  l10n.remindersSoundSilent,
                                ),
                              ],
                            ),
                            if (withAdhan && choice == _SoundChoice.adhan) ...[
                              const SizedBox(height: AppSpacing.sm),
                              AppTile(
                                title: l10n.adhanChooseTile,
                                leadingIcon: Icons.graphic_eq,
                                trailingText:
                                    adhanById(
                                      settings.adhanId,
                                    )?.name(l10n.localeName.startsWith('ar')) ??
                                    l10n.adhanNoneChosen,
                                onTap: _openAdhan,
                              ),
                            ],
                          ],
                        );
                      },
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
    // Prayer reminders only: salawat reminders have their own page.
    final count = digits.localize(
      l10n.remindersCount(state.status.scheduledPrayers),
    );
    final next = state.status.nextPrayer;
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
    final cubit = context.read<RemindersCubit>();
    String? text;
    var kind = StatusKind.warning;
    var offerSettings = false;
    if (state.problem == ReminderProblem.needsPlace) {
      text = l10n.remindersNeedPlace;
      kind = StatusKind.info;
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
      kind = StatusKind.error;
    } else if (state.status.failed > 0) {
      text = l10n.remindersFailed;
    }
    if (text == null) return const [];
    return [
      const SizedBox(height: AppSpacing.md),
      StatusBanner(
        message: text,
        kind: kind,
        actionLabel: offerSettings ? l10n.openSettings : null,
        onAction: offerSettings ? cubit.openSettings : null,
      ),
    ];
  }
}
