import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../features/dashboard/presentation/dashboard_placeholder_screen.dart';
import '../features/finance/presentation/finance_placeholder_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/tasks/presentation/tasks_placeholder_screen.dart';
import '../features/vault/presentation/vault_placeholder_screen.dart';
import 'nav_index_provider.dart';

/// Top-level navigation shell.
///
/// Bottom bar: Dashboard, Finance, Vault, Tasks, More — signed off this
/// session (see DECISIONS.md). Everything else (Notes, Goals,
/// Birthdays & Events, Recipes, Beauty, Health, Wishlist) lives behind
/// More.
///
/// Uses [IndexedStack], not a router package — Section 2's stack table
/// doesn't name one, and this task's scope is a flat set of tabs, not
/// multi-page stacks within a module. IndexedStack keeps every tab's
/// widget subtree alive (not rebuilt) when you switch away and back,
/// which is also what makes tab selection survive backgrounding for
/// free, without extra state-restoration code.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = <Widget>[
    DashboardPlaceholderScreen(),
    FinancePlaceholderScreen(),
    VaultPlaceholderScreen(),
    TasksPlaceholderScreen(),
    MoreScreen(),
  ];

  static final _destinations = <_NavItem>[
    _NavItem(
      label: 'Dashboard',
      regular: PhosphorIconsRegular.house,
      selected: PhosphorIconsFill.house,
    ),
    _NavItem(
      label: 'Finance',
      regular: PhosphorIconsRegular.wallet,
      selected: PhosphorIconsFill.wallet,
    ),
    _NavItem(
      label: 'Vault',
      regular: PhosphorIconsRegular.lockKey,
      selected: PhosphorIconsFill.lockKey,
    ),
    _NavItem(
      label: 'Tasks',
      regular: PhosphorIconsRegular.checkSquare,
      selected: PhosphorIconsFill.checkSquare,
    ),
    _NavItem(
      label: 'More',
      regular: PhosphorIconsRegular.dotsThreeCircle,
      selected: PhosphorIconsFill.dotsThreeCircle,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(navIndexProvider.notifier).setIndex(i),
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.regular),
              selectedIcon: Icon(item.selected),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.regular,
    required this.selected,
  });

  final String label;
  final IconData regular;
  final IconData selected;
}
