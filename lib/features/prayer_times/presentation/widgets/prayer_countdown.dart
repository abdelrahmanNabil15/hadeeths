import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/features/prayer_times/presentation/countdown_text.dart';

/// Rebuilds [builder] with the time left until [nextAt], once a second, while it can be seen.
///
/// - The value is always `nextAt - clock.now()`; nothing is counted down, so it cannot drift and a
///   changed phone clock is picked up on the next tick.
/// - It ticks on the second boundary of the rounded-up value, so the display changes exactly as a
///   second passes.
/// - It stops while the app is not in the foreground, while its section is hidden (ticker mode off)
///   and while another page covers it; it recomputes at once when it can be seen again and calls
///   [onResumed] (the page recalculates, for example after midnight).
/// - When the time is reached it calls [onReachedZero] once for that [nextAt]; a new [nextAt]
///   (the next prayer) starts again.
class PrayerCountdown extends StatefulWidget {
  const PrayerCountdown({
    super.key,
    required this.nextAt,
    required this.clock,
    required this.builder,
    this.onReachedZero,
    this.onResumed,
  });

  final DateTime nextAt;
  final Clock clock;
  final Widget Function(BuildContext context, Duration remaining) builder;
  final VoidCallback? onReachedZero;
  final VoidCallback? onResumed;

  @override
  State<PrayerCountdown> createState() => _PrayerCountdownState();
}

class _PrayerCountdownState extends State<PrayerCountdown>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  bool _visible = true;
  DateTime? _reachedFor;

  Duration get _remaining {
    final left = widget.nextAt.difference(widget.clock.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get _running => _foreground && _visible;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    final becameVisible = visible && !_visible;
    _visible = visible;
    _schedule();
    if (becameVisible) _later(widget.onResumed);
  }

  @override
  void didUpdateWidget(PrayerCountdown old) {
    super.didUpdateWidget(old);
    if (old.nextAt != widget.nextAt) _reachedFor = null;
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (foreground) {
      setState(() {});
      _later(widget.onResumed);
    }
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_running) return;
    final remaining = _remaining;
    if (remaining == Duration.zero) {
      _reached();
      return;
    }
    _timer = Timer(untilNextTick(remaining), _tick);
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    _schedule();
  }

  void _reached() {
    if (_reachedFor == widget.nextAt) return;
    _reachedFor = widget.nextAt;
    _later(widget.onReachedZero);
  }

  /// Callers may change state (the page recalculates), which must not happen in the middle of a
  /// build, so callbacks run after the current frame.
  void _later(VoidCallback? callback) {
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}
