import '../../l10n/app_localizations.dart';
import '../result/app_failure.dart';

/// Turning an [AppFailure] into something a reader can read.
///
/// `AppFailure` carries a [AppFailure.localisationKey] and no message, which
/// is what keeps free text — and therefore a condition name or a medication
/// name — out of the failure model entirely. This extension is the other half
/// of that arrangement: the one place where a key becomes a sentence.
///
/// It is a `switch` over the sealed hierarchy rather than a lookup by key,
/// because `AppLocalizations` generates a getter per message and not a map.
/// The consequence is the useful one: adding a variant to `AppFailure` without
/// adding its message here does not compile.
extension AppFailureMessage on AppFailure {
  /// This failure's message in [strings]' language.
  ///
  /// Never contains anything derived from the failure itself.
  /// [UnexpectedFailure.errorType] in particular is diagnostic, not something
  /// to show a reader, so it is not interpolated here or anywhere else.
  String message(AppLocalizations strings) => switch (this) {
    StorageFailure() => strings.failureStorage,
    ValidationFailure() => strings.failureValidation,
    NotFoundFailure() => strings.failureNotFound,
    PermissionFailure() => strings.failurePermission,
    UnexpectedFailure() => strings.failureUnexpected,
  };
}
