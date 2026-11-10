import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard for the offline-first fonts (CLAUDE.md Section 3: Fraunces + Karla via
/// google_fonts). The google_fonts package looks for its font files in the
/// app's assets, so the root-level google_fonts/ folder must exist, hold real
/// font files, and be declared in pubspec.yaml. Plain file reads: no widgets.
///
/// The five files are exactly the variants the app requests (see
/// AppTypography and the Karla text theme in AppTheme): Fraunces 500 / 600,
/// Karla 400 / 500 / 600.
void main() {
  const fontFiles = [
    'Fraunces-Medium.ttf',
    'Fraunces-SemiBold.ttf',
    'Karla-Regular.ttf',
    'Karla-Medium.ttf',
    'Karla-SemiBold.ttf',
  ];

  for (final name in fontFiles) {
    group(name, () {
      final file = File('google_fonts/$name');

      test('exists under google_fonts/', () {
        expect(
          file.existsSync(),
          isTrue,
          reason: 'google_fonts/$name is missing',
        );
      });

      test('is larger than 10 KB', () {
        // An error page or an empty download is far smaller.
        expect(file.lengthSync(), greaterThan(10 * 1024));
      });

      test('starts with a valid font header', () {
        final handle = file.openSync();
        final List<int> header;
        try {
          header = handle.readSync(4);
        } finally {
          handle.closeSync();
        }
        final valid =
            _bytesEqual(header, const [0x00, 0x01, 0x00, 0x00]) || // TrueType
            _bytesEqual(header, 'true'.codeUnits) || // Apple TrueType
            _bytesEqual(header, 'OTTO'.codeUnits); // OpenType (CFF)
        expect(
          valid,
          isTrue,
          reason:
              '$name does not start with a font header (an HTML error page '
              'saved as .ttf?). First bytes: $header',
        );
      });
    });
  }

  test('pubspec.yaml declares google_fonts/ under assets', () {
    final lines = File('pubspec.yaml').readAsLinesSync();

    // The real (uncommented) "assets:" key, then its list items.
    final start = lines.indexWhere(
      (l) => RegExp(r'^\s*assets:\s*$').hasMatch(l),
    );
    expect(start, isNot(-1), reason: 'pubspec.yaml has no assets: section');

    final items = <String>[];
    for (final line in lines.skip(start + 1)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      if (!trimmed.startsWith('- ')) break; // the list has ended
      items.add(trimmed.substring(2).trim());
    }
    expect(items, contains('google_fonts/'));
  });
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
