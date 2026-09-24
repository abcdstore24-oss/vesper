import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/services/app_lock_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../lock/presentation/pin_setup_screen.dart';

/// Settings screen scaffold (Phase 1, Task 6).
///
/// Theme mode is wired to the real, already-tested [themeModeProvider].
/// App Lock and Data export are placeholder rows only — their own
/// upcoming TODO.md tasks implement the actual logic; this screen just
/// gives them a permanent, real home in the UI.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final appLockMode = ref.watch(appLockModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(PhosphorIconsRegular.sun),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(PhosphorIconsRegular.moon),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(PhosphorIconsRegular.deviceMobile),
                    ),
                  ],
                  selected: <ThemeMode>{themeMode},
                  onSelectionChanged: (selected) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selected.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const _SectionHeader('Security'),
          _SettingsRow(
            icon: PhosphorIconsRegular.lockKey,
            title: 'App Lock',
            trailing: Text(
              _appLockModeLabel(appLockMode),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => _showAppLockPicker(context, ref, appLockMode),
          ),
          const SizedBox(height: AppSpacing.xl),

          const _SectionHeader('Data'),
          _SettingsRow(
            icon: PhosphorIconsRegular.export,
            title: 'Export my data',
            trailing: const _ComingSoonBadge(),
            onTap: () => _showComingSoon(context, 'Data export'),
          ),
          const SizedBox(height: AppSpacing.xl),

          const _SectionHeader('About'),
          _SettingsRow(
            icon: PhosphorIconsRegular.info,
            title: 'Version',
            trailing: Text(
              '1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              'Vesper is a private, offline-first life-management app for '
              'finance, an encrypted vault, notes, goals, and more.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature — coming soon.')));
  }

  String _appLockModeLabel(AppLockMode mode) {
    switch (mode) {
      case AppLockMode.os:
        return 'Device lock';
      case AppLockMode.pin:
        return 'Custom PIN';
      case AppLockMode.off:
        return 'Off';
    }
  }

  void _showAppLockPicker(
    BuildContext context,
    WidgetRef ref,
    AppLockMode currentMode,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppLockMode>(
                title: const Text('Device lock (biometric/PIN)'),
                subtitle: const Text('Recommended'),
                value: AppLockMode.os,
                groupValue: currentMode,
                onChanged: (_) async {
                  Navigator.of(sheetContext).pop();
                  await ref
                      .read(appLockModeProvider.notifier)
                      .setMode(AppLockMode.os);
                },
              ),
              RadioListTile<AppLockMode>(
                title: const Text('Custom PIN'),
                value: AppLockMode.pin,
                groupValue: currentMode,
                onChanged: (_) async {
                  Navigator.of(sheetContext).pop();
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                  );
                },
              ),
              RadioListTile<AppLockMode>(
                title: const Text('Off'),
                value: AppLockMode.off,
                groupValue: currentMode,
                onChanged: (_) {
                  Navigator.of(sheetContext).pop();
                  _confirmTurnOff(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmTurnOff(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Turn off App Lock?'),
        content: const Text(
          'Anyone with access to your device will be able to open Vesper '
          'without a PIN or biometric check, including Finance and Vault. '
          'You can turn it back on anytime in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref
                  .read(appLockModeProvider.notifier)
                  .setMode(AppLockMode.off);
            },
            child: const Text('Turn Off'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Soon',
        style: theme.textTheme.labelLarge?.copyWith(
          fontSize: 11,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}