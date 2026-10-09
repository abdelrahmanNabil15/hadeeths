import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/app_icons.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/categories/presentation/category_navigation.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/categories/presentation/widgets/home_hero.dart';
import 'package:mynewapp/features/search/presentation/pages/search_page.dart';
import 'package:mynewapp/features/search/presentation/widgets/search_entry.dart';
import 'package:mynewapp/features/settings/presentation/pages/about_page.dart';
import 'package:mynewapp/features/settings/presentation/pages/settings_page.dart';
import 'package:mynewapp/l10n/l10n.dart';

class HomePage extends StatelessWidget {
  /// [inShell] is true when the bottom navigation is showing: settings and "Sources and
  /// rights" then live under "More", so this page does not repeat them.
  const HomePage({
    super.key,
    this.inShell = false,
    this.clock = const SystemClock(),
  });

  final bool inShell;

  /// Gives today's date for the header.
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CategoriesCubit, CategoriesState>(
        listenWhen: (previous, current) =>
            current.refreshFailure != null &&
            current.refreshFailure != previous.refreshFailure,
        listener: (context, state) =>
            showFailureSnackBar(context, state.refreshFailure!),
        builder: (context, state) =>
            AnimatedStateSwitcher(child: _body(context, state)),
      ),
    );
  }

  /// The header, shown above every state so the screen keeps its identity while loading or
  /// after an error. [compact] leaves out the introduction and the search field, so a state
  /// message (with its retry button) stays on screen even on a small phone with very large text.
  Widget _hero(BuildContext context, {bool compact = false}) {
    final l10n = context.l10n;
    final colors = AppColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Formatted with Western digits, then shown in the user's digit style.
    final date = context.digits.localize(
      (DateFormat.yMMMMEEEEd(
        locale,
      )..useNativeDigits = false).format(clock.now().toLocal()),
    );
    return HomeHero(
      title: l10n.appTitle,
      intro: compact ? null : l10n.homeIntro,
      date: date,
      action: inShell
          ? null
          : IconButton(
              tooltip: l10n.settings,
              color: colors.onHero,
              icon: const Icon(AppIcons.settings),
              onPressed: () => Navigator.of(
                context,
              ).push(appRoute<void>(builder: (_) => const SettingsPage())),
            ),
      bottom: compact
          ? null
          : SearchEntry(
              hint: l10n.searchHint,
              onTap: () => openSearch(context),
            ),
    );
  }

  /// The header above a state that fills the rest of the screen (loading, error, empty).
  Widget _withHero(BuildContext context, Key key, Widget child) =>
      CustomScrollView(
        key: key,
        slivers: [
          SliverToBoxAdapter(child: _hero(context, compact: true)),
          SliverFillRemaining(child: child),
        ],
      );

  /// Each state has its own key, so a change of state fades; a refresh of the same state does not.
  Widget _body(BuildContext context, CategoriesState state) {
    final l10n = context.l10n;
    final cubit = context.read<CategoriesCubit>();
    switch (state.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return _withHero(
          context,
          const ValueKey('loading'),
          const ContentWidth(child: SkeletonList()),
        );
      case LoadStatus.failure:
        return _withHero(
          context,
          const ValueKey('failure'),
          ErrorView(failure: state.failure!, onRetry: cubit.retry),
        );
      case LoadStatus.success:
        final roots = state.roots;
        if (roots.isEmpty) {
          return _withHero(
            context,
            const ValueKey('empty'),
            EmptyView(
              message: l10n.noCategories,
              icon: Icons.folder_off_outlined,
            ),
          );
        }
        return RefreshIndicator(
          key: const ValueKey('content'),
          onRefresh: cubit.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _hero(context),
              ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeading(l10n.mainCategories),
                      const SizedBox(height: AppSpacing.md),
                      for (final root in roots) ...[
                        AppTile(
                          title: root.title,
                          pressFeedback: true,
                          trailingText: context.digits.format(root.hadithCount),
                          semanticLabel: l10n.tileSemantics(
                            root.title,
                            context.digits.format(root.hadithCount),
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
                              appRoute<void>(builder: (_) => const AboutPage()),
                            ),
                            icon: const Icon(AppIcons.info),
                            label: Text(l10n.aboutTitle),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
