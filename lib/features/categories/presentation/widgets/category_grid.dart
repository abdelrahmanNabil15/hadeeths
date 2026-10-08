import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';
import 'package:mynewapp/features/categories/presentation/widgets/category_card.dart';
import 'package:mynewapp/l10n/l10n.dart';

const _backdropAsset = 'assets/backgruond.jpg';

/// Background image shared by the category screens.
///
/// The source image is 2250x4000 (about 36 MB once decoded). It is decoded at the width it is
/// actually shown at, which keeps it to a few MB.
class CategoryBackdrop extends StatelessWidget {
  const CategoryBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeWidth = (constraints.maxWidth * pixelRatio).round();
        // SizedBox.expand: a short list must still fill the screen with the backdrop.
        return SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ResizeImage(
                  const AssetImage(_backdropAsset),
                  width: decodeWidth,
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Category cards in rows of equal height. A row is as tall as its tallest card, so long
/// titles at large text sizes grow the row instead of overflowing. The number of columns follows
/// the width and the user's text size: wide screens get more, large text gets fewer.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.nodes, required this.onOpen});

  final List<HadithCategory> nodes;
  final void Function(HadithCategory node) onOpen;

  /// Columns that fit in [width] when a card may be at most
  /// [AppSizes.categoryCardMaxWidth] wide at 100% text (wider as the text grows).
  static int columnsFor(double width, double textScale) {
    final maxCardWidth = AppSizes.categoryCardMaxWidth * textScale;
    final columns = (width / (maxCardWidth + AppSpacing.grid)).ceil();
    return columns < 1 ? 1 : columns;
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final minHeight = textScaler.scale(AppSizes.categoryCardHeight);
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(constraints.maxWidth, textScaler.scale(1));
        final rows = <Widget>[];
        for (var start = 0; start < nodes.length; start += columns) {
          final cards = <Widget>[];
          for (var i = start; i < start + columns; i++) {
            if (i > start) cards.add(const SizedBox(width: AppSpacing.grid));
            if (i >= nodes.length) {
              cards.add(const Expanded(child: SizedBox.shrink()));
              continue;
            }
            final node = nodes[i];
            cards.add(
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: CategoryCard(
                    title: node.title,
                    semanticLabel: l10n.categoryCardSemantics(
                      node.title,
                      '${node.hadithCount}',
                    ),
                    onTap: () => onOpen(node),
                  ),
                ),
              ),
            );
          }
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: AppSpacing.grid));
          }
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cards,
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}
