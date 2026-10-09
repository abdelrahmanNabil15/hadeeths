import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';
import 'package:mynewapp/features/categories/presentation/pages/category_page.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_list_page.dart';

/// Opens the right screen for [node]: its sub-categories if it has any, otherwise its hadiths.
void openCategory(BuildContext context, HadithCategory node) {
  final hasChildren = context.read<CategoriesCubit>().state.hasChildren(
    node.id,
  );
  Navigator.of(context).push(
    appRoute<void>(
      builder: (_) => hasChildren
          ? CategoryPage(categoryId: node.id)
          : HadithListPage(categoryId: node.id, title: node.title),
    ),
  );
}
