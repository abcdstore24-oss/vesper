import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Generic placeholder screen for a module that doesn't have real
/// content yet. TODO.md's later phases replace these one module at a
/// time; this exists only to prove navigation + the design system
/// render correctly on a real screen (Phase 1, Task 4).
///
/// Colors/type come from [Theme.of(context)] (wired from AppColors/
/// AppTypography in app_theme.dart) rather than importing the token
/// files directly — see task response for the reasoning. AppSpacing is
/// the one token imported directly here, since ThemeData has no
/// spacing/layout slot.
///
/// Registered in COMPONENTS.md — reuse this rather than duplicating a
/// Scaffold-with-centered-title per module.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            title,
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
