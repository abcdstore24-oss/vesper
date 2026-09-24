import 'dart:convert';
import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/db/app_database.dart';

/// Builds and writes the CLAUDE.md Section 6 data export: every
/// non-Vault table in [AppDatabase], as a single JSON file.
///
/// **Generalization (task response flag #2):** iterates
/// [AppDatabase.allTables] and calls each row's generated `toJson()`
/// rather than hand-listing fields, so a new Finance/Notes/Goals/etc.
/// table added in a later phase is picked up automatically — this file
/// needs no edit — as long as it is not added to [_excludedTableNames]
/// below.
///
/// **Vault exclusion (task response flag #4):** this is a plain
/// denylist of SQL table names, not a type-level marker, so it is only
/// as safe as remembering to add each Vault table's name here the
/// moment it's created in Phase 3. See the flag in the task response
/// for a stronger (type-level) alternative if the owner wants a harder
/// guarantee later — that alternative would require touching
/// app_database.dart, which this task intentionally left alone.
class DataExportService {
  const DataExportService(this._db);

  final AppDatabase _db;

  /// SQL table names deliberately excluded from every export.
  ///
  /// - `remote_status_cache`: device-state cache (maintenance/kill-switch
  ///   status), not user data a person would want to "restore" — see
  ///   task response flag #1, please confirm this reasoning.
  /// - Phase 3: the moment `vault_items`, `vault_document_refs`, and
  ///   `vault_recovery_meta` exist, add their SQL names here BEFORE any
  ///   code path that could export them ships. This set is the single,
  ///   deliberate place that decision is made — per API.md's Vault hard
  ///   rule, Vault data must never leave the device in plaintext.
  static const _excludedTableNames = <String>{'remote_status_cache'};

  /// Builds the export and writes it to the app's documents directory.
  ///
  /// Returns the written file's absolute path. Throws on any failure
  /// (query error, disk-full, permission error, etc.) — writes to a
  /// temp file first and renames on success, so a failure partway
  /// through never leaves a half-written export file behind.
  Future<String> exportToFile() async {
    final tables = <String, List<Map<String, dynamic>>>{};

    for (final table in _db.allTables) {
      if (_excludedTableNames.contains(table.actualTableName)) continue;

      final rows = await _db.select(table).get();
      tables[table.actualTableName] = rows
          .map((row) => (row as dynamic).toJson() as Map<String, dynamic>)
          .toList();
    }

    final payload = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    };

    final dir = await getApplicationDocumentsDirectory();
    final dateStamp = DateTime.now().toIso8601String().split('T').first;
    final finalFile = File(p.join(dir.path, 'vesper_export_$dateStamp.json'));
    final tempFile = File('${finalFile.path}.tmp');

    try {
      await tempFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
        flush: true,
      );
      final written = await tempFile.rename(finalFile.path);
      return written.path;
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  /// Builds a fresh export (via [exportToFile]) and hands it to the
  /// OS's own "Save As" picker — `file_saver`'s `saveAs()`, which uses
  /// the Storage Access Framework on Android — so the user places the
  /// file directly in a public location (typically Downloads) with
  /// zero custom permissions and zero unaudited native plugin code.
  /// Reuses [exportToFile] rather than duplicating the table-building
  /// loop, so there is exactly one place the export's contents are
  /// decided.
  ///
  /// **Android-only for now** (task response flag #3): iOS already
  /// gets an equivalent via the existing Share sheet's "Save to Files"
  /// action, so callers should only surface this option on Android —
  /// this method itself doesn't guard on platform, since that's a UI
  /// decision, not a data one.
  ///
  /// Returns the path the user chose, or `null` if they cancelled the
  /// system dialog — that is **not** an error, callers should treat a
  /// null result as a silent no-op, not a failure to report.
  Future<String?> saveToDownloads() async {
    final sourcePath = await exportToFile();
    final baseName = p.basenameWithoutExtension(sourcePath);

    return FileSaver.instance.saveAs(
      name: baseName,
      file: File(sourcePath),
      fileExtension: 'json',
      // MimeType.custom + customMimeType is used instead of betting on
      // a specific MimeType.json enum member existing in this package
      // version — see task response.
      mimeType: MimeType.custom,
      customMimeType: 'application/json',
    );
  }
}