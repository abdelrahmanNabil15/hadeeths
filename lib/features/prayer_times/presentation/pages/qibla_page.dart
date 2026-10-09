import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/prayer_times/domain/qibla.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The direction of the Kaaba from the chosen place: a number of degrees from true north and the
/// nearest compass word, with a map-style dial (north at the top). It does not use the phone's
/// compass, so it works everywhere and never gives a noisy reading.
class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final digits = context.digits;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qiblaHeading)),
      body: ContentWidth(
        child: BlocBuilder<PrayerCubit, PrayerState>(
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
            final kilometres = (Qibla.distanceMetres(place.point) / 1000)
                .round();
            final degrees = digits.localize(bearing.round().toString());
            final direction = compassWord(l10n, bearing);
            final description = '${l10n.qiblaBearing(degrees)}, $direction';
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: Semantics(
                    container: true,
                    label: description,
                    excludeSemantics: true,
                    child: SizedBox(
                      width: 260,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.compassN,
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
                                bearing: bearing,
                                ring: scheme.outline,
                                accent: scheme.primary,
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
                  style: TextStyle(
                    fontSize: AppTextSize.meta,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.qiblaDistance(digits.format(kilometres)),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextSize.meta,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.bearing,
    required this.ring,
    required this.accent,
    required this.tick,
  });

  final double bearing;
  final Color ring;
  final Color accent;
  final Color tick;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
    final tickPaint = Paint()
      ..strokeWidth = 2
      ..color = tick;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final outer = center + Offset(math.sin(a), -math.cos(a)) * radius;
      final inner = center + Offset(math.sin(a), -math.cos(a)) * (radius - 12);
      canvas.drawLine(inner, outer, tickPaint);
    }
    final a = bearing * math.pi / 180;
    final direction = Offset(math.sin(a), -math.cos(a));
    final tip = center + direction * (radius - 6);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
    canvas.drawCircle(tip, 11, Paint()..color = accent);
    canvas.drawCircle(center, 6, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.bearing != bearing ||
      old.ring != ring ||
      old.accent != accent ||
      old.tick != tick;
}
