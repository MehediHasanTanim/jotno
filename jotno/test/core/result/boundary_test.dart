import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/result/app_failure.dart';
import 'package:jotno/core/result/boundary.dart';
import 'package:jotno/core/result/result.dart';

/// The matrix says an unexpected exception is converted to an `AppFailure` at
/// the boundary and never rethrown outward. `Boundary` is the one `try`/`catch`
/// that does it, so the properties worth pinning are that it catches
/// everything, that it lets the data layer classify what it recognises, and
/// that the original error stops here.
void main() {
  group('guard', () {
    test('returns the value when nothing throws', () {
      expect(Boundary.guard(() => 7), const Success<int, AppFailure>(7));
    });

    test('converts a thrown exception into an unexpected failure', () {
      final result = Boundary.guard<int>(
        () => throw const FormatException('bad'),
      );

      expect(
        result,
        const Failure<int, AppFailure>(
          UnexpectedFailure(errorType: FormatException),
        ),
      );
    });

    test('catches an Error, not only an Exception', () {
      // A `catch` that names only `Exception` lets a StateError from a bug in
      // the data layer straight through the boundary, which costs the reader
      // whatever they were in the middle of recording.
      final result = Boundary.guard<int>(() => throw StateError('a bug'));

      expect(result.isFailure, isTrue);
      expect(
        result,
        const Failure<int, AppFailure>(
          UnexpectedFailure(errorType: StateError),
        ),
      );
    });

    test('lets the caller classify what it recognises', () {
      // How a data layer maps its own store's exceptions without core knowing
      // anything about sqlite.
      final result = Boundary.guard<int>(
        () => throw const FormatException('bad'),
        onError: (error) => const StorageFailure(),
      );

      expect(result, const Failure<int, AppFailure>(StorageFailure()));
    });

    test('the original error does not survive the boundary', () {
      // The error is dropped here and nowhere else, so there is no later point
      // at which someone can decide to render its message.
      const secret = 'super-secret-key';
      final result = Boundary.guard<int>(
        () => throw StateError("pragma key = '$secret'"),
      );

      expect(result.toString(), isNot(contains(secret)));
      switch (result) {
        case Success():
          fail('the throw did not become a failure');
        case Failure(:final failure):
          expect(failure.toString(), isNot(contains(secret)));
          expect(failure.localisationKey, 'failureUnexpected');
      }
    });
  });

  group('guardAsync', () {
    test('returns the value when nothing throws', () async {
      expect(
        await Boundary.guardAsync(() async => 7),
        const Success<int, AppFailure>(7),
      );
    });

    test('catches a rejected future rather than letting it escape', () async {
      // The `await` is inside the `try`, so the rejection is caught here
      // instead of arriving at whoever awaits the result.
      final result = await Boundary.guardAsync<int>(
        () async => throw const FormatException('bad'),
      );

      expect(
        result,
        const Failure<int, AppFailure>(
          UnexpectedFailure(errorType: FormatException),
        ),
      );
    });

    test('catches a synchronous throw from the callback', () async {
      final result = await Boundary.guardAsync<int>(
        () => throw StateError('thrown before the future exists'),
      );

      expect(result.isFailure, isTrue);
    });

    test('catches a timeout', () async {
      final result = await Boundary.guardAsync<int>(
        () => Completer<int>().future.timeout(const Duration(milliseconds: 10)),
      );

      expect(
        result,
        const Failure<int, AppFailure>(
          UnexpectedFailure(errorType: TimeoutException),
        ),
      );
    });

    test('lets the caller classify what it recognises', () async {
      final result = await Boundary.guardAsync<int>(
        () async => throw const FormatException('bad'),
        onError: (error) => const NotFoundFailure(),
      );

      expect(result, const Failure<int, AppFailure>(NotFoundFailure()));
    });

    test('returns a FutureResult, the shape repositories will use', () {
      FutureResult<int> load() => Boundary.guardAsync(
        () async => 1,
        onError: (_) => const StorageFailure(),
      );

      expect(load(), isA<FutureResult<int>>());
    });
  });
}
