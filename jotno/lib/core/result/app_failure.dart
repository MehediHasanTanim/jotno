import 'package:flutter/foundation.dart';

import 'result.dart';

/// A [Result] whose failure side is always an [AppFailure].
///
/// Every layer boundary in Jotno returns one of these.
typedef AppResult<T> = Result<T, AppFailure>;

/// An [AppResult] that has not arrived yet.
///
/// The shape every repository method in the remaining stories returns. Chain
/// these with `mapAsync` and `flatMapAsync` rather than awaiting and switching
/// by hand — see `FutureResultChaining` in `result.dart`.
typedef FutureResult<T> = Future<AppResult<T>>;

/// Why an operation failed, in terms a layer boundary may hand outward.
///
/// Sealed, so a `switch` over a failure is exhaustive and adding a variant
/// breaks every caller that has to care.
///
/// **An [AppFailure] never carries a message.** It carries a
/// [localisationKey], and Story 1.3 resolves that key against the ARB files in
/// the reader's language. A `String message` field would be a free-text hole
/// straight into the UI and into any log that renders a failure, and free text
/// in this app means a condition name or a medication name sooner or later.
///
/// The keys are literal constants, not derived from `runtimeType`. A rename or
/// an obfuscated release build must not be able to change which string a
/// reader sees.
@immutable
sealed class AppFailure {
  /// Const constructor for the variants below.
  const AppFailure();

  /// The ARB key naming the message to show for this failure.
  ///
  /// Stable across renames, unique across variants, and never empty.
  String get localisationKey;
}

/// Reading or writing the local database failed.
///
/// Disk full, file locked, I/O error — anything where the store itself is the
/// problem rather than what was asked of it.
@immutable
final class StorageFailure extends AppFailure {
  /// Creates a storage failure.
  const StorageFailure();

  @override
  String get localisationKey => 'failureStorage';

  @override
  bool operator ==(Object other) => other is StorageFailure;

  @override
  int get hashCode => (StorageFailure).hashCode;

  @override
  String toString() => 'StorageFailure($localisationKey)';
}

/// The input was rejected before anything was written.
///
/// Deliberately carries no field name and no offending value: the value is
/// health data by default, and the field is the caller's own business.
@immutable
final class ValidationFailure extends AppFailure {
  /// Creates a validation failure.
  const ValidationFailure();

  @override
  String get localisationKey => 'failureValidation';

  @override
  bool operator ==(Object other) => other is ValidationFailure;

  @override
  int get hashCode => (ValidationFailure).hashCode;

  @override
  String toString() => 'ValidationFailure($localisationKey)';
}

/// The requested record does not exist, or is soft-deleted.
@immutable
final class NotFoundFailure extends AppFailure {
  /// Creates a not-found failure.
  const NotFoundFailure();

  @override
  String get localisationKey => 'failureNotFound';

  @override
  bool operator ==(Object other) => other is NotFoundFailure;

  @override
  int get hashCode => (NotFoundFailure).hashCode;

  @override
  String toString() => 'NotFoundFailure($localisationKey)';
}

/// The operating system withheld a permission the operation needed.
///
/// Per the epic's rules a denial hides the control rather than leaving a
/// broken affordance, so this exists mainly for the paths that cannot check
/// beforehand.
@immutable
final class PermissionFailure extends AppFailure {
  /// Creates a permission failure.
  const PermissionFailure();

  @override
  String get localisationKey => 'failurePermission';

  @override
  bool operator ==(Object other) => other is PermissionFailure;

  @override
  int get hashCode => (PermissionFailure).hashCode;

  @override
  String toString() => 'PermissionFailure($localisationKey)';
}

/// Something no one anticipated happened inside a boundary.
///
/// This is what a `catch (error)` at a layer boundary converts an unexpected
/// exception into, so the exception never travels outward.
///
/// [errorType] is a [Type], not a name and not a message, and that is the
/// point. A `String` field here would end up holding
/// `error.toString()` — and `SqliteException.toString()` prints its causing
/// statement, which for the key pragma is the database key. A [Type] can carry
/// the diagnostic value of "it was a `FileSystemException`" and nothing else.
@immutable
final class UnexpectedFailure extends AppFailure {
  /// Creates an unexpected failure, optionally recording [errorType].
  const UnexpectedFailure({this.errorType});

  /// Creates an unexpected failure recording only the runtime type of [error].
  ///
  /// The error itself is dropped here, at the boundary, so there is no later
  /// point at which someone can decide to render its message.
  factory UnexpectedFailure.from(Object error) =>
      UnexpectedFailure(errorType: error.runtimeType);

  /// The type of the original error, when one is known.
  final Type? errorType;

  @override
  String get localisationKey => 'failureUnexpected';

  @override
  bool operator ==(Object other) =>
      other is UnexpectedFailure && other.errorType == errorType;

  @override
  int get hashCode => Object.hash(UnexpectedFailure, errorType);

  @override
  String toString() {
    final type = errorType == null ? '' : ', errorType: $errorType';
    return 'UnexpectedFailure($localisationKey$type)';
  }
}

/// One instance of every [AppFailure] variant.
///
/// Exists so a test — and, from Story 1.3, the l10n parity check — can walk
/// the whole hierarchy, which Dart cannot enumerate at runtime.
///
/// `test/core/result/app_failure_test.dart` reads this file and fails if a
/// variant is declared above without being listed here, so the list cannot
/// silently fall behind the hierarchy.
const List<AppFailure> appFailureVariants = <AppFailure>[
  StorageFailure(),
  ValidationFailure(),
  NotFoundFailure(),
  PermissionFailure(),
  UnexpectedFailure(),
];
