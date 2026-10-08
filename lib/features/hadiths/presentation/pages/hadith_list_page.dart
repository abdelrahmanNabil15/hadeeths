import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_details_page.dart';
import 'package:mynewapp/features/hadiths/presentation/state/hadith_list_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Paged list of the hadiths of one category.
class HadithListPage extends StatelessWidget {
  const HadithListPage({
    super.key,
    required this.categoryId,
    required this.title,
  });

  final String categoryId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final language = context.apiLanguage;
    return BlocProvider(
      create: (context) => HadithListCubit(
        context.read<HadithsRepository>(),
        categoryId,
        language: language,
      )..load(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.appBar,
          title: CustomText(
            fontWeight: FontWeight.bold,
            alignment: AlignmentDirectional.centerStart,
            color: AppColors.onAppBar,
            text: title,
            fontSize: AppTextSize.title,
            isHeader: true,
          ),
        ),
        body: const _HadithListBody(),
      ),
    );
  }
}

class _HadithListBody extends StatelessWidget {
  const _HadithListBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HadithListCubit, HadithListState>(
      listenWhen: (previous, current) =>
          current.refreshFailure != null &&
          current.refreshFailure != previous.refreshFailure,
      listener: (context, state) =>
          showFailureSnackBar(context, state.refreshFailure!),
      builder: (context, state) {
        final cubit = context.read<HadithListCubit>();
        switch (state.status) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            return const LoadingView();
          case LoadStatus.failure:
            return ErrorView(failure: state.failure!, onRetry: cubit.load);
          case LoadStatus.success:
            if (state.items.isEmpty) {
              return EmptyView(message: context.l10n.noHadithsInCategory);
            }
            return _HadithList(state: state);
        }
      },
    );
  }
}

class _HadithList extends StatelessWidget {
  const _HadithList({required this.state});

  final HadithListState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HadithListCubit>();
    // The list is sized from what was actually loaded, never from the server's total.
    final showFooter =
        state.hasMore || state.isLoadingMore || state.loadMoreFailure != null;
    final itemCount = state.items.length + (showFooter ? 1 : 0);

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return _Footer(
                    failure: state.loadMoreFailure,
                    onLoadMore: cubit.loadMore,
                  );
                }
                final hadith = state.items[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => HadithDetailsPage(id: hadith.id),
                      ),
                    ),
                    title: CustomText(
                      fontWeight: FontWeight.bold,
                      alignment: AlignmentDirectional.centerStart,
                      color: AppColors.listTitle,
                      text: hadith.title,
                      fontSize: AppTextSize.listTitle,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Last list item. Building it means the user is near the end, so it asks for the next page.
class _Footer extends StatefulWidget {
  const _Footer({required this.failure, required this.onLoadMore});

  final Failure? failure;
  final VoidCallback onLoadMore;

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  @override
  void initState() {
    super.initState();
    if (widget.failure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Column(
            children: [
              Text(failureMessage(context.l10n, failure)),
              TextButton.icon(
                onPressed: widget.onLoadMore,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Semantics(
          label: context.l10n.loading,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
