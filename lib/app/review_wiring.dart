import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/app/review_coordinator.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/prayer_times/domain/place_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_moment.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';

/// How long before a prayer, and after it began, the user is left alone.
const _beforePrayer = Duration(minutes: 10);
const _afterPrayerBegan = Duration(minutes: 20);

/// Whether a prayer is due: about to begin, or only just begun, at the saved place. False when
/// there is no place or the times cannot be worked out (nothing is guessed).
Future<bool> prayerIsDue(PrayerServices services) async {
  try {
    final preferences = await services.preferences.load();
    final place = preferences.location;
    if (place == null) return false;
    final now = services.clock.now();
    final result = services.calculator.calculate(
      location: place.point,
      date: zoneForPlace(place).localDateAt(now),
      settings: preferences.settings,
    );
    if (result is! Success<PrayerDay>) return false;
    final moment = PrayerMoment.at(result.value, now);
    final justBegan =
        moment.current.isPrayer &&
        now.difference(moment.currentStartedAt) < _afterPrayerBegan;
    final soon = moment.next.isPrayer && moment.remaining(now) <= _beforePrayer;
    return justBegan || soon;
  } on Object {
    return false;
  }
}

/// The places nothing should interrupt: a due prayer, and an adhan download under way. Prayer
/// reminders are covered by the due-prayer window (a reminder is a minutes-before or at-the-time
/// notification of the same prayer).
Future<bool> Function() reviewCanInterrupt({PrayerServices? prayer}) =>
    () async {
      if (prayer == null) return true;
      if (prayer.adhan?.downloading ?? false) return false;
      return !await prayerIsDue(prayer);
    };

/// Tells the rating logic that the user is back on the hadith home screen. Only the first page of
/// the navigator it watches counts, and only when the page has finished loading its content
/// (a home screen showing an error or still loading is somewhere the user is recovering).
class HomeReturnObserver extends NavigatorObserver {
  HomeReturnObserver(this._onHome);

  final VoidCallback _onHome;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && previousRoute.isFirst) _onHome();
  }
}

/// Whether the hadith home screen is calm: its categories loaded without trouble.
bool homeIsCalm(BuildContext? context) {
  if (context == null || !context.mounted) return false;
  try {
    return context.read<CategoriesCubit>().state.status == LoadStatus.success;
  } on Object {
    return false;
  }
}

/// Asks the coordinator at the end of the current frame, once the page has settled, if the home
/// screen is calm.
void requestOnHomeReturn(ReviewCoordinator? coordinator, BuildContext? home) {
  if (coordinator == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (homeIsCalm(home)) coordinator.maybeRequest().ignore();
  });
}
