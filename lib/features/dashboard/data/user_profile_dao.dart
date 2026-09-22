import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';

/// Minimal query support for the Dashboard's greeting card — the single
/// local user_profile row (single-user-today per CLAUDE.md Section 1).
///
/// A plain extension method rather than a full @DriftAccessor DAO
/// class: this screen needs exactly one query, and a DAO class would
/// require another `build_runner` codegen pass for no real benefit at
/// this scale. Uses AppDatabase's already-generated `userProfile` table
/// accessor directly — no new codegen needed for this file.
extension UserProfileDao on AppDatabase {
  /// Watches the single user_profile row, or null if none exists yet
  /// (the table starts empty — no onboarding flow creates a row
  /// automatically; that's a later task).
  Stream<UserProfileRow?> watchUserProfile() {
    return (select(userProfile)..limit(1)).watchSingleOrNull();
  }
}

/// Riverpod-friendly wrapper around [UserProfileDao.watchUserProfile].
final userProfileProvider = StreamProvider<UserProfileRow?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchUserProfile();
});
