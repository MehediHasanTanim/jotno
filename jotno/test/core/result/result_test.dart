import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/result/app_failure.dart';
import 'package:jotno/core/result/result.dart';

import '../../support/dart_source.dart';

/// `Result` is the shape every one of the fifty-eight remaining stories will
/// return across a layer boundary. What is worth testing is not that a wrapper
/// holds a value — it is the two properties that make it worth having: both
/// branches are reachable and neither can be skipped, and there is no way to
/// ask for a value and be handed `null` instead.
void main() {
  group('success', () {
    test('carries its value and reports itself as a success', () {
      const result = Result<int, AppFailure>.success(7);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result, isA<Success<int, AppFailure>>());
      expect((result as Success<int, AppFailure>).value, 7);
    });

    test('is destructured by a pattern without a null check', () {
      const Result<int, AppFailure> result = Success(7);

      final int read = switch (result) {
        Success(:final value) => value,
        Failure() => fail('a success matched the failure branch'),
      };

      expect(read, 7);
    });

    test('fold takes the success branch', () {
      const Result<int, AppFailure> result = Success(7);

      expect(
        result.fold(
          onSuccess: (value) => 'ok $value',
          onFailure: (failure) => 'no ${failure.localisationKey}',
        ),
        'ok 7',
      );
    });

    test('map transforms the value and keeps the failure type', () {
      const Result<int, AppFailure> result = Success(7);

      expect(
        result.map((value) => value * 2),
        const Success<int, AppFailure>(14),
      );
    });

    test('flatMap chains a second fallible step', () {
      const Result<int, AppFailure> result = Success(7);

      expect(
        result.flatMap<int>((value) => Success<int, AppFailure>(value + 1)),
        const Success<int, AppFailure>(8),
      );
      expect(
        result.flatMap<int>(
          (value) => const Failure<int, AppFailure>(StorageFailure()),
        ),
        const Failure<int, AppFailure>(StorageFailure()),
      );
    });

    test('mapFailure leaves a success alone', () {
      const Result<int, AppFailure> result = Success(7);

      final mapped = result.mapFailure<StateError>(
        (failure) => fail('mapFailure ran the transform on a success'),
      );

      expect(mapped, isA<Success<int, StateError>>());
      expect((mapped as Success<int, StateError>).value, 7);
    });

    test('valueOr returns the value, not the fallback', () {
      const Result<int, AppFailure> result = Success(7);

      expect(result.valueOr(-1), 7);
    });

    test('toString reports the shape and not the value', () {
      // A success can be carrying a member name or a lab value. The one place
      // a `Result` could plausibly reach a console is its `toString`, so it
      // says what kind of result this is and nothing about its contents.
      const Result<String, AppFailure> result = Success('Rehana Begum');

      expect(result.toString(), 'Success<String>');
      expect(result.toString(), isNot(contains('Rehana')));
    });
  });

  group('failure', () {
    test('carries its failure and reports itself as a failure', () {
      const result = Result<int, AppFailure>.failure(NotFoundFailure());

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(
        (result as Failure<int, AppFailure>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('is destructured by a pattern without a null check', () {
      const Result<int, AppFailure> result = Failure(NotFoundFailure());

      final String key = switch (result) {
        Success() => fail('a failure matched the success branch'),
        Failure(:final failure) => failure.localisationKey,
      };

      expect(key, 'failureNotFound');
    });

    test('fold takes the failure branch', () {
      const Result<int, AppFailure> result = Failure(StorageFailure());

      expect(
        result.fold(
          onSuccess: (value) => 'ok $value',
          onFailure: (failure) => 'no ${failure.localisationKey}',
        ),
        'no failureStorage',
      );
    });

    test('map does not run the transform and keeps the failure', () {
      const Result<int, AppFailure> result = Failure(StorageFailure());

      final mapped = result.map<int>(
        (value) => fail('map ran the transform on a failure'),
      );

      expect(mapped, const Failure<int, AppFailure>(StorageFailure()));
    });

    test('flatMap does not run the transform and keeps the failure', () {
      const Result<int, AppFailure> result = Failure(StorageFailure());

      final mapped = result.flatMap<int>(
        (value) => fail('flatMap ran the transform on a failure'),
      );

      expect(mapped, const Failure<int, AppFailure>(StorageFailure()));
    });

    test('mapFailure translates a lower layer failure into this layer', () {
      const Result<int, AppFailure> result = Failure(StorageFailure());

      final mapped = result.mapFailure<AppFailure>(
        (failure) => const UnexpectedFailure(),
      );

      expect(mapped, const Failure<int, AppFailure>(UnexpectedFailure()));
    });

    test('valueOr returns the fallback', () {
      const Result<int, AppFailure> result = Failure(StorageFailure());

      expect(result.valueOr(-1), -1);
    });

    test('toString renders the failure, which carries no message', () {
      const Result<int, AppFailure> result = Failure(StorageFailure());

      expect(result.toString(), 'Failure<int>(StorageFailure(failureStorage))');
    });
  });

  group('equality', () {
    test('successes are equal when their values are', () {
      expect(
        const Success<int, AppFailure>(7),
        const Success<int, AppFailure>(7),
      );
      expect(
        const Success<int, AppFailure>(7),
        isNot(const Success<int, AppFailure>(8)),
      );
    });

    test('failures are equal when their failures are', () {
      expect(
        const Failure<int, AppFailure>(StorageFailure()),
        const Failure<int, AppFailure>(StorageFailure()),
      );
      expect(
        const Failure<int, AppFailure>(StorageFailure()),
        isNot(const Failure<int, AppFailure>(NotFoundFailure())),
      );
    });

    test('a success is never equal to a failure', () {
      expect(
        const Success<int, AppFailure>(7),
        isNot(const Failure<int, AppFailure>(StorageFailure())),
      );
    });
  });

  group('chaining a Result that has not arrived yet', () {
    // Every repository in the remaining stories returns a Future<Result<...>>.
    // Without these each caller writes the same await-then-switch and rebuilds
    // the failure branch by hand, which is the accretion this story exists to
    // prevent.

    Future<Result<int, AppFailure>> ok(int value) async => Success(value);
    Future<Result<int, AppFailure>> bad() async =>
        const Failure(StorageFailure());

    test('mapAsync transforms a success', () async {
      expect(
        await ok(7).mapAsync((value) async => value * 2),
        const Success<int, AppFailure>(14),
      );
    });

    test('mapAsync accepts a synchronous transform too', () async {
      expect(
        await ok(7).mapAsync((value) => value * 2),
        const Success<int, AppFailure>(14),
      );
    });

    test('mapAsync short-circuits on a failure', () async {
      expect(
        await bad().mapAsync<int>(
          (value) => fail('mapAsync ran the transform on a failure'),
        ),
        const Failure<int, AppFailure>(StorageFailure()),
      );
    });

    test('flatMapAsync chains a second fallible step', () async {
      expect(
        await ok(7).flatMapAsync<int>((value) => ok(value + 1)),
        const Success<int, AppFailure>(8),
      );
      expect(
        await ok(7).flatMapAsync<int>((value) => bad()),
        const Failure<int, AppFailure>(StorageFailure()),
      );
    });

    test('flatMapAsync short-circuits on a failure', () async {
      expect(
        await bad().flatMapAsync<int>(
          (value) => fail('flatMapAsync ran the transform on a failure'),
        ),
        const Failure<int, AppFailure>(StorageFailure()),
      );
    });

    test('a chain of several steps stops at the first failure', () async {
      var stepsRun = 0;

      final result = await ok(1)
          .flatMapAsync<int>((value) {
            stepsRun++;
            return bad();
          })
          .flatMapAsync<int>((value) {
            stepsRun++;
            return ok(value);
          });

      expect(result, const Failure<int, AppFailure>(StorageFailure()));
      expect(stepsRun, 1, reason: 'the step after the failure still ran');
    });

    test('mapFailureAsync translates a failure and leaves a success', () async {
      expect(
        await bad().mapFailureAsync<AppFailure>(
          (failure) => const NotFoundFailure(),
        ),
        const Failure<int, AppFailure>(NotFoundFailure()),
      );
      expect(
        await ok(7).mapFailureAsync<AppFailure>(
          (failure) => fail('mapFailureAsync ran the transform on a success'),
        ),
        const Success<int, AppFailure>(7),
      );
    });
  });

  group('no path yields null', () {
    // The guarantee is a type-level one: there is no `valueOrNull`, no
    // nullable `failure` getter, and no member declared to return `T?` or
    // `F?`. A caller therefore cannot receive `null` and cannot forget to
    // check for it, which is the ambiguity the type exists to remove.
    //
    // This cannot be asserted by calling the code — the offending call would
    // not compile — so it is asserted against the declaration.
    final code = readPackageCode('lib/core/result/result.dart');

    test('declares no nullable value or failure type', () {
      expect(
        RegExp(r'\bT\?').hasMatch(code),
        isFalse,
        reason:
            'result.dart declares a nullable success value. Handing back null '
            'for "it failed" reintroduces the ambiguity Result removes: null '
            'cannot say why, and a caller that forgets the check compiles.',
      );
      expect(
        RegExp(r'\bF\?').hasMatch(code),
        isFalse,
        reason: 'result.dart declares a nullable failure type.',
      );
    });

    test('declares none of the usual nullable escape hatches', () {
      for (final escapeHatch in const [
        'valueOrNull',
        'failureOrNull',
        'getOrNull',
        'errorOrNull',
      ]) {
        expect(
          code,
          isNot(contains(escapeHatch)),
          reason: '$escapeHatch reintroduces nullable unwrapping.',
        );
      }
    });
  });
}
