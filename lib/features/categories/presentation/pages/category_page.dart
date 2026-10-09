import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/categories/presentation/category_navigation.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_list_page.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Sub-categories of one category, plus a way into the hadiths filed directly under it.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final node = state.byId(categoryId);
        final children = state.childrenOf(categoryId);
        return Scaffold(
          appBar: AppBar(title: Text(node?.title ?? '')),
          body: node == null
              ? EmptyView(message: l10n.categoryUnavailable)
              : ContentWidth(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      AppTile(
                        emphasized: true,
                        title: l10n.allHadithsInCategory,
                        trailingText: context.digits.format(node.hadithCount),
                        semanticLabel: l10n.tileSemantics(
                          l10n.allHadithsInCategory,
                          context.digits.format(node.hadithCount),
                        ),
                        onTap: () => Navigator.of(context).push(
                          appRoute<void>(
                            builder: (_) => HadithListPage(
                              categoryId: node.id,
                              title: node.title,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (final child in children) ...[
                        AppTile(
                          title: child.title,
                          trailingText: context.digits.format(
                            child.hadithCount,
                          ),
                          semanticLabel: l10n.tileSemantics(
                            child.title,
                            context.digits.format(child.hadithCount),
                          ),
                          onTap: () => openCategory(context, child),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
