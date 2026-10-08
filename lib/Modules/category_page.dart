import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Shared/components/CustomText.dart';
import '../Shared/components/category_card.dart';
import '../Shared/components/state_views.dart';
import '../Shared/constant.dart';
import 'categories/categories_cubit.dart';
import 'hadith_list_page.dart';
import 'home_page.dart';

/// Sub-categories of one category, plus a way into the hadiths filed directly under it.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final node = state.byId(categoryId);
        final children = state.childrenOf(categoryId);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: appbarColor,
            title: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Customtext(
                fontWeight: FontWeight.bold,
                alignment: Alignment.centerRight,
                color: Colors.white,
                text: node?.title ?? '',
                fontSize: 19,
              ),
            ),
          ),
          body: node == null
              ? const EmptyView(message: 'هذا التصنيف غير متوفر')
              : CategoryBackdrop(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: MediaQuery.textScalerOf(context).scale(90),
                          child: CategoryCard(
                            title: 'جميع الأحاديث في هذا التصنيف',
                            subtitle: '${node.hadithCount}',
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
                        const SizedBox(height: 20),
                        CategoryGrid(nodes: children),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
