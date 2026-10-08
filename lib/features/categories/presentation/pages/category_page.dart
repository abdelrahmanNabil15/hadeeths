import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/categories/presentation/category_navigation.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/categories/presentation/widgets/category_card.dart';
import 'package:mynewapp/features/categories/presentation/widgets/category_grid.dart';
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
          appBar: AppBar(
            backgroundColor: AppColors.appBar,
            title: CustomText(
              fontWeight: FontWeight.bold,
              alignment: AlignmentDirectional.centerStart,
              color: AppColors.onAppBar,
              text: node?.title ?? '',
              fontSize: AppTextSize.title,
              isHeader: true,
            ),
          ),
          body: node == null
              ? EmptyView(message: l10n.categoryUnavailable)
              : CategoryBackdrop(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.textScalerOf(
                              context,
                            ).scale(AppSizes.categoryWideCardHeight),
                          ),
                          child: CategoryCard(
                            title: l10n.allHadithsInCategory,
                            subtitle: '${node.hadithCount}',
                            semanticLabel: l10n.categoryCardSemantics(
                              l10n.allHadithsInCategory,
                              '${node.hadithCount}',
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => HadithListPage(
                                  categoryId: node.id,
                                  title: node.title,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.grid),
                        CategoryGrid(
                          nodes: children,
                          onOpen: (c) => openCategory(context, c),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
