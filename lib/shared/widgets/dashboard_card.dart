import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Reusable card shell for Dashboard sections: an icon + title header,
/// with a flexible body slot below.
///
/// Card color/radius/border/shadow come entirely from ThemeData's
/// `cardTheme` (wired from AppColors/AppRadius in app_theme.dart) —
/// this widget deliberately never re-specifies AppRadius.card or a
/// surface color directly, continuing the Theme.of(context)-first
/// convention from the nav-shell task. AppSpacing is imported directly
/// only for internal padding/gaps, since ThemeData has no layout slot.
///
/// Registered in COMPONENTS.md.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  /// Convenience constructor for the common case: an icon, a title, and
  /// one muted line of body copy. All 6 empty-state module cards use
  /// this, and the greeting card uses it for both its populated and
  /// empty states, for visual consistency.
  factory DashboardCard.emptyState({
    Key? key,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return DashboardCard(
      key: key,
      icon: icon,
      title: title,
      child: _EmptyStateBody(message: message),
    );
  }

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyStateBody extends StatelessWidget {
  const _EmptyStateBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
