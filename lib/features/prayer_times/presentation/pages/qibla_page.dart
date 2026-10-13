import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/haptics/haptics.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/qibla.dart';
import 'package:mynewapp/features/prayer_times/presentation/angle_smoothing.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/qibla_compass_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The direction of the Kaaba from the chosen place: a number of degrees from true north and the
/// nearest compass word, with a map-style dial (north at the top). That part needs no sensor and
/// never shows a noisy reading. Below it the user can switch on the live compass, which turns the
/// dial to follow the phone.
class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key, this.haptics = const SystemHaptics()});

  /// The short vibration when the compass lines up with the Qibla.
  final Haptics haptics;

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
              haptics: haptics,
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
    required this.haptics,
    required this.place,
    required this.bearing,
  });

  final PrayerServices services;
  final Haptics haptics;
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
        listener: (context, state) => widget.haptics.alignment(),
        builder: (context, live) {
          final isLive = live.status == CompassStatus.active;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Panel(
                children: [
                  Center(
                    child: Semantics(
                      container: true,
                      liveRegion: isLive,
                      label: isLive
                          ? _liveLabel(l10n, digits, live)
                          : description,
                      excludeSemantics: true,
                      // Only the drawing is eased towards each reading. A missing marker
                      // (interference) disappears at once, never fading while it is wrong.
                      child: SizedBox.square(
                        dimension: _dialSize,
                        child: SmoothAngle(
                          angle: isLive ? -live.trueHeading! : null,
                          builder: (context, north) => SmoothAngle(
                            angle: isLive
                                ? (live.interference ? null : live.turn)
                                : bearing,
                            builder: (context, marker) => CustomPaint(
                              painter: _DialPainter(
                                markerAngle: marker,
                                northAngle: north,
                                aligned: live.aligned,
                                colors: _DialColors.of(context),
                                labels: [
                                  l10n.compassN,
                                  l10n.compassE,
                                  l10n.compassS,
                                  l10n.compassW,
                                ],
                                textDirection: Directionality.of(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (isLive)
                    ..._liveHeadline(context, live)
                  else
                    ..._staticTexts(
                      context,
                      degrees: degrees,
                      direction: direction,
                      kilometres: kilometres,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isLive) ..._liveDetails(context, live),
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

  static const _dialSize = 280.0;

  /// On the panel: the bearing in large figures, the compass word, and how far the Kaaba is.
  List<Widget> _staticTexts(
    BuildContext context, {
    required String degrees,
    required String direction,
    required int kilometres,
  }) {
    final l10n = context.l10n;
    final colors = AppColors.of(context);
    final type = AppTypography.of(context);
    final digits = context.digits;
    return [
      Text(
        '$degrees°',
        textAlign: TextAlign.center,
        style: type.number.copyWith(
          fontSize: AppTextSize.display,
          color: colors.onHero,
        ),
      ),
      Text(
        direction,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTextSize.heading,
          color: colors.heroAccent,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.qiblaBearing(degrees),
        textAlign: TextAlign.center,
        style: type.meta.copyWith(color: colors.onHeroMuted),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        l10n.qiblaDistance(digits.format(kilometres)),
        textAlign: TextAlign.center,
        style: type.meta.copyWith(color: colors.onHeroMuted),
      ),
    ];
  }

  /// On the panel while the compass is live: what to do next, or that the phone faces the Qibla.
  /// Alignment is shown by the words and the check mark, not by colour alone.
  List<Widget> _liveHeadline(BuildContext context, QiblaCompassState live) {
    final l10n = context.l10n;
    final colors = AppColors.of(context);
    final digits = context.digits;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (live.aligned) ...[
            Icon(Icons.check_circle, color: colors.heroAccent),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              _instruction(l10n, digits, live),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTextSize.title,
                fontWeight: FontWeight.w700,
                color: colors.onHero,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  /// Under the panel while the compass is live: interference, how to hold the phone, calibration.
  List<Widget> _liveDetails(BuildContext context, QiblaCompassState live) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final digits = context.digits;
    TextStyle small() => TextStyle(
      fontSize: AppTextSize.meta,
      height: AppLineHeight.body,
      color: scheme.onSurfaceVariant,
    );
    return [
      AnimatedStateSwitcher(
        child: live.interference
            ? StatusBanner(
                key: const ValueKey('interference'),
                message: l10n.compassInterference,
                kind: StatusKind.error,
              )
            : const SizedBox(key: ValueKey('clear'), width: double.infinity),
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
      const SizedBox(height: AppSpacing.lg),
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

/// The midnight-emerald panel the dial sits on, with the faint star lattice of the home screen.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sheet),
      child: ColoredBox(
        color: colors.hero,
        child: Stack(
          children: [
            Positioned.fill(
              child: GeometricPattern(
                color: colors.heroAccent.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dial's colours on the panel, all from the theme.
class _DialColors {
  const _DialColors({
    required this.face,
    required this.ring,
    required this.hairline,
    required this.tick,
    required this.label,
    required this.needle,
    required this.aligned,
    required this.gold,
    required this.kaaba,
  });

  factory _DialColors.of(BuildContext context) {
    final colors = AppColors.of(context);
    return _DialColors(
      face: Color.alphaBlend(
        colors.onHero.withValues(alpha: 0.06),
        colors.hero,
      ),
      ring: colors.onHeroMuted.withValues(alpha: 0.6),
      hairline: colors.onHero.withValues(alpha: 0.16),
      tick: colors.onHeroMuted,
      label: colors.onHeroMuted,
      needle: colors.heroAccent,
      aligned: colors.onHero,
      gold: colors.heroAccent,
      kaaba: HSLColor.fromColor(colors.hero).withLightness(0.04).toColor(),
    );
  }

  final Color face;
  final Color ring;
  final Color hairline;
  final Color tick;
  final Color label;
  final Color needle;
  final Color aligned;
  final Color gold;
  final Color kaaba;

  @override
  bool operator ==(Object other) =>
      other is _DialColors &&
      other.face == face &&
      other.ring == ring &&
      other.hairline == hairline &&
      other.tick == tick &&
      other.label == label &&
      other.needle == needle &&
      other.aligned == aligned &&
      other.gold == gold &&
      other.kaaba == kaaba;

  @override
  int get hashCode => Object.hash(
    face,
    ring,
    hairline,
    tick,
    label,
    needle,
    aligned,
    gold,
    kaaba,
  );
}

/// A compass rose with a marker. Static: north at the top, the marker at the Qibla bearing. Live:
/// the top is where the phone points, the marker is the Qibla relative to that, and the rose turns
/// so its north stays true. The marker is a small Kaaba on the rim. Decoration for the eyes only:
/// the page reads the same information aloud.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.markerAngle,
    required this.northAngle,
    required this.aligned,
    required this.colors,
    required this.labels,
    required this.textDirection,
  });

  final double? markerAngle;
  final double? northAngle;
  final bool aligned;
  final _DialColors colors;

  /// North, east, south and west, in the interface language.
  final List<String> labels;
  final TextDirection textDirection;

  Offset _at(Offset center, double radius, double degrees) {
    final a = degrees * math.pi / 180;
    return center + Offset(math.sin(a), -math.cos(a)) * radius;
  }

  void _label(Canvas canvas, String text, Offset at, Color color, bool bold) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final fine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.hairline;

    // The face, a fine inner rule, and an eight-pointed star pressed faintly into it.
    canvas.drawCircle(center, radius, Paint()..color = colors.face);
    canvas.drawCircle(center, radius - 18, fine);
    canvas.drawPath(eightPointStar(center, radius * 0.62), fine);

    // A tick every 10 degrees, longer every 30, then the ring.
    final north = northAngle ?? 0;
    final longTick = Paint()
      ..strokeWidth = 1.5
      ..color = colors.tick;
    for (var i = 0; i < 36; i++) {
      final long = i % 3 == 0;
      canvas.drawLine(
        _at(center, radius - (long ? 12 : 6), north + i * 10.0),
        _at(center, radius, north + i * 10.0),
        long ? longTick : fine,
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 4 : 2
        ..color = aligned ? colors.aligned : colors.ring,
    );

    // The four directions turn with north, so they always read upright.
    for (var i = 0; i < 4; i++) {
      _label(
        canvas,
        labels[i],
        _at(center, radius - 36, north + i * 90.0),
        i == 0 ? colors.gold : colors.label,
        i == 0,
      );
    }
    if (northAngle != null) {
      // Live: a pointer at the top marks where the phone is aimed.
      final front = Path()
        ..moveTo(center.dx, center.dy - radius - 6)
        ..lineTo(center.dx - 8, center.dy - radius + 8)
        ..lineTo(center.dx + 8, center.dy - radius + 8)
        ..close();
      canvas.drawPath(front, Paint()..color = colors.gold);
    }

    // No marker while the reading is being disturbed: a wrong arrow is worse than none.
    final angle = markerAngle;
    if (angle != null) {
      canvas.drawLine(
        center,
        _at(center, radius - 36, angle),
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = aligned ? colors.aligned : colors.needle,
      );
      _kaaba(canvas, _at(center, radius - 24, angle));
    }
    canvas.drawPath(
      eightPointStar(center, 10),
      Paint()..color = angle == null ? colors.ring : colors.gold,
    );
  }

  /// A small Kaaba: a dark cube with a gold band and a gold edge.
  void _kaaba(Canvas canvas, Offset at) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: 26, height: 26),
      const Radius.circular(4),
    );
    canvas
      ..drawRRect(body, Paint()..color = colors.kaaba)
      ..save()
      ..clipRRect(body)
      ..drawRect(
        Rect.fromLTWH(body.left, body.top + 6, body.width, 5),
        Paint()..color = colors.gold,
      )
      ..restore()
      ..drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = aligned ? colors.aligned : colors.gold,
      );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.markerAngle != markerAngle ||
      old.northAngle != northAngle ||
      old.aligned != aligned ||
      old.colors != colors ||
      old.textDirection != textDirection ||
      !_sameLabels(old.labels);

  bool _sameLabels(List<String> other) {
    for (var i = 0; i < labels.length; i++) {
      if (labels[i] != other[i]) return false;
    }
    return true;
  }
}
