import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/result/app_failure.dart';
import 'package:jotno/core/result/result.dart';

import '../../support/dart_source.dart';

/// The localisation keys are a contract with Story 1.3: it wires each key to
/// an ARB entry in Bangla and English. A key that is missing, duplicated, or
/// derived from something that can change at build time turns into a blank
/// error message on a real device, which is the one moment the reader most
/// needs words.
void main() {
  group('localisation keys', () {
    test('every variant has a non-empty key', () {
      for (final failure in appFailureVariants) {
        expect(
          failure.localisationKey,
          isNotEmpty,
          reason: '$failure has no localisation key',
        );
      }
    });

    test('every variant has a distinct key', () {
      final keys = appFailureVariants
          .map((failure) => failure.localisationKey)
          .toList();

      expect(
        keys.toSet(),
        hasLength(keys.length),
        reason:
            'two variants share a key, so one of them cannot be worded '
            'differently from the other',
      );
    });

    test('the keys are exactly the agreed strings', () {
      // Pinned rather than computed. Story 1.3 writes these strings into the
      // ARB files; changing one here without changing it there produces a
      // missing translation, and this test is the thing that notices.
      expect(
        {
          for (final failure in appFailureVariants)
            failure.runtimeType.toString(): failure.localisationKey,
        },
        {
          'StorageFailure': 'failureStorage',
          'ValidationFailure': 'failureValidation',
          'NotFoundFailure': 'failureNotFound',
          'PermissionFailure': 'failurePermission',
          'UnexpectedFailure': 'failureUnexpected',
        },
      );
    });

    test('every key is a literal in the source, not a derived name', () {
      // `runtimeType` is unreliable in an obfuscated release build and changes
      // under a rename, either of which would silently repoint a message.
      final code = readPackageCode('lib/core/result/app_failure.dart');

      for (final failure in appFailureVariants) {
        expect(
          code,
          contains("'${failure.localisationKey}'"),
          reason:
              '${failure.runtimeType} does not return a literal key, so a '
              'rename or an obfuscated build can change which string a reader '
              'sees.',
        );
      }
    });
  });

  group('the variant list covers the sealed hierarchy', () {
    // Dart cannot enumerate a sealed hierarchy at runtime, so
    // `appFailureVariants` is written by hand — and a hand-written list falls
    // behind. This reads the declarations back and fails when it has.
    test('every declared variant appears in appFailureVariants', () {
      final code = readPackageCode('lib/core/result/app_failure.dart');
      final declared = RegExp(
        r'class\s+(\w+)\s+(?:extends|implements)\s+AppFailure',
      ).allMatches(code).map((match) => match.group(1)!).toSet();

      expect(
        declared,
        isNotEmpty,
        reason:
            'found no AppFailure subclasses, so this test is scanning '
            'nothing and would pass whatever happened',
      );
      expect(
        appFailureVariants
            .map((failure) => failure.runtimeType.toString())
            .toSet(),
        declared,
        reason:
            'appFailureVariants has fallen behind the sealed hierarchy. '
            'Add the missing variant so the key checks above and Story 1.3s '
            'ARB coverage see it.',
      );
    });
  });

  group('UnexpectedFailure', () {
    test('records the type of the original error and nothing else', () {
      final failure = UnexpectedFailure.from(
        StateError('database is at /data/user/0/app/jotno.sqlite'),
      );

      expect(failure.errorType, StateError);
      expect(failure.toString(), contains('StateError'));
      expect(failure.toString(), isNot(contains('jotno.sqlite')));
    });

    test('has no field that can hold a message', () {
      // A `String` field here would end up holding `error.toString()`, and
      // `SqliteException.toString()` prints its causing statement — which for
      // the key pragma is the database key.
      final code = readPackageCode('lib/core/result/app_failure.dart');

      expect(
        RegExp(r'\bString\b\s+\w+\s*;').hasMatch(code),
        isFalse,
        reason:
            'an AppFailure declares a String field. A failure carries a '
            'localisation key and a type, never text.',
      );
    });

    test('two unexpected failures of the same error type are equal', () {
      expect(
        UnexpectedFailure.from(StateError('a')),
        UnexpectedFailure.from(StateError('b')),
      );
      expect(
        UnexpectedFailure.from(StateError('a')),
        isNot(UnexpectedFailure.from(ArgumentError('a'))),
      );
    });
  });

  group('AppResult', () {
    test('is a Result whose failure side is an AppFailure', () {
      const AppResult<int> ok = Success(1);
      const AppResult<int> bad = Failure(PermissionFailure());

      expect(ok, isA<Result<int, AppFailure>>());
      expect(
        bad.fold(onSuccess: (_) => '', onFailure: (f) => f.localisationKey),
        'failurePermission',
      );
    });
  });

  group('rendering', () {
    test('a failure renders its key, never a message', () {
      for (final failure in appFailureVariants) {
        expect(failure.toString(), contains(failure.localisationKey));
      }
    });
  });
}
