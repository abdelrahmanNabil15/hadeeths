import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Shared/Network/hadeeth_api.dart';
import '../Shared/errors/failure.dart';
import '../Shared/components/CustomText.dart';
import '../Shared/components/state_views.dart';
import '../Shared/constant.dart';
import 'categories/categories_cubit.dart' show LoadStatus;
import 'hadiths/hadith_list_cubit.dart';
import 'hadith_details_page.dart';

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
    return BlocProvider(
      create: (context) =>
          HadithListCubit(context.read<HadeethApi>(), categoryId)..load(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: appbarColor,
          title: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Customtext(
              fontWeight: FontWeight.bold,
              alignment: Alignment.centerRight,
              color: Colors.white,
              text: title,
              fontSize: 19,
            ),
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
              return const EmptyView(message: 'لا توجد أحاديث في هذا التصنيف');
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
                leading: const Icon(Icons.arrow_back_ios),
                title: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Customtext(
                    fontWeight: FontWeight.bold,
                    alignment: Alignment.centerRight,
                    color: const Color.fromARGB(250, 40, 82, 122),
                    text: hadith.title,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              failureMessage(failure),
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Schyler'),
            ),
            TextButton.icon(
              onPressed: widget.onLoadMore,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Schyler'),
              ),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
