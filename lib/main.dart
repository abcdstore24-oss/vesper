import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeModeNotifier.initialMode = await ThemeModeNotifier.loadPersisted();
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
    );
  }
}
