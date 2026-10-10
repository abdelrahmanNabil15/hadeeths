import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_store.dart';
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
      create: (context) {
        // Remembered for the hadith of the day (only when that section is on and the user has not
        // switched remembering off). Nothing waits for it.
        context.read<DailyHadithStore?>()?.recordOpened(categoryId);
        return HadithListCubit(
          context.read<HadithsRepository>(),
          categoryId,
          language: language,
        )..load();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
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
      // Each state has its own key, so a change of state fades. Loading more pages keeps the
      // same state, so the list never fades or jumps while it grows.
      builder: (context, state) =>
          AnimatedStateSwitcher(child: _content(context, state)),
    );
  }

  Widget _content(BuildContext context, HadithListState state) {
    final cubit = context.read<HadithListCubit>();
    switch (state.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const ContentWidth(
          key: ValueKey('loading'),
          child: SkeletonList(rowHeight: 72),
        );
      case LoadStatus.failure:
        return ErrorView(
          key: const ValueKey('failure'),
          failure: state.failure!,
          onRetry: cubit.load,
        );
      case LoadStatus.success:
        if (state.items.isEmpty) {
          return EmptyView(
            key: const ValueKey('empty'),
            message: context.l10n.noHadithsInCategory,
            icon: Icons.menu_book_outlined,
          );
        }
        return _HadithList(key: const ValueKey('content'), state: state);
    }
  }
}

class _HadithList extends StatelessWidget {
  const _HadithList({super.key, required this.state});

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
        child: ContentWidth(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return _Footer(
                  failure: state.loadMoreFailure,
                  onLoadMore: cubit.loadMore,
                );
              }
              final hadith = state.items[index];
              return AppTile(
                title: hadith.title,
                maxTitleLines: 4,
                onTap: () => Navigator.of(context).push(
                  appRoute<void>(
                    builder: (_) => HadithDetailsPage(id: hadith.id),
                  ),
                ),
              );
            },
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
      return Semantics(
        liveRegion: true,
        container: true,
        child: Column(
          children: [
            Text(
              failureMessage(context.l10n, failure),
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              onPressed: widget.onLoadMore,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Semantics(
        label: context.l10n.loading,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
