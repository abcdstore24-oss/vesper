import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/db_provider.dart';
import '../../../core/services/app_lock_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../lock/presentation/pin_setup_screen.dart';
import '../data/data_export_service.dart';
/// Settings screen scaffold.
///
/// Theme mode, App Lock, and Data export are all wired to real
/// functionality. Change PIN / Forgot PIN are deferred — see
/// DECISIONS.md.

enum _ExportChoice { share, downloads }

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
          const _ExportDataRow(),
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
          child: RadioGroup<AppLockMode>(
            groupValue: currentMode,
            onChanged: (mode) async {
              if (mode == null) return;
              Navigator.of(sheetContext).pop();
              switch (mode) {
                case AppLockMode.os:
                  await ref.read(appLockModeProvider.notifier).setMode(AppLockMode.os);
                case AppLockMode.pin:
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                  );
                case AppLockMode.off:
                  _confirmTurnOff(context, ref);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<AppLockMode>(
                  title: Text('Device lock (biometric/PIN)'),
                  subtitle: Text('Recommended'),
                  value: AppLockMode.os,
                ),
                RadioListTile<AppLockMode>(
                  title: Text('Custom PIN'),
                  value: AppLockMode.pin,
                ),
                RadioListTile<AppLockMode>(
                  title: Text('Off'),
                  value: AppLockMode.off,
                ),
              ],
            ),
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

/// Phase 1, Task 8/8b: real "Export my data" row.
///
/// Offers a choice between the existing Share sheet and, on Android,
/// a direct save to the public Downloads folder via file_saver's
/// saveAs() — see task response for why saveAs() over a raw MediaStore
/// plugin.
class _ExportDataRow extends ConsumerStatefulWidget {
  const _ExportDataRow();

  @override
  ConsumerState<_ExportDataRow> createState() => _ExportDataRowState();
}

class _ExportDataRowState extends ConsumerState<_ExportDataRow> {
  bool _isBusy = false;

  Future<void> _onTap() async {
    if (_isBusy) return;

    final choice = await showModalBottomSheet<_ExportChoice>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.shareNetwork),
              title: const Text('Share...'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_ExportChoice.share),
            ),
            if (Platform.isAndroid)
              ListTile(
                leading: const Icon(PhosphorIconsRegular.downloadSimple),
                title: const Text('Save to Downloads'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_ExportChoice.downloads),
              ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;
    switch (choice) {
      case _ExportChoice.share:
        await _share();
      case _ExportChoice.downloads:
        await _saveToDownloads();
    }
  }

  Future<void> _share() async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      final db = ref.read(appDatabaseProvider);
      final path = await DataExportService(db).exportToFile();
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)], text: 'Vesper data export');
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: errorColor,
          content: const Text(
            "Export failed — couldn't write the file. Please try again.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _saveToDownloads() async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      final db = ref.read(appDatabaseProvider);
      final savedPath = await DataExportService(db).saveToDownloads();
      if (!mounted) return;
      if (savedPath == null) {
        // User cancelled the system Save As dialog — not an error,
        // nothing to report.
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('Saved to $savedPath')));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: errorColor,
          content: const Text("Couldn't save the file. Please try again."),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        PhosphorIconsRegular.export,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text('Export my data', style: theme.textTheme.bodyLarge),
      trailing: _isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              PhosphorIconsRegular.caretRight,
              color: theme.colorScheme.onSurfaceVariant,
            ),
      onTap: _isBusy ? null : _onTap,
    );
  }
}