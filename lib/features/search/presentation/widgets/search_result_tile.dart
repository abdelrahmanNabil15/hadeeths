import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/features/search/domain/hadith_search_result.dart';

/// A search hit: the title and an excerpt of the hadith with the matched words highlighted.
/// The excerpt is a window onto the unmodified text; no characters are changed.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  final HadithSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final excerpt = excerptAround(result.segments);
    final body = TextStyle(
      fontSize: AppTextSize.body,
      height: AppLineHeight.body,
      color: scheme.onSurfaceVariant,
    );
    final mark = body.copyWith(
      color: scheme.onPrimaryContainer,
      backgroundColor: scheme.primaryContainer,
      fontWeight: FontWeight.w700,
    );
    return Semantics(
      button: true,
      label: result.title,
      excludeSemantics: true,
      onTap: onTap,
      child: AppCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTextSize.body + 1,
                  fontWeight: FontWeight.w700,
                  height: AppLineHeight.body,
                  color: scheme.onSurface,
                ),
              ),
              if (excerpt.segments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    children: [
                      if (excerpt.leading)
                        TextSpan(text: '\u2026 ', style: body),
                      for (final s in excerpt.segments)
                        TextSpan(
                          text: s.text,
                          style: s.highlighted ? mark : body,
                        ),
                      if (excerpt.trailing)
                        TextSpan(text: ' \u2026', style: body),
                    ],
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
