import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db_bootstrap.dart';
import 'db_provider.dart';

/// The device-local user id (`user_profile.user_id`).
///
/// Calls [ensureLocalUser], which is idempotent: it creates the
/// user_profile row if it is missing and otherwise returns the existing
/// id. So this is correct even if the startup bootstrap failed silently in
/// a release build, and reading it again (or after `ref.invalidate`)
/// never creates a second row or changes the id.
final localUserIdProvider = FutureProvider<String>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ensureLocalUser(db);
});
