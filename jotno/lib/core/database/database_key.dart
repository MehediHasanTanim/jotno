import 'package:flutter/foundation.dart';

/// The seam through which the database encryption key reaches the connection.
///
/// Story 1.1 ships a development implementation returning a constant. Story
/// 1.13 replaces it with the double-wrapped data encryption key — one wrap held
/// in platform secure storage, one derived from the recovery phrase — without
/// any caller of this interface changing.
abstract interface class DatabaseKeyProvider {
  /// Returns the key passed to `PRAGMA key` when the database is opened.
  ///
  /// The returned value is used verbatim (after SQL escaping) as a passphrase.
  /// It is never logged.
  Future<String> databaseKey();
}

/// Thrown when [DevelopmentKeyProvider] is used in a release build.
final class DevelopmentKeyInReleaseBuildError extends UnsupportedError {
  /// Creates the error.
  DevelopmentKeyInReleaseBuildError()
    : super(
        'DevelopmentKeyProvider was reached in a release build. Its key is '
        'compiled into the binary and identical on every install, so the '
        'database would be encrypted with a key anyone can read out of the '
        'APK. Story 1.13 must supply the double-wrapped data encryption key '
        'before a release ships.',
      );
}

/// A [DatabaseKeyProvider] returning a fixed, non-secret constant.
///
/// This exists so Story 1.1 can prove the cipher end to end before real key
/// management exists. It provides no confidentiality whatsoever: the key is
/// compiled into the binary and identical on every install.
///
/// Because a TODO is not a gate, [databaseKey] throws
/// [DevelopmentKeyInReleaseBuildError] in release builds. Forgetting Story
/// 1.13 therefore cannot ship a shared, extractable key — it produces a
/// release binary that refuses to start.
///
/// TODO(story-1.13): Replace with the double-wrapped DEK provider. Losing
/// platform secure storage must cost a prompt, not the data, so the recovery
/// phrase must be able to reconstruct the key on its own. No code may assume
/// secure storage survives. Delete this class and its release guard once that
/// provider exists.
final class DevelopmentKeyProvider implements DatabaseKeyProvider {
  /// Creates a provider returning [key], defaulting to [developmentKey].
  const DevelopmentKeyProvider({this.key = developmentKey});

  /// The constant used when no other key is supplied.
  static const String developmentKey = 'jotno-development-key';

  /// The key this provider hands out.
  final String key;

  @override
  Future<String> databaseKey() async {
    if (kReleaseMode) {
      throw DevelopmentKeyInReleaseBuildError();
    }
    return key;
  }
}
