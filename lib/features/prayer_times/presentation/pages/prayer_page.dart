import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/clock_format.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/prayer_times/domain/method_suggestion.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/presentation/countdown_text.dart';
import 'package:mynewapp/features/prayer_times/presentation/date_labels.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/hijri_page.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/method_page.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/qibla_page.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/reminders_page.dart';
import 'package:mynewapp/features/prayer_times/presentation/prayer_labels.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/widgets/prayer_countdown.dart';
import 'package:mynewapp/features/prayer_times/presentation/widgets/prayer_setup_view.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The prayer section's first screen: today's times at the chosen place, or the setup when no
/// place is chosen yet.
class PrayerPage extends StatelessWidget {
  const PrayerPage({super.key, required this.services});

  final PrayerServices services;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<PrayerServices>.value(
      value: services,
      child: BlocProvider(
        create: (_) => PrayerCubit(services)..load(),
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.prayerTimesTitle)),
          body: BlocBuilder<PrayerCubit, PrayerState>(
            // Each state has its own key, so a change fades; the new state is usable at once.
            builder: (context, state) => AnimatedStateSwitcher(
              child: switch (state.status) {
                PrayerStatus.loading => const LoadingView(
                  key: ValueKey('loading'),
                ),
                PrayerStatus.needsSetup => const PrayerSetupView(
                  key: ValueKey('setup'),
                ),
                PrayerStatus.ready => const _TimesView(key: ValueKey('ready')),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TimesView extends StatelessWidget {
  const _TimesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final digits = context.digits;
    final arabic = context.apiLanguage == 'ar';
    final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
    return BlocBuilder<PrayerCubit, PrayerState>(
      builder: (context, state) {
        final day = state.today;
        final zone = state.zone;
        final place = state.preferences.location!;
        String clock(DateTime utc) => formatClock(
          zone!.wallClockAt(utc),
          arabic: arabic,
          use24Hour: use24Hour,
          digits: digits,
        );
        return ContentWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Icon(Icons.place_outlined, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      place.name ?? l10n.currentLocation,
                      style: TextStyle(
                        fontSize: AppTextSize.heading,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    appRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PrayerCubit>(),
                        child: RepositoryProvider.value(
                          value: context.read<PrayerServices>(),
                          child: const _ChangeLocationPage(),
                        ),
                      ),
                    ),
                  ),
                  child: Text(l10n.changeLocation),
                ),
              ),
              if (day != null) ...[
                Text(
                  gregorianDateText(l10n, digits, day.date),
                  style: TextStyle(
                    fontSize: AppTextSize.body,
                    color: scheme.onSurface,
                  ),
                ),
                if (state.hijriDate != null)
                  Text(
                    hijriDateText(l10n, digits, state.hijriDate!),
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (day == null || state.calculationFailed)
                SizedBox(
                  height: 200,
                  child: EmptyView(
                    message: l10n.calculationFailed,
                    icon: Icons.wb_twilight,
                  ),
                )
              else ...[
                if (state.moment != null)
                  // Ticks once a second while the page can be seen; at zero (and when the page is
                  // seen again) the page recalculates, which moves on to the following prayer.
                  PrayerCountdown(
                    nextAt: state.moment!.nextAt,
                    clock: context.read<PrayerServices>().clock,
                    onReachedZero: context.read<PrayerCubit>().refresh,
                    onResumed: context.read<PrayerCubit>().refresh,
                    builder: (context, remaining) => _NextBanner(
                      label: l10n.nextPrayerLabel,
                      name: prayerName(l10n, state.moment!.next),
                      time: clock(state.moment!.nextAt),
                      countdown: l10n.countdownIn(
                        countdownClock(remaining, digits),
                      ),
                      countdownSpoken: countdownSpoken(l10n, remaining, digits),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                for (final prayer in Prayer.values) ...[
                  _TimeRow(
                    name: prayerName(l10n, prayer),
                    time: clock(day[prayer]),
                    isNext: state.moment?.next == prayer,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              SectionHeading(l10n.methodHeading),
              const SizedBox(height: AppSpacing.sm),
              AppTile(
                title: methodName(l10n, state.preferences.settings.method),
                pressFeedback: true,
                onTap: () => Navigator.of(context).push(
                  appRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: context.read<PrayerCubit>(),
                      child: const MethodPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${methodDetail(l10n, digits, state.preferences.settings.method)}\n'
                '${_origin(l10n, state.preferences)}',
                style: TextStyle(
                  fontSize: AppTextSize.meta,
                  height: AppLineHeight.body,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTile(
                title: l10n.remindersHeading,
                pressFeedback: true,
                onTap: () => _open(context, const RemindersPage()),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTile(
                title: l10n.qiblaHeading,
                pressFeedback: true,
                onTap: () => _open(context, const QiblaPage()),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTile(
                title: l10n.hijriHeading,
                pressFeedback: true,
                onTap: () => _open(context, const HijriPage()),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.prayerDisclaimer,
                style: TextStyle(
                  fontSize: AppTextSize.meta,
                  height: AppLineHeight.body,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens a sub-page that shares this screen's state.
  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      appRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<PrayerCubit>(),
          child: RepositoryProvider.value(
            value: context.read<PrayerServices>(),
            child: page,
          ),
        ),
      ),
    );
  }

  static String _origin(AppLocalizations l10n, PrayerPreferences p) {
    switch (p.methodOrigin) {
      case MethodOrigin.user:
        return l10n.methodByYou;
      case MethodOrigin.suggested:
        final specific = MethodSuggestion.forCountry(
          p.location?.countryCode,
        ).isCountrySpecific;
        return specific ? l10n.methodAutoCountry : l10n.methodAutoGeneral;
      case MethodOrigin.notSet:
        return '';
    }
  }
}

class _NextBanner extends StatelessWidget {
  const _NextBanner({
    required this.label,
    required this.name,
    required this.time,
    required this.countdown,
    required this.countdownSpoken,
  });

  final String label;
  final String name;
  final String time;

  /// Time left as a clock face, updated every second.
  final String countdown;

  /// Time left in words, to the minute: what a screen reader hears.
  final String countdownSpoken;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final type = AppTypography.of(context);
    // The same midnight-emerald panel and faint lattice as the home header, so the most important
    // fact on the page reads as its headline.
    return Semantics(
      container: true,
      label: '$label: $name, $time, $countdownSpoken',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ColoredBox(
          color: colors.hero,
          child: Stack(
            children: [
              Positioned.fill(
                child: GeometricPattern(
                  color: colors.heroAccent.withValues(alpha: 0.08),
                  tileSize: 44,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg + AppSpacing.xs,
                  vertical: AppSpacing.lg,
                ),
                // A Wrap, not a Row: with very large text the time moves under the name instead of
                // running out of the box.
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: type.label.copyWith(
                              color: colors.heroAccent,
                            ),
                          ),
                          Text(
                            name,
                            style: type.editorial.copyWith(
                              color: colors.onHero,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: type.number.copyWith(
                              fontSize: AppTextSize.title,
                              fontWeight: FontWeight.w700,
                              color: colors.onHero,
                            ),
                          ),
                          Text(
                            countdown,
                            style: type.number.copyWith(
                              fontSize: AppTextSize.meta,
                              fontWeight: FontWeight.w500,
                              color: colors.onHeroMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.name,
    required this.time,
    required this.isNext,
  });

  final String name;
  final String time;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$name, $time',
      excludeSemantics: true,
      // The next prayer's emphasis (border and weight) eases in when the next prayer changes. It
      // is also fully visible with no animation, so nothing depends on the movement.
      child: AnimatedContainer(
        duration: context.motion(AppMotion.medium),
        curve: AppMotion.standard,
        constraints: const BoxConstraints(minHeight: AppSizes.minTileHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isNext ? scheme.primary : scheme.outlineVariant,
            width: isNext ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: AppTextSize.body + 1,
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Text(
              time,
              // Equal-width digits where the font has them, so times line up down the list.
              style: AppTypography.of(context).number.copyWith(
                fontSize: AppTextSize.body + 1,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The setup, reached from "Change location". Closes itself once a new place has been set.
class _ChangeLocationPage extends StatelessWidget {
  const _ChangeLocationPage();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrayerCubit, PrayerState>(
      listenWhen: (previous, current) =>
          previous.preferences.location != current.preferences.location,
      listener: (context, state) => Navigator.of(context).maybePop(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.changeLocation)),
        body: const PrayerSetupView(),
      ),
    );
  }
}
