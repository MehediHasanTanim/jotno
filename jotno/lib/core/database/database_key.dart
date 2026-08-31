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

/// A [DatabaseKeyProvider] returning a fixed, non-secret constant.
///
/// This exists so Story 1.1 can prove the cipher end to end before real key
/// management exists. It provides no confidentiality whatsoever: the key is
/// compiled into the binary and identical on every install.
///
/// TODO(story-1.13): Replace with the double-wrapped DEK provider. Losing
/// platform secure storage must cost a prompt, not the data, so the recovery
/// phrase must be able to reconstruct the key on its own. No code may assume
/// secure storage survives.
final class DevelopmentKeyProvider implements DatabaseKeyProvider {
  /// Creates a provider returning [key], defaulting to [developmentKey].
  const DevelopmentKeyProvider({this.key = developmentKey});

  /// The constant used when no other key is supplied.
  static const String developmentKey = 'jotno-development-key';

  /// The key this provider hands out.
  final String key;

  @override
  Future<String> databaseKey() async => key;
}
