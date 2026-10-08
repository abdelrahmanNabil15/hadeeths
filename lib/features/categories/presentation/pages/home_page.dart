import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/categories/presentation/category_navigation.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/categories/presentation/widgets/category_grid.dart';
import 'package:mynewapp/l10n/l10n.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.homeAppBar,
        title: CustomText(
          fontWeight: FontWeight.bold,
          alignment: Alignment.center,
          color: AppColors.onAppBar,
          text: l10n.appTitle,
          fontSize: AppTextSize.title,
          isHeader: true,
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
                return EmptyView(message: l10n.noCategories);
              }
              return CategoryBackdrop(
                child: RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 10,
                            bottom: AppSpacing.sm,
                          ),
                          child: CustomText(
                            fontWeight: FontWeight.bold,
                            alignment: AlignmentDirectional.centerStart,
                            text: l10n.mainCategories,
                            fontSize: AppTextSize.display,
                            isHeader: true,
                          ),
                        ),
                        CategoryGrid(
                          nodes: roots,
                          onOpen: (c) => openCategory(context, c),
                        ),
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
