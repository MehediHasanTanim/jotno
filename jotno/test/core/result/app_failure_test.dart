import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/result/app_failure.dart';
import 'package:jotno/core/result/result.dart';
import 'package:jotno/main.dart';

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

    test('every key is a plain identifier', () {
      // ARB keys become generated Dart getters, so anything else fails at
      // codegen time in Story 1.3 rather than here. The same check runs over
      // StartupFailure in startup_surface_test.dart.
      for (final failure in appFailureVariants) {
        expect(
          RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(failure.localisationKey),
          isTrue,
          reason:
              '${failure.localisationKey} is not a lowerCamelCase identifier, '
              'so gen_l10n cannot turn it into a getter',
        );
      }
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

  group('the two key namespaces do not collide', () {
    // Story 1.3 merges these into one ARB file. Two mechanisms producing keys
    // independently is exactly how a duplicate arrives, and a duplicate ARB
    // key is a build failure at best and a silently wrong message at worst.
    test('no AppFailure key equals a StartupFailure key', () {
      final failureKeys = appFailureVariants
          .map((failure) => failure.localisationKey)
          .toSet();
      final startupKeys = StartupFailure.values
          .map((reason) => reason.localisationKey)
          .toSet();

      expect(
        failureKeys.intersection(startupKeys),
        isEmpty,
        reason:
            'the same key is produced by both hierarchies; Story 1.3 will '
            'write one ARB entry and one of the two will get the other one'
            "'s wording",
      );
    });

    test('every key across both namespaces is unique', () {
      final allKeys = <String>[
        ...appFailureVariants.map((failure) => failure.localisationKey),
        ...StartupFailure.values.map((reason) => reason.localisationKey),
      ];

      expect(allKeys.toSet(), hasLength(allKeys.length));
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

    test('renders without an error type when none is known', () {
      expect(const UnexpectedFailure().errorType, isNull);
      expect(
        const UnexpectedFailure().toString(),
        'UnexpectedFailure(failureUnexpected)',
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

  group('no AppFailure can hold text', () {
    // A `String message` field would end up holding `error.toString()`, and
    // `SqliteException.toString()` prints its causing statement — which for
    // the key pragma is the database key.
    test('the declarations contain no free-text shape', () {
      final code = readPackageCode('lib/core/result/app_failure.dart');

      expect(
        freeTextShapesIn(code),
        isEmpty,
        reason:
            'app_failure.dart declares somewhere text can sit. A failure '
            'carries a localisation key and a Type, never words.',
      );
    });

    // The test of the test. Each shape below is one a reviewer or a hurried
    // author would actually write, and each must be rejected — the first
    // version of this guard matched only `String message;` and let the
    // nullable and initialiser forms straight through.
    const rejected = <String>[
      'final String message;',
      'final String? message;',
      "String message = '';",
      "final String message = 'x';",
      'late String note;',
      'final List<String> notes;',
      'final Map<String, Object?> extras;',
      'final dynamic payload;',
      'final Object? blob;',
      'void record(String note);',
      'const ValidationFailure(this.field, String reason);',
    ];

    for (final shape in rejected) {
      test('rejects `$shape`', () {
        expect(
          freeTextShapesIn(shape),
          isNotEmpty,
          reason: 'this shape can carry a diagnosis and the guard missed it',
        );
      });
    }

    // The declarations that are actually in the file and must stay allowed.
    // A guard that fires on these gets deleted by the next person.
    const allowed = <String>[
      "String get localisationKey => 'failureStorage';",
      "String toString() => 'StorageFailure(failureStorage)';",
      'bool operator ==(Object other) => other is StorageFailure;',
      'int get hashCode => Object.hash(UnexpectedFailure, errorType);',
      'final Type? errorType;',
      'typedef AppResult<T> = Result<T, AppFailure>;',
      'typedef FutureResult<T> = Future<AppResult<T>>;',
      'const UnexpectedFailure({this.errorType});',
    ];

    for (final shape in allowed) {
      test('allows `$shape`', () {
        expect(
          freeTextShapesIn(shape),
          isEmpty,
          reason: 'a false positive here would get the whole guard deleted',
        );
      });
    }
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

    test('FutureResult is an AppResult that has not arrived', () async {
      FutureResult<int> load() async => const Success(4);

      expect(await load(), const Success<int, AppFailure>(4));
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
