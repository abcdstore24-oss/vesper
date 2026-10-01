import 'package:flutter/material.dart';

import 'summary_screen.dart';

/// Named SummaryPage, not SummaryScreen — that name is already the
/// inner widget's (summary_screen.dart), so this wrapper needed a
/// distinct name (task response). Read-only, no FAB.
class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: const SummaryScreen(),
    );
  }
}