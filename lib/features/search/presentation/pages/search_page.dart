import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/app_icons.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_details_page.dart';
import 'package:mynewapp/features/search/domain/search_repository.dart';
import 'package:mynewapp/features/search/presentation/state/search_cubit.dart';
import 'package:mynewapp/features/search/presentation/widgets/search_result_tile.dart';
import 'package:mynewapp/l10n/l10n.dart';

void openSearch(BuildContext context) {
  Navigator.of(
    context,
  ).push(appRoute<void>(builder: (_) => const SearchPage()));
}

/// Search-as-you-type over the hadith texts (server-side; Arabic diacritics are handled by
/// the server, so the displayed text is never altered).
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.apiLanguage;
    return BlocProvider(
      create: (context) =>
          SearchCubit(context.read<SearchRepository>(), language: language),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<SearchCubit>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
          child: ListenableBuilder(
            listenable: _controller,
            // The rounded field comes from the input theme: card colour, 3:1 edge, brand colour on
            // focus.
            builder: (context, _) => TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: cubit.onQueryChanged,
              style: TextStyle(
                fontSize: AppTextSize.body + 1,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                prefixIcon: Icon(AppIcons.search, color: scheme.primary),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.searchClear,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          cubit.onQueryChanged('');
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          switch (state.status) {
            case SearchStatus.idle:
              return EmptyView(message: l10n.searchPrompt, icon: Icons.search);
            case SearchStatus.tooShort:
              return EmptyView(
                message: context.digits.localize(
                  l10n.searchTooShort(SearchRepository.minPhraseLength),
                ),
                icon: Icons.edit_outlined,
              );
            case SearchStatus.loading:
              return const ContentWidth(child: SkeletonList(rowHeight: 96));
            case SearchStatus.failure:
              return ErrorView(failure: state.failure!, onRetry: cubit.retry);
            case SearchStatus.success:
              if (state.results.isEmpty) {
                return EmptyView(
                  message: l10n.searchNoResults(state.query),
                  icon: Icons.search_off,
                );
              }
              return ContentWidth(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: state.results.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Semantics(
                        liveRegion: true,
                        child: Text(
                          context.digits.localize(
                            state.mayBeTruncated
                                ? l10n.searchTruncated(
                                    SearchRepository.maxResults,
                                  )
                                : l10n.searchResultCount(state.results.length),
                          ),
                          style: TextStyle(
                            fontSize: AppTextSize.meta,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    final result = state.results[index - 1];
                    return SearchResultTile(
                      result: result,
                      onTap: () => Navigator.of(context).push(
                        appRoute<void>(
                          builder: (_) => HadithDetailsPage(id: result.id),
                        ),
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
