import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'account_form_sheet.dart';
import 'accounts_list_screen.dart';
import 'categories_list_screen.dart';
import 'category_form_sheet.dart';

/// Finance module home — Task 2.1 scope only. Transactions/Budgets/
/// Investments (later Phase 2 tasks) are not wired in here; each gets
/// its own tab when its own task lands.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Accounts'), Tab(text: 'Categories')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [AccountsListScreen(), CategoriesListScreen()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0
            ? showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AccountFormSheet(),
              )
            : showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const CategoryFormSheet(),
              ),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
    );
  }
}