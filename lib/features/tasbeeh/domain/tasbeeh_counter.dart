import 'package:equatable/equatable.dart';

/// A plain counter: how many times the user has tapped, and an optional target to count towards.
/// It holds no words: the user decides what they are counting.
class TasbeehCounter extends Equatable {
  const TasbeehCounter({this.count = 0, this.target});

  /// The largest count; the counter stops there rather than growing past what the screen can show.
  static const maxCount = 999999;

  /// The targets the user can choose from. No target is also allowed.
  static const targets = <int>[33, 99, 100];

  final int count;

  /// What to count up to, or null for no target.
  final int? target;

  bool get isFull => count >= maxCount;

  /// 0 to 1 within the current round (a full ring on each multiple of the target); 0 with no target.
  double get progress {
    final t = target;
    if (t == null || count == 0) return 0;
    final inRound = count % t;
    return inRound == 0 ? 1 : inRound / t;
  }

  /// Whole rounds of the target completed so far; 0 with no target.
  int get rounds => target == null ? 0 : count ~/ target!;

  /// The count is exactly on a multiple of the target (and above zero).
  bool get onTarget => target != null && count > 0 && count % target! == 0;

  TasbeehCounter increment() =>
      isFull ? this : TasbeehCounter(count: count + 1, target: target);

  TasbeehCounter decrement() =>
      count == 0 ? this : TasbeehCounter(count: count - 1, target: target);

  TasbeehCounter reset() => TasbeehCounter(target: target);

  /// A different target; the count stays. Targets outside [targets] are refused.
  TasbeehCounter withTarget(int? newTarget) {
    if (newTarget != null && !targets.contains(newTarget)) {
      throw ArgumentError.value(
        newTarget,
        'newTarget',
        'not an offered target',
      );
    }
    return TasbeehCounter(count: count, target: newTarget);
  }

  @override
  List<Object?> get props => [count, target];
}
