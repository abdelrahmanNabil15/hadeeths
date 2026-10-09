import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';
import 'package:mynewapp/core/widgets/ornament_divider.dart';

/// The home screen's header: a midnight-emerald panel with a faint star lattice, today's date, a
/// small gold ornament, the app's name in the editorial face and a one-line introduction.
/// [action] sits at the end of the date row (settings, when there is no bottom navigation);
/// [bottom] is placed under the text (the search field).
///
/// It runs under the status bar, so the status-bar icons are switched to light while it shows.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.title,
    this.intro,
    required this.date,
    this.action,
    this.bottom,
  });

  final String title;
  final String? intro;
  final String date;
  final Widget? action;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final type = AppTypography.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.sheet),
        ),
        child: ColoredBox(
          color: colors.hero,
          child: Stack(
            children: [
              Positioned.fill(
                child: GeometricPattern(
                  color: colors.heroAccent.withValues(alpha: 0.08),
                ),
              ),
              ContentWidth(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    top + AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSizes.minTouchTarget,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                date,
                                style: type.meta.copyWith(
                                  color: colors.onHeroMuted,
                                ),
                              ),
                            ),
                            ?action,
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox(
                          width: 72,
                          child: OrnamentDivider(
                            color: colors.heroAccent,
                            lineColor: colors.heroAccent.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: type.editorialTitle.copyWith(
                            color: colors.onHero,
                          ),
                        ),
                      ),
                      if (intro != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          intro!,
                          style: type.body.copyWith(color: colors.onHeroMuted),
                        ),
                      ],
                      if (bottom != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        bottom!,
                      ],
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
