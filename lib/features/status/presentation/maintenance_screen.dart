import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/db_provider.dart';
import '../../../core/services/remote_status_service.dart';
import '../../../core/theme/app_spacing.dart';

/// Maintenance-mode screen. Shows the cached `maintenance_message`,
/// and re-checks `app_status` on a timer (approved: 30s) while it's
/// mounted, so it clears itself automatically once a fresh successful
/// check comes back false — no relaunch needed. The re-check writes to
/// remote_status_cache; effectiveRemoteStatusProvider watches that
/// table reactively, so clearing this screen needs no manual
/// navigation here — it just stops being built once the status flips.
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({required this.message, super.key});

  final String? message;

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  static const _recheckInterval = Duration(seconds: 30);

  Timer? _recheckTimer;

  @override
  void initState() {
    super.initState();
    _recheckTimer = Timer.periodic(_recheckInterval, (_) => _recheck());
  }

  @override
  void dispose() {
    _recheckTimer?.cancel();
    super.dispose();
  }

  void _recheck() {
    RemoteStatusService(ref.read(appDatabaseProvider)).checkAndCache();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.message?.trim();
    final hasCustomMessage = message != null && message.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.moonStars,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Vesper is taking a short break',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasCustomMessage
                      ? message
                      : "We'll be back shortly. Your data stays on "
                            'this device the whole time.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'This will update automatically.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}