import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../beauty/presentation/beauty_placeholder_screen.dart';
import '../../events/presentation/events_placeholder_screen.dart';
import '../../goals/presentation/goals_placeholder_screen.dart';
import '../../health/presentation/health_placeholder_screen.dart';
import '../../notes/presentation/notes_placeholder_screen.dart';
import '../../recipes/presentation/recipes_placeholder_screen.dart';
import '../../wishlist/presentation/wishlist_placeholder_screen.dart';

/// Lists every module not promoted to the bottom nav bar (Notes, Goals,
/// Birthdays & Events, Recipes, Beauty, Health, Wishlist) — see
/// DECISIONS.md for the signed-off nav structure.
///
/// Plain Navigator.push/MaterialPageRoute — core Flutter navigation,
/// not a router package (Section 2 doesn't name one, and this task was
/// explicit about not adding go_router/auto_route).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <_MoreItem>[
      _MoreItem(
        'Notes',
        PhosphorIconsRegular.notebook,
        const NotesPlaceholderScreen(),
      ),
      _MoreItem(
        'Goals',
        PhosphorIconsRegular.target,
        const GoalsPlaceholderScreen(),
      ),
      _MoreItem(
        'Birthdays & Events',
        PhosphorIconsRegular.calendarHeart,
        const EventsPlaceholderScreen(),
      ),
      _MoreItem(
        'Recipes',
        PhosphorIconsRegular.cookingPot,
        const RecipesPlaceholderScreen(),
      ),
      _MoreItem(
        'Beauty',
        PhosphorIconsRegular.sparkle,
        const BeautyPlaceholderScreen(),
      ),
      _MoreItem(
        'Health',
        PhosphorIconsRegular.heartbeat,
        const HealthPlaceholderScreen(),
      ),
      _MoreItem(
        'Wishlist',
        PhosphorIconsRegular.star,
        const WishlistPlaceholderScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: theme.colorScheme.outline),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            leading: Icon(item.icon, color: theme.colorScheme.onSurface),
            title: Text(item.label, style: theme.textTheme.bodyLarge),
            trailing: Icon(
              PhosphorIconsRegular.caretRight,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => item.screen)),
          );
        },
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem(this.label, this.icon, this.screen);

  final String label;
  final IconData icon;
  final Widget screen;
}
