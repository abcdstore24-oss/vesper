import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'core/services/app_lock_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/lock/presentation/lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeModeNotifier.initialMode = await ThemeModeNotifier.loadPersisted();
  AppLockModeNotifier.initialMode = await AppLockModeNotifier.loadPersisted();
  runApp(const ProviderScope(child: VesperApp()));
}

class VesperApp extends ConsumerWidget {
  const VesperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Vesper',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AppShell(),
      builder: (context, child) =>
          _LockOverlay(child: child ?? const SizedBox.shrink()),
    );
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
      if (ref.read(appLockModeProvider) != AppLockMode.off) {
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