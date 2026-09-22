import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which bottom-nav tab is currently selected.
///
/// Index mapping (must stay in sync with AppShell's tab list, signed
/// off in this session — see DECISIONS.md):
/// 0 = Dashboard, 1 = Finance, 2 = Vault, 3 = Tasks, 4 = More.
///
/// In-memory only — no persistence layer. This task's test criteria
/// only calls for surviving backgrounding (the app staying alive,
/// which keeps this provider's state intact), not surviving a full
/// process kill/cold restart. If that's wanted later, it's a small
/// addition (same flutter_secure_storage pattern as
/// theme_mode_provider.dart), not a redesign.
class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(
  NavIndexNotifier.new,
);
