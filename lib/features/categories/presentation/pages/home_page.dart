import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/categories/presentation/category_navigation.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/search/presentation/pages/search_page.dart';
import 'package:mynewapp/features/search/presentation/widgets/search_entry.dart';
import 'package:mynewapp/features/settings/presentation/pages/about_page.dart';
import 'package:mynewapp/features/settings/presentation/pages/settings_page.dart';
import 'package:mynewapp/l10n/l10n.dart';

class HomePage extends StatelessWidget {
  /// [inShell] is true when the bottom navigation is showing: settings and "Sources and
  /// rights" then live under "More", so this page does not repeat them.
  const HomePage({super.key, this.inShell = false});

  final bool inShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (!inShell)
            IconButton(
              tooltip: l10n.settings,
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              ),
            ),
        ],
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
              return const ContentWidth(child: SkeletonList());
            case LoadStatus.failure:
              return ErrorView(failure: state.failure!, onRetry: cubit.retry);
            case LoadStatus.success:
              final roots = state.roots;
              if (roots.isEmpty) {
                return EmptyView(
                  message: l10n.noCategories,
                  icon: Icons.folder_off_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: cubit.refresh,
                child: ContentWidth(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Text(
                        l10n.homeIntro,
                        style: TextStyle(
                          fontSize: AppTextSize.body,
                          height: AppLineHeight.body,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SearchEntry(
                        hint: l10n.searchHint,
                        onTap: () => openSearch(context),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SectionHeading(l10n.mainCategories),
                      const SizedBox(height: AppSpacing.md),
                      for (final root in roots) ...[
                        AppTile(
                          title: root.title,
                          trailingText: '${root.hadithCount}',
                          semanticLabel: l10n.tileSemantics(
                            root.title,
                            '${root.hadithCount}',
                          ),
                          onTap: () => openCategory(context, root),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (!inShell) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AboutPage(),
                              ),
                            ),
                            icon: const Icon(Icons.info_outline),
                            label: Text(l10n.aboutTitle),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
