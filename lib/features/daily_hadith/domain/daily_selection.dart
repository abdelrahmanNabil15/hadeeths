import 'package:mynewapp/core/notifications/notification_planner.dart'
    show fnv1a31;

/// Pure rules for choosing the daily hadith. The same inputs always give the same choice, on every
/// phone and every release, so a day's hadith never changes under the user.

/// `yyyy-MM-dd` for a local calendar date.
String dayKey(DateTime localDate) =>
    '${localDate.year.toString().padLeft(4, '0')}-'
    '${localDate.month.toString().padLeft(2, '0')}-'
    '${localDate.day.toString().padLeft(2, '0')}';

/// Days since 1 January 1970 for a local calendar date (its time fields are ignored).
int dayNumber(DateTime localDate) => DateTime.utc(
  localDate.year,
  localDate.month,
  localDate.day,
).difference(DateTime.utc(1970)).inDays;

/// The categories in the order they are tried on [day]: the pool, sorted, rotated so that each day
/// starts one further along. When there is more than one, yesterday's category goes last, so the
/// same category does not come two days running.
List<String> categoryOrder({
  required int day,
  required Iterable<String> pool,
  String? yesterday,
}) {
  final sorted = pool.toSet().toList()..sort();
  if (sorted.isEmpty) return const [];
  final start = day % sorted.length;
  final order = [...sorted.sublist(start), ...sorted.sublist(0, start)];
  if (yesterday != null && order.length > 1 && order.first == yesterday) {
    order
      ..removeAt(0)
      ..add(yesterday);
  }
  return order;
}

/// A stable position among [count] items for this day, language and category.
int itemIndex({
  required String day,
  required String language,
  required String categoryId,
  required int count,
}) {
  assert(count > 0);
  return fnv1a31('$day|$language|$categoryId') % count;
}

/// From [ids], the first one at or after [start] (wrapping round) that is not in [avoid]; the one
/// at [start] when every id is to be avoided.
int firstNotShown(List<String> ids, int start, Set<String> avoid) {
  for (var step = 0; step < ids.length; step++) {
    final i = (start + step) % ids.length;
    if (!avoid.contains(ids[i])) return i;
  }
  return start;
}
