import 'app_failure.dart';
import 'result.dart';

/// The point at which an exception stops being an exception.
///
/// The rule is that nothing throws across a layer boundary, and a rule that
/// every repository re-implements by hand is a rule one of them will get
/// wrong — a missing `catch`, a `catch (e)` that rethrows, a `catch` that
/// only names `Exception` and so lets an `Error` straight through. This is
/// that `try`/`catch`, written once:
///
/// ```dart
/// FutureResult<Member> loadMember(String id) => Boundary.guardAsync(
///   () => _dao.memberById(id),
///   onError: (error) => const StorageFailure(),
/// );
/// ```
///
/// **It catches `Object`, not `Exception`.** A `StateError` from a bug in the
/// data layer is not something the reader can act on, and letting it escape
/// costs them whatever they were in the middle of recording. It arrives as
/// `failureUnexpected` with the error's type attached, which is the most that
/// can be said about it without saying too much.
///
/// The error itself is dropped here and nowhere else, so there is no later
/// point at which someone can decide to render its message. `onError` receives
/// it, but can only answer with an [AppFailure] — a type with nowhere to put
/// text.
abstract final class Boundary {
  /// Runs [operation], converting anything it throws into an [AppFailure].
  ///
  /// [onError] classifies the error — a data layer maps its own store's
  /// exceptions to [StorageFailure], for instance. Without it, everything
  /// becomes an [UnexpectedFailure] carrying the error's type.
  static AppResult<T> guard<T>(
    T Function() operation, {
    AppFailure Function(Object error)? onError,
  }) {
    try {
      return Success<T, AppFailure>(operation());
    } on Object catch (error) {
      return Failure<T, AppFailure>(_classify(error, onError));
    }
  }

  /// The asynchronous [guard].
  ///
  /// Awaits inside the `try`, so a rejected future is caught here rather than
  /// escaping to whoever awaits the result.
  static FutureResult<T> guardAsync<T>(
    Future<T> Function() operation, {
    AppFailure Function(Object error)? onError,
  }) async {
    try {
      return Success<T, AppFailure>(await operation());
    } on Object catch (error) {
      return Failure<T, AppFailure>(_classify(error, onError));
    }
  }

  static AppFailure _classify(
    Object error,
    AppFailure Function(Object error)? onError,
  ) => onError == null ? UnexpectedFailure.from(error) : onError(error);
}
