import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_shell.dart';
import 'core/db/db_provider.dart';
import 'core/services/app_lock_provider.dart';
import 'core/services/remote_status_provider.dart';
import 'core/services/remote_status_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/lock/presentation/lock_screen.dart';
import 'features/status/presentation/kill_switch_screen.dart';
import 'features/status/presentation/maintenance_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeModeNotifier.initialMode = await ThemeModeNotifier.loadPersisted();
  AppLockModeNotifier.initialMode = await AppLockModeNotifier.loadPersisted();

  // Cold-start remote-status-flash fix: create the container manually
  // so we can read appDatabaseProvider here and get the SAME
  // AppDatabase instance (same SQLCipher connection) the rest of the
  // app will use — never a second AppDatabase. Then run one real query
  // against remote_status_cache and seed the notifier's initial state
  // with it, so the very first frame already reflects the true cached
  // Maintenance/KillSwitch status instead of falling back to `open`
  // for a frame.
  final container = ProviderContainer();
  final db = container.read(appDatabaseProvider);
  final cachedRow = await db.getRemoteStatusOnce();
  EffectiveRemoteStatusNotifier.initialStatus = cachedRow == null
      ? EffectiveRemoteStatus.open
      : EffectiveRemoteStatus(
          maintenanceMode: cachedRow.maintenanceMode,
          maintenanceMessage: cachedRow.maintenanceMessage,
          killSwitch: cachedRow.killSwitch,
        );

  // AI/API.md "Remote app control": a public, no-login project. The
  // anon key is meant to be client-embedded, not a secret — RLS grants
  // SELECT-only to the anon role on app_status, nothing here can
  // write. Supabase.initialize() itself is local/synchronous-ish (no
  // network round trip), safe to await before runApp; the actual
  // status *check* below is fired separately, non-blocking.
  await Supabase.initialize(
    url: 'https://kgezuhrygxozuaechxga.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtnZXp1aHJ5Z3hvenVhZWNoeGdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAyMzIzODcsImV4cCI6MjEwNTgwODM4N30.9xcDJBKrtubrcGOjkEk9BqlHEQSHqpgyZ2VH2MkGlvI',
  );

  // UncontrolledProviderScope (NOT a fresh ProviderScope): the whole
  // widget tree must share this exact container, so appDatabaseProvider
  // resolves to the same AppDatabase we just queried above, not a
  // second instance.
  runApp(UncontrolledProviderScope(container: container, child: const VesperApp()));
}

class VesperApp extends ConsumerStatefulWidget {
  const VesperApp({super.key});

  @override
  ConsumerState<VesperApp> createState() => _VesperAppState();
}

class _VesperAppState extends ConsumerState<VesperApp> {
  @override
  void initState() {
    super.initState();
    // Opportunistic check on app start, per API.md. Fire-and-forget:
    // checkAndCache() is fully self-contained about failure — no
    // connectivity, a timeout, or any fetch error leaves
    // remote_status_cache untouched — and this deliberately never
    // gates the first frame, even in the 5s-timeout worst case.
    Future.microtask(() {
      RemoteStatusService(ref.read(appDatabaseProvider)).checkAndCache();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Vesper',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AppShell(),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        // Layering, outermost to innermost — approved in task response:
        // Kill switch > App Lock > Maintenance > app. Kill switch wins
        // over Lock (nothing to protect behind a dead end); Maintenance
        // sits INSIDE Lock deliberately, so a maintenance window
        // clearing while the phone is unattended never hands over the
        // app without having required a PIN.
        return _KillSwitchGate(
          child: _LockOverlay(child: _MaintenanceGate(child: content)),
        );
      },
    );
  }
}

/// Outermost gate. See build()'s comment above for the ordering
/// rationale.
class _KillSwitchGate extends ConsumerWidget {
  const _KillSwitchGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(effectiveRemoteStatusProvider);
    if (status.killSwitch) return const KillSwitchScreen();
    return child;
  }
}

/// Innermost gate — sits INSIDE _LockOverlay on purpose. See build()'s
/// comment above.
class _MaintenanceGate extends ConsumerWidget {
  const _MaintenanceGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(effectiveRemoteStatusProvider);
    if (status.maintenanceMode) {
      return MaintenanceScreen(message: status.maintenanceMessage);
    }
    return child;
  }
}

class _LockOverlay extends ConsumerStatefulWidget {
  const _LockOverlay({required this.child});

  final Widget child;

  @override
  ConsumerState<_LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends ConsumerState<_LockOverlay>
    with WidgetsBindingObserver {
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!ref.read(authPromptActiveProvider)) {
        _wasBackgrounded = true;
      }
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      // Don't (re-)lock into a prompt if kill switch is already
      // active: _KillSwitchGate already fully blocks the app above
      // this widget, so there's nothing left to protect, and locking
      // here is exactly what starts the native biometric prompt that
      // then floats over KillSwitchScreen once this subtree gets
      // unmounted. See lock_screen.dart's ref.listen for the mid-
      // prompt case (kill switch flips true while already locked).
      final killSwitchAlreadyActive =
          ref.read(effectiveRemoteStatusProvider).killSwitch;
      if (!killSwitchAlreadyActive &&
          ref.read(appLockModeProvider) != AppLockMode.off) {
        ref.read(isUnlockedProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appLockModeProvider);
    final isUnlocked = ref.watch(isUnlockedProvider);
    final locked = mode != AppLockMode.off && !isUnlocked;

    return Stack(
      children: [
        widget.child,
        if (locked) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}