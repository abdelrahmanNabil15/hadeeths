import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/categories/presentation/category_navigation.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/categories/presentation/widgets/category_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(100, 241, 224, 172),
        title: const CustomText(
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
                          child: CustomText(
                            fontWeight: FontWeight.bold,
                            alignment: Alignment.centerRight,
                            color: Colors.black,
                            text: 'التصنيفات الرئيسية',
                            fontSize: 30,
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
