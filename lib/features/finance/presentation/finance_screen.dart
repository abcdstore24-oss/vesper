import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'account_form_sheet.dart';
import 'accounts_list_screen.dart';
import 'categories_list_screen.dart';
import 'category_form_sheet.dart';
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
    _tabController = TabController(length: 3, vsync: this)
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
          tabs: const [Tab(text: 'Accounts'), Tab(text: 'Categories'), Tab(text: 'Transactions')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [AccountsListScreen(), CategoriesListScreen(), TransactionsListScreen()],
      ),
      floatingActionButton: FloatingActionButton(
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