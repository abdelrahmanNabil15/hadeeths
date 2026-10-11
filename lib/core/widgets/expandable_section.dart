import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/app_icons.dart';

/// A titled block that expands and collapses in place. Announces its expanded state to
/// screen readers; the animation is skipped when the user asked for reduced motion.
class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.onShare,
    this.shareTooltip,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  /// When set, a share button appears while the section is open.
  final VoidCallback? onShare;
  final String? shareTooltip;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppMotion.medium;
    final body = _expanded
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: widget.child,
          )
        : const SizedBox(width: double.infinity);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  expanded: _expanded,
                  label: widget.title,
                  excludeSemantics: true,
                  onTap: _toggle,
                  child: InkWell(
                    onTap: _toggle,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSizes.minTileHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: AppTextSize.heading,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            _Chevron(expanded: _expanded, duration: duration),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_expanded && widget.onShare != null)
                IconButton(
                  tooltip: widget.shareTooltip,
                  icon: const Icon(AppIcons.share),
                  onPressed: widget.onShare,
                ),
            ],
          ),
          // With reduced motion the content simply appears; a zero-duration AnimatedSize
          // would re-dirty its own layout.
          if (reduceMotion)
            body
          else
            AnimatedSize(
              duration: duration,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: body,
            ),
        ],
      ),
    );
  }
}

/// Points toward the content when closed and down when open, in either text direction.
class _Chevron extends StatelessWidget {
  const _Chevron({required this.expanded, required this.duration});

  final bool expanded;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    // The arrow already mirrors with the text direction, so it must turn the other way
    // in right-to-left to end up pointing down.
    final turns = expanded ? (rtl ? -0.25 : 0.25) : 0.0;
    final icon = Icon(AppIcons.chevron, size: AppSizes.iconSmall, color: color);
    if (duration == Duration.zero) {
      return RotationTransition(
        turns: AlwaysStoppedAnimation(turns),
        child: icon,
      );
    }
    return AnimatedRotation(turns: turns, duration: duration, child: icon);
  }
}
