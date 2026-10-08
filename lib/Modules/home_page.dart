import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Model/category_node.dart';
import '../Shared/components/CustomText.dart';
import '../Shared/components/category_card.dart';
import '../Shared/components/state_views.dart';
import 'categories/categories_cubit.dart';
import 'category_page.dart';
import 'hadith_list_page.dart';

/// Opens the right screen for [node]: its sub-categories if it has any, otherwise its hadiths.
void openCategory(BuildContext context, CategoryNode node) {
  final hasChildren = context.read<CategoriesCubit>().state.hasChildren(
    node.id,
  );
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => hasChildren
          ? CategoryPage(categoryId: node.id)
          : HadithListPage(categoryId: node.id, title: node.title),
    ),
  );
}

/// Background image + padding shared by the category screens.
class CategoryBackdrop extends StatelessWidget {
  const CategoryBackdrop({super.key, required this.child});

  final Widget child;

  @override
  // SizedBox.expand: a short list must still fill the screen with the backdrop.
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backgruond.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    ),
  );
}

/// A two-column grid of [nodes] that grows with the user's text size.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.nodes});

  final List<CategoryNode> nodes;

  @override
  Widget build(BuildContext context) {
    final cellHeight = MediaQuery.textScalerOf(context).scale(120);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: cellHeight,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return CategoryCard(
          title: node.title,
          onTap: () => openCategory(context, node),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(100, 241, 224, 172),
        title: const Customtext(
          fontWeight: FontWeight.bold,
          alignment: Alignment.center,
          color: Colors.white,
          text: 'الأحاديث النبوية',
          fontSize: 19,
        ),
      ),
      body: BlocConsumer<CategoriesCubit, CategoriesState>(
        listenWhen: (previous, current) =>
            current.refreshFailure != null &&
            current.refreshFailure != previous.refreshFailure,
        listener: (context, state) =>
            showFailureSnackBar(context, state.refreshFailure!),
        builder: (context, state) {
          final cubit = context.read<CategoriesCubit>();
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(failure: state.failure!, onRetry: cubit.retry);
            case LoadStatus.success:
              final roots = state.roots;
              if (roots.isEmpty) {
                return const EmptyView(message: 'لا توجد تصنيفات');
              }
              return CategoryBackdrop(
                child: RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 10, bottom: 8),
                          child: Customtext(
                            fontWeight: FontWeight.bold,
                            alignment: Alignment.centerRight,
                            color: Colors.black,
                            text: 'التصنيفات الرئيسية',
                            fontSize: 30,
                          ),
                        ),
                        CategoryGrid(nodes: roots),
                      ],
                    ),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
