import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/qibla.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/qibla_compass_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The direction of the Kaaba from the chosen place: a number of degrees from true north and the
/// nearest compass word, with a map-style dial (north at the top). That part needs no sensor and
/// never shows a noisy reading. Below it the user can switch on the live compass, which turns the
/// dial to follow the phone.
class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qiblaHeading)),
      body: ContentWidth(
        child: BlocBuilder<PrayerCubit, PrayerState>(
          buildWhen: (a, b) => a.preferences.location != b.preferences.location,
          builder: (context, state) {
            final place = state.preferences.location;
            if (place == null) {
              return EmptyView(
                message: l10n.qiblaNeedsPlace,
                icon: Icons.explore_outlined,
              );
            }
            final bearing = Qibla.bearing(place.point);
            if (bearing == null) {
              return EmptyView(
                message: l10n.qiblaHere,
                icon: Icons.mosque_outlined,
              );
            }
            return _QiblaBody(
              key: ValueKey(place.point),
              services: context.read<PrayerServices>(),
              place: place.point,
              bearing: bearing,
            );
          },
        ),
      ),
    );
  }

  /// The nearest of the eight compass words for a bearing in degrees.
  static String compassWord(AppLocalizations l10n, double bearing) {
    final index = ((bearing + 22.5) ~/ 45) % 8;
    return switch (index) {
      0 => l10n.compassN,
      1 => l10n.compassNE,
      2 => l10n.compassE,
      3 => l10n.compassSE,
      4 => l10n.compassS,
      5 => l10n.compassSW,
      6 => l10n.compassW,
      _ => l10n.compassNW,
    };
  }
}

class _QiblaBody extends StatefulWidget {
  const _QiblaBody({
    super.key,
    required this.services,
    required this.place,
    required this.bearing,
  });

  final PrayerServices services;
  final GeoPoint place;
  final double bearing;

  @override
  State<_QiblaBody> createState() => _QiblaBodyState();
}

class _QiblaBodyState extends State<_QiblaBody> with WidgetsBindingObserver {
  late final QiblaCompassCubit _compass = QiblaCompassCubit(
    services: widget.services,
    place: widget.place,
    qiblaBearing: widget.bearing,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compass.close();
    super.dispose();
  }

  /// The sensors stop when the app is not in front: no battery use, nothing listening unseen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _compass.stop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final digits = context.digits;
    final bearing = widget.bearing;
    final kilometres = (Qibla.distanceMetres(widget.place) / 1000).round();
    final degrees = digits.localize(bearing.round().toString());
    final direction = QiblaPage.compassWord(l10n, bearing);
    final description = '${l10n.qiblaBearing(degrees)}, $direction';
    return BlocProvider.value(
      value: _compass,
      child: BlocConsumer<QiblaCompassCubit, QiblaCompassState>(
        listenWhen: (a, b) => !a.aligned && b.aligned,
        listener: (context, state) => HapticFeedback.mediumImpact(),
        builder: (context, live) {
          final isLive = live.status == CompassStatus.active;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Semantics(
                  container: true,
                  liveRegion: isLive,
                  label: isLive ? _liveLabel(l10n, digits, live) : description,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 260,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLive ? ' ' : l10n.compassN,
                          style: TextStyle(
                            fontSize: AppTextSize.meta,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: CustomPaint(
                            painter: _DialPainter(
                              markerAngle: isLive
                                  ? (live.interference ? null : live.turn)
                                  : bearing,
                              northAngle: isLive ? -live.trueHeading! : null,
                              aligned: live.aligned,
                              ring: scheme.outline,
                              accent: live.aligned
                                  ? scheme.secondary
                                  : scheme.primary,
                              tick: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isLive)
                ..._liveTexts(context, live)
              else
                ..._staticTexts(
                  context,
                  degrees: degrees,
                  direction: direction,
                  kilometres: kilometres,
                ),
              const SizedBox(height: AppSpacing.lg),
              _CompassSwitch(compass: _compass, live: live),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.qiblaNote,
                style: TextStyle(
                  fontSize: AppTextSize.meta,
                  height: AppLineHeight.body,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _staticTexts(
    BuildContext context, {
    required String degrees,
    required String direction,
    required int kilometres,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final digits = context.digits;
    TextStyle small() =>
        TextStyle(fontSize: AppTextSize.meta, color: scheme.onSurfaceVariant);
    return [
      Text(
        '$degrees°',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTextSize.display,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      Text(
        direction,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTextSize.heading,
          color: scheme.onSurface,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.qiblaBearing(degrees),
        textAlign: TextAlign.center,
        style: small(),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        l10n.qiblaDistance(digits.format(kilometres)),
        textAlign: TextAlign.center,
        style: small(),
      ),
    ];
  }

  List<Widget> _liveTexts(BuildContext context, QiblaCompassState live) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final digits = context.digits;
    TextStyle small() => TextStyle(
      fontSize: AppTextSize.meta,
      height: AppLineHeight.body,
      color: scheme.onSurfaceVariant,
    );
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (live.aligned) ...[
            Icon(Icons.check_circle, color: scheme.secondary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              _instruction(l10n, digits, live),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTextSize.title,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      if (live.interference)
        Semantics(
          liveRegion: true,
          container: true,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: scheme.error),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.compassInterference,
                    style: TextStyle(
                      fontSize: AppTextSize.meta,
                      height: AppLineHeight.body,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.compassHoldFlat, textAlign: TextAlign.center, style: small()),
      const SizedBox(height: AppSpacing.xs),
      Text(l10n.compassCalibrate, textAlign: TextAlign.center, style: small()),
      if (live.declination != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.compassCorrection(_signed(digits, live.declination!)),
          textAlign: TextAlign.center,
          style: small(),
        ),
      ],
    ];
  }

  static String _signed(Digits digits, double value) {
    final text = '${value >= 0 ? '+' : '-'}${value.abs().toStringAsFixed(1)}';
    final localized = digits.localize(text);
    return digits.arabicIndic ? localized.replaceAll('.', '٫') : localized;
  }

  /// "Turn right 40°", "Turn left 12°" or "You are facing the Qibla". The number is rounded to
  /// 5 degrees so a screen reader is not interrupted by every small change.
  static String _instruction(
    AppLocalizations l10n,
    Digits digits,
    QiblaCompassState live,
  ) {
    if (live.interference) return l10n.compassUnreliable;
    if (live.aligned) return l10n.compassAligned;
    final turn = live.turn!;
    final rounded = math.max(5, (turn.abs() / 5).round() * 5);
    final text = digits.format(rounded);
    return turn > 0 ? l10n.compassTurnRight(text) : l10n.compassTurnLeft(text);
  }

  static String _liveLabel(
    AppLocalizations l10n,
    Digits digits,
    QiblaCompassState live,
  ) => _instruction(l10n, digits, live);
}

/// Starts and stops the live compass, and explains why it is not available when it is not.
class _CompassSwitch extends StatelessWidget {
  const _CompassSwitch({required this.compass, required this.live});

  final QiblaCompassCubit compass;
  final QiblaCompassState live;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final running =
        live.status == CompassStatus.active ||
        live.status == CompassStatus.starting;
    final message = switch (live.status) {
      CompassStatus.unavailable => l10n.compassUnavailable,
      CompassStatus.modelExpired => l10n.compassModelExpired,
      CompassStatus.starting => l10n.compassStarting,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: TextStyle(
                  fontSize: AppTextSize.body,
                  height: AppLineHeight.body,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        if (live.status != CompassStatus.modelExpired)
          running
              ? OutlinedButton.icon(
                  onPressed: compass.stop,
                  icon: const Icon(Icons.explore_off_outlined),
                  label: Text(l10n.compassStop),
                )
              : FilledButton.icon(
                  onPressed: compass.start,
                  icon: const Icon(Icons.explore_outlined),
                  label: Text(l10n.compassUse),
                ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.compassPrivacy,
          style: TextStyle(
            fontSize: AppTextSize.meta,
            height: AppLineHeight.body,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A ring with a marker. Static: north at the top, the marker at the Qibla bearing. Live: the top
/// is where the phone points, the marker is the Qibla relative to that, and a small tick shows
/// where north is.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.markerAngle,
    required this.northAngle,
    required this.aligned,
    required this.ring,
    required this.accent,
    required this.tick,
  });

  final double? markerAngle;
  final double? northAngle;
  final bool aligned;
  final Color ring;
  final Color accent;
  final Color tick;

  Offset _at(Offset center, double radius, double degrees) {
    final a = degrees * math.pi / 180;
    return center + Offset(math.sin(a), -math.cos(a)) * radius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 4 : 2
        ..color = aligned ? accent : ring,
    );
    final tickPaint = Paint()
      ..strokeWidth = 2
      ..color = tick;
    if (northAngle == null) {
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          _at(center, radius - 12, i * 90),
          _at(center, radius, i * 90),
          tickPaint,
        );
      }
    } else {
      // The top of the dial is "ahead"; a long tick marks north as it swings round.
      final north = northAngle!;
      canvas.drawLine(
        _at(center, radius - 22, north),
        _at(center, radius, north),
        Paint()
          ..strokeWidth = 4
          ..color = tick,
      );
      final front = Path()
        ..moveTo(center.dx, center.dy - radius - 4)
        ..lineTo(center.dx - 9, center.dy - radius + 12)
        ..lineTo(center.dx + 9, center.dy - radius + 12)
        ..close();
      canvas.drawPath(front, Paint()..color = tick);
    }
    // No marker while the reading is being disturbed: a wrong arrow is worse than none.
    final angle = markerAngle;
    if (angle != null) {
      final tip = _at(center, radius - 6, angle);
      canvas.drawLine(
        center,
        tip,
        Paint()
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );
      canvas.drawCircle(tip, 11, Paint()..color = accent);
    }
    canvas.drawCircle(
      center,
      6,
      Paint()..color = angle == null ? ring : accent,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.markerAngle != markerAngle ||
      old.northAngle != northAngle ||
      old.aligned != aligned ||
      old.ring != ring ||
      old.accent != accent ||
      old.tick != tick;
}
