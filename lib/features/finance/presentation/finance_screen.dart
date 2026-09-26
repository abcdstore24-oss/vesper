import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'account_form_sheet.dart';
import 'accounts_list_screen.dart';
import 'budgets_list_screen.dart';
import 'categories_list_screen.dart';
import 'category_form_sheet.dart';
import 'summary_screen.dart';
import 'transaction_form_sheet.dart';
import 'transactions_list_screen.dart';

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
    _tabController = TabController(length: 5, vsync: this)
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Accounts'),
            Tab(text: 'Categories'),
            Tab(text: 'Transactions'),
            Tab(text: 'Summary'),
            Tab(text: 'Budgets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AccountsListScreen(),
          CategoriesListScreen(),
          TransactionsListScreen(),
          SummaryScreen(),
          BudgetsListScreen(),
        ],
      ),
      // Summary (3) is read-only, no FAB. Budgets (4) has its own
      // internal Scaffold + FAB (see budgets_list_screen.dart) since
      // its add-form needs that tab's own month state — no shared FAB
      // for either.
      floatingActionButton: (_tabController.index == 3 || _tabController.index == 4)
          ? null
          : FloatingActionButton(
              onPressed: () {
                switch (_tabController.index) {
                  case 0:
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AccountFormSheet(),
                    );
                  case 1:
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const CategoryFormSheet(),
                    );
                  default:
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const TransactionFormSheet(),
                    );
                }
              },
              child: const Icon(PhosphorIconsRegular.plus),
            ),
    );
  }
}