import 'package:mynewapp/features/tracker/presentation/state/tracker_cubit.dart';

/// The prayers the user newly marked between two states, as keys for the rating logic
/// (`prayer:<day>:<prayer>`).
///
/// Only a change between two loaded states of the same week counts. The first load, a reload after
/// midnight (the week moved, so days enter and leave it), and a change that was taken back after a
/// failed save are not the user marking a prayer.
List<String> newlyMarked(TrackerState previous, TrackerState current) {
  if (previous.status != TrackerStatus.ready ||
      current.status != TrackerStatus.ready ||
      current.saveFailed ||
      previous.days.length != current.days.length) {
    return const [];
  }
  for (var i = 0; i < current.days.length; i++) {
    if (previous.days[i] != current.days[i]) return const [];
  }
  return [
    for (final day in current.days)
      for (final prayer in current.doneOn(day))
        if (!previous.doneOn(day).contains(prayer))
          'prayer:${day.id}:${prayer.name}',
  ];
}
