import 'package:flutter/material.dart';

import 'charts_screen.dart';

/// Same naming reasoning as summary_page.dart — ChartsScreen is
/// already taken by the inner widget (charts_screen.dart). Read-only,
/// no FAB.
class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: const ChartsScreen(),
    );
  }
}