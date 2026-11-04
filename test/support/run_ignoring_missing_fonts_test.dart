import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test_helpers.dart';

// The message google_fonts throws (from the failing test output).
const _missingFont =
    'GoogleFonts.config.allowRuntimeFetching is false but font Karla-Regular '
    'was not found in the application assets. Ensure the font file is '
    'declared in pubspec.yaml.';

/// Runs [body] inside an OUTER guarded zone that collects every error that
/// reaches it, then lets pending async work finish. `runIgnoringMissingFonts`
/// is called from inside that outer zone, so whatever the filter re-reports
/// lands in the returned list.
Future<List<Object>> collectOuterErrors(void Function() body) async {
  final reached = <Object>[];
  runZonedGuarded(body, (error, stackTrace) => reached.add(error));
  // Unhandled future errors are reported after the microtask queue drains.
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return reached;
}

/// A google_fonts-shaped failure: an async function that throws, with a
/// `.then` that has no error handler (so the derived future errors unhandled).
Future<void> failLikeGoogleFonts(Object error) async {
  throw error;
}

void main() {
  group('isMissingFontError', () {
    test('matches only the google_fonts missing-asset Exception', () {
      expect(isMissingFontError(Exception(_missingFont)), isTrue);
    });

    test('needs BOTH message fragments', () {
      expect(
        isMissingFontError(
          Exception('allowRuntimeFetching is false but font X is odd'),
        ),
        isFalse,
      );
      expect(
        isMissingFontError(
          Exception('font X was not found in the application assets'),
        ),
        isFalse,
      );
    });

    test('an Error is never matched, even with the same message', () {
      expect(isMissingFontError(StateError(_missingFont)), isFalse);
      expect(isMissingFontError(ArgumentError(_missingFont)), isFalse);
    });

    test('other errors and objects are not matched', () {
      expect(isMissingFontError(const FormatException('bad')), isFalse);
      expect(isMissingFontError(_missingFont), isFalse); // a thrown String
      expect(isMissingFontError(Exception('anything else')), isFalse);
    });
  });

  group('runIgnoringMissingFonts', () {
    test('(a) ignores the google_fonts exception, even from async work', () async {
      final reached = await collectOuterErrors(() {
        runIgnoringMissingFonts(() {
          unawaited(
            failLikeGoogleFonts(Exception(_missingFont)).then((_) {}),
          );
          unawaited(
            Future<void>.delayed(
              const Duration(milliseconds: 5),
              () => throw Exception(_missingFont),
            ),
          );
        });
      });

      expect(reached, isEmpty);
    });

    test('(b) a StateError is NOT swallowed and reaches the outer zone', () async {
      final error = StateError('boom');
      final reached = await collectOuterErrors(() {
        runIgnoringMissingFonts(() {
          unawaited(failLikeGoogleFonts(error).then((_) {}));
        });
      });

      expect(reached, hasLength(1));
      expect(identical(reached.single, error), isTrue); // unchanged
    });

    test('(b) a StateError with the font message is still reported', () async {
      final reached = await collectOuterErrors(() {
        runIgnoringMissingFonts(() {
          unawaited(
            failLikeGoogleFonts(StateError(_missingFont)).then((_) {}),
          );
        });
      });

      expect(reached.single, isA<StateError>());
    });

    test('(b) other errors are reported: Argument, Format, String', () async {
      final reached = await collectOuterErrors(() {
        runIgnoringMissingFonts(() {
          unawaited(failLikeGoogleFonts(ArgumentError('a')).then((_) {}));
          unawaited(
            failLikeGoogleFonts(const FormatException('f')).then((_) {}),
          );
          unawaited(failLikeGoogleFonts('plain string').then((_) {}));
        });
      });

      expect(reached, hasLength(3));
      expect(reached.whereType<ArgumentError>(), hasLength(1));
      expect(reached.whereType<FormatException>(), hasLength(1));
      expect(reached.whereType<String>(), hasLength(1));
    });

    test('(b) an Exception without the full message is reported', () async {
      final reached = await collectOuterErrors(() {
        runIgnoringMissingFonts(() {
          unawaited(
            failLikeGoogleFonts(
              Exception('allowRuntimeFetching is false but font X'),
            ).then((_) {}),
          );
        });
      });

      expect(reached, hasLength(1));
    });

    test('a mix: only the non-font error gets through', () async {
      final real = StateError('real problem');
      final reached = await collectOuterErrors(() {
        runIgnoringMissingFonts(() {
          unawaited(
            failLikeGoogleFonts(Exception(_missingFont)).then((_) {}),
          );
          unawaited(failLikeGoogleFonts(real).then((_) {}));
          unawaited(
            failLikeGoogleFonts(Exception(_missingFont)).then((_) {}),
          );
        });
      });

      expect(reached, hasLength(1));
      expect(identical(reached.single, real), isTrue);
    });

    test('a synchronous error in the body is reported, result is null', () async {
      int? result = 123;
      final reached = await collectOuterErrors(() {
        result = runIgnoringMissingFonts<int>(() => throw StateError('sync'));
      });

      expect(result, isNull);
      expect(reached.single, isA<StateError>());
    });

    test('returns the body\'s value when nothing goes wrong', () {
      expect(runIgnoringMissingFonts(() => 42), 42);
    });
  });

  group('buildTestTheme', () {
    setUpAll(disableFontFetching);

    testWidgets('builds the real light and dark themes', (tester) async {
      final light = buildTestTheme(Brightness.light);
      final dark = buildTestTheme(Brightness.dark);

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.chipTheme.showCheckmark, isFalse);
    });
  });
}
