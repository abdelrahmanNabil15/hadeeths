import 'package:flutter/material.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/app/shell/coming_soon_page.dart';
import 'package:mynewapp/app/shell/more_page.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/features/categories/presentation/pages/home_page.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/prayer_page.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The top-level sections.
enum ShellTab { hadiths, quran, prayer, more }

/// Bottom navigation with one independent navigation stack per section.
///
/// - A section keeps its place when you switch away and back.
/// - Pages pushed inside a section (a category, a hadith) keep the bar visible.
/// - Tapping the current section's button returns to its first page.
/// - System back closes the open page, then returns to the first section, then leaves the app.
/// - Sections are built the first time they are opened.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.features, this.prayer});

  final FeatureFlags features;

  /// The prayer section's services; without them that section shows its placeholder.
  final PrayerServices? prayer;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final List<ShellTab> _tabs = [
    ShellTab.hadiths,
    if (widget.features.quran) ShellTab.quran,
    if (widget.features.prayer) ShellTab.prayer,
    ShellTab.more,
  ];
  late final List<GlobalKey<NavigatorState>> _navigators = [
    for (final _ in _tabs) GlobalKey<NavigatorState>(),
  ];
  late final List<_StackObserver> _observers = [
    for (final _ in _tabs) _StackObserver(_stackChanged),
  ];
  final Set<int> _opened = {0};
  int _index = 0;

  NavigatorState? get _currentNavigator => _navigators[_index].currentState;

  void _stackChanged() {
    // Navigator callbacks can arrive while the tree is building; update afterwards.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _select(int index) {
    if (index == _index) {
      _currentNavigator?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _index = index;
      _opened.add(index);
    });
  }

  Future<void> _handleBack(bool didPop, Object? result) async {
    if (didPop) return;
    if (await (_currentNavigator?.maybePop() ?? Future.value(false))) return;
    if (_index != 0) _select(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The system may leave the app only from the first section with nothing open on top of
    // it; that also keeps the system's back animation for leaving the app.
    final canLeave = _index == 0 && !(_currentNavigator?.canPop() ?? false);
    return PopScope(
      canPop: canLeave,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Offstage(
                offstage: i != _index,
                child: TickerMode(
                  enabled: i == _index,
                  child: TabFade(
                    active: i == _index,
                    child: _opened.contains(i)
                        ? Navigator(
                            key: _navigators[i],
                            observers: [_observers[i]],
                            onGenerateRoute: (_) => _rootRoute(_tabs[i]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Semantics(
          container: true,
          label: l10n.navigationLabel,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final tab in _tabs)
                NavigationDestination(
                  icon: Icon(_icon(tab, selected: false)),
                  selectedIcon: Icon(_icon(tab, selected: true)),
                  label: _label(l10n, tab),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The hadith section keeps the platform's own transitions (it is the released app); the other
  /// sections use the app's transition for their whole stack, starting with this first page.
  Route<void> _rootRoute(ShellTab tab) {
    const settings = RouteSettings(name: '/');
    Widget build(BuildContext _) => _root(tab);
    return tab == ShellTab.hadiths
        ? MaterialPageRoute<void>(settings: settings, builder: build)
        : appRoute<void>(settings: settings, builder: build);
  }

  Widget _root(ShellTab tab) => switch (tab) {
    ShellTab.hadiths => const HomePage(inShell: true),
    ShellTab.quran => ComingSoonPage(
      title: context.l10n.navQuran,
      icon: Icons.auto_stories_outlined,
    ),
    ShellTab.prayer =>
      widget.prayer == null
          ? ComingSoonPage(
              title: context.l10n.navPrayer,
              icon: Icons.mosque_outlined,
            )
          : PrayerPage(services: widget.prayer!),
    ShellTab.more => const MorePage(),
  };

  static String _label(AppLocalizations l10n, ShellTab tab) => switch (tab) {
    ShellTab.hadiths => l10n.navHadiths,
    ShellTab.quran => l10n.navQuran,
    ShellTab.prayer => l10n.navPrayer,
    ShellTab.more => l10n.navMore,
  };

  static IconData _icon(ShellTab tab, {required bool selected}) =>
      switch (tab) {
        ShellTab.hadiths =>
          selected ? Icons.menu_book : Icons.menu_book_outlined,
        ShellTab.quran =>
          selected ? Icons.auto_stories : Icons.auto_stories_outlined,
        ShellTab.prayer => selected ? Icons.mosque : Icons.mosque_outlined,
        ShellTab.more => Icons.menu,
      };
}

/// Tells the shell when a section's stack changes, so back handling stays correct.
class _StackObserver extends NavigatorObserver {
  _StackObserver(this._onChange);

  final VoidCallback _onChange;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChange();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChange();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChange();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _onChange();
}

/// Fades a section in when it is selected. The section is built and usable straight away; only its
/// opacity animates (150 ms), and with "remove animations" on it simply appears.
class TabFade extends StatefulWidget {
  const TabFade({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.short,
    value: 1,
  );

  @override
  void didUpdateWidget(TabFade old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !context.reduceMotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: CurvedAnimation(parent: _controller, curve: AppMotion.enter),
    child: widget.child,
  );
}
