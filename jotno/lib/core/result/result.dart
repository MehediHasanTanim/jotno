import 'dart:async';

import 'package:flutter/foundation.dart';

/// The outcome of an operation that can fail.
///
/// Every layer boundary in Jotno returns one of these instead of throwing:
/// `data` hands a [Result] to `domain`, `domain` hands one to `presentation`.
/// An exception that escapes a repository is a defect, not a control-flow
/// mechanism — see `AppFailure` for the failure side of the contract.
///
/// The type is sealed, so a `switch` over it is exhaustive and the compiler
/// refuses to let a caller forget the failure branch:
///
/// ```dart
/// switch (await repository.load(id)) {
///   case Success(:final value):
///     show(value);
///   case Failure(:final failure):
///     showMessageFor(failure.localisationKey);
/// }
/// ```
///
/// There is deliberately no `valueOrNull` and no nullable `failure` getter.
/// Handing back `null` for "it failed" reintroduces exactly the ambiguity this
/// type exists to remove: `null` cannot say *why*, and a caller that forgets
/// the null check compiles. Read the value through a pattern, [fold] or
/// [valueOr], all three of which force the failure case to be considered.
@immutable
sealed class Result<T, F extends Object> {
  /// Const constructor for the two variants below.
  const Result();

  /// A successful outcome carrying [value].
  const factory Result.success(T value) = Success<T, F>;

  /// A failed outcome carrying [failure].
  const factory Result.failure(F failure) = Failure<T, F>;

  /// Whether this is a [Success].
  bool get isSuccess;

  /// Whether this is a [Failure].
  bool get isFailure;

  /// Collapses both variants to a single [R].
  ///
  /// Both branches are required, so a failure cannot be skipped by omission.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(F failure) onFailure,
  });

  /// Applies [transform] to a success value, leaving a failure untouched.
  Result<R, F> map<R>(R Function(T value) transform);

  /// Chains another fallible operation onto a success value.
  ///
  /// The difference from [map] is that [transform] may itself fail, so the
  /// result is not nested.
  Result<R, F> flatMap<R>(Result<R, F> Function(T value) transform);

  /// Applies [transform] to a failure, leaving a success untouched.
  ///
  /// Used at a layer boundary to translate a lower layer's failure into this
  /// layer's vocabulary.
  Result<T, G> mapFailure<G extends Object>(G Function(F failure) transform);

  /// The success value, or [fallback] when this is a [Failure].
  T valueOr(T fallback);
}

/// A [Result] that succeeded.
@immutable
final class Success<T, F extends Object> extends Result<T, F> {
  /// Creates a successful result carrying [value].
  const Success(this.value);

  /// The value the operation produced.
  final T value;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(F failure) onFailure,
  }) => onSuccess(value);

  @override
  Result<R, F> map<R>(R Function(T value) transform) =>
      Success<R, F>(transform(value));

  @override
  Result<R, F> flatMap<R>(Result<R, F> Function(T value) transform) =>
      transform(value);

  @override
  Result<T, G> mapFailure<G extends Object>(G Function(F failure) transform) =>
      Success<T, G>(value);

  @override
  T valueOr(T fallback) => value;

  @override
  bool operator ==(Object other) =>
      other is Success<T, F> && other.value == value;

  @override
  int get hashCode => Object.hash(Success<T, F>, value);

  /// The type of the value, never the value.
  ///
  /// A success can be carrying a member name or a lab value, and this string
  /// is the one part of a [Result] that could plausibly reach a log or a
  /// console. It reports the shape of the result and nothing about its
  /// contents, for the same reason health entities render as type and id only.
  @override
  String toString() => 'Success<$T>';
}

/// A [Result] that failed.
@immutable
final class Failure<T, F extends Object> extends Result<T, F> {
  /// Creates a failed result carrying [failure].
  const Failure(this.failure);

  /// Why the operation failed.
  final F failure;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(F failure) onFailure,
  }) => onFailure(failure);

  @override
  Result<R, F> map<R>(R Function(T value) transform) => Failure<R, F>(failure);

  @override
  Result<R, F> flatMap<R>(Result<R, F> Function(T value) transform) =>
      Failure<R, F>(failure);

  @override
  Result<T, G> mapFailure<G extends Object>(G Function(F failure) transform) =>
      Failure<T, G>(transform(failure));

  @override
  T valueOr(T fallback) => fallback;

  @override
  bool operator ==(Object other) =>
      other is Failure<T, F> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Failure<T, F>, failure);

  /// Safe to render in full: an `AppFailure` carries a localisation key and a
  /// type, never a message and never anything derived from user data.
  @override
  String toString() => 'Failure<$T>($failure)';
}

/// Chaining on a [Result] that has not arrived yet.
///
/// Every repository in the remaining stories returns a `Future<Result<...>>`,
/// and without these each caller writes the same `await`-then-`switch` and
/// then rebuilds the failure branch by hand. That is exactly the accretion
/// this story exists to prevent, so the combinators live here once:
///
/// ```dart
/// final result = await repository
///     .loadMember(id)
///     .flatMapAsync((member) => repository.loadConditions(member.id));
/// ```
///
/// A failure short-circuits: the transform never runs, and the original
/// failure is carried through unchanged.
extension FutureResultChaining<T, F extends Object> on Future<Result<T, F>> {
  /// Applies [transform] to a success value once it arrives.
  Future<Result<R, F>> mapAsync<R>(
    FutureOr<R> Function(T value) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => Success<R, F>(await transform(value)),
      Failure(:final failure) => Failure<R, F>(failure),
    };
  }

  /// Chains another fallible, asynchronous step onto a success value.
  Future<Result<R, F>> flatMapAsync<R>(
    FutureOr<Result<R, F>> Function(T value) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => await transform(value),
      Failure(:final failure) => Failure<R, F>(failure),
    };
  }

  /// Applies [transform] to a failure once it arrives.
  Future<Result<T, G>> mapFailureAsync<G extends Object>(
    FutureOr<G> Function(F failure) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => Success<T, G>(value),
      Failure(:final failure) => Failure<T, G>(await transform(failure)),
    };
  }
}
