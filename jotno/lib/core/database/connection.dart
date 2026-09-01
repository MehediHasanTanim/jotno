import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database_key.dart';

/// File name (without extension) of the Jotno database.
///
/// The connection appends `.sqlite`.
const String databaseFileName = 'jotno';

/// The message carried by [MissingCipherError].
const String cipherMissingMessage =
    'Jotno requires the SQLite3MultipleCiphers build. '
    'The shipped library is unencrypted — refusing to open the database.';

/// Thrown when the loaded SQLite library is not the SQLite3MultipleCiphers
/// build, so the database would be written in plaintext.
///
/// Deliberately an [UnsupportedError]: the I/O matrix for this story specifies
/// that type, and callers that only know about `UnsupportedError` still catch
/// it. The named subtype exists so startup can identify this failure by type
/// rather than by string-matching the message.
final class MissingCipherError extends UnsupportedError {
  /// Creates the error with the standard [cipherMissingMessage].
  MissingCipherError() : super(cipherMissingMessage);
}

/// Thrown when the supplied key is empty or contains only whitespace.
///
/// `PRAGMA key = ''` is not an error in SQLite3MultipleCiphers — it leaves the
/// database *unencrypted*. That is the same catastrophe as shipping the wrong
/// library, arriving by a different route, so it is refused before the pragma
/// runs.
final class EmptyDatabaseKeyError extends ArgumentError {
  /// Creates the error. The key itself is never included.
  EmptyDatabaseKeyError()
    : super.value(
        '<redacted>',
        'key',
        'must not be empty or whitespace-only: an empty PRAGMA key leaves the '
            'database unencrypted',
      );
}

/// Thrown when the cipher is present but the supplied key does not unlock the
/// database.
///
/// Deliberately distinct from [MissingCipherError]: "we shipped the wrong
/// library" and "we have the wrong key" are different failures with different
/// remedies, and must never be conflated.
///
/// This type never carries the underlying [SqliteException]. That exception's
/// `toString()` includes its `causingStatement`, which for the key pragma is
/// the key itself.
final class DatabaseKeyRejectedException implements Exception {
  /// Creates the exception for the given SQLite [resultCode], if one is known.
  const DatabaseKeyRejectedException({this.resultCode});

  /// The SQLite primary result code, when the failure came from SQLite.
  ///
  /// Safe to display: it is a small integer, never text derived from the key.
  final int? resultCode;

  @override
  String toString() {
    final code = resultCode == null ? '' : ' (SQLite result code $resultCode)';
    return 'DatabaseKeyRejectedException: the encrypted database could not be '
        'read with the supplied key$code. The database file exists and the '
        'cipher is present, so this is a key problem, not a build problem.';
  }
}

/// Escapes [value] for inlining into a single-quoted SQL string literal.
///
/// `PRAGMA key` does not accept bind parameters, so the key has to be inlined.
/// Doubling `'` is the whole of SQL string escaping.
///
/// Exposed only so the escaping can be tested directly. This is **not** a
/// general-purpose substitute for bind parameters — every other statement in
/// the app must use them.
@visibleForTesting
String escapeSqlStringLiteral(String value) => value.replaceAll("'", "''");

/// Throws unless the loaded SQLite library is SQLite3MultipleCiphers.
///
/// Upstream SQLite answers an unknown pragma with an empty result set rather
/// than an error, so an unencrypted build is silent — which is exactly the
/// failure this check exists to catch.
///
/// This is a `throw`, never an `assert`: asserts are stripped in release, and
/// a release build shipping upstream SQLite is precisely the build that must
/// refuse to start.
void requireEncryptedSqlite(CommonDatabase db) {
  if (db.select('pragma cipher').isEmpty) {
    throw MissingCipherError();
  }
}

/// Prepares a freshly opened [db] for use: cipher check, then key, then
/// everything else.
///
/// The ordering is mandatory. Nothing may run against the connection before
/// `PRAGMA key` — any other pragma or query placed above it reads or writes
/// the database unencrypted.
void configureEncryptedDatabase(CommonDatabase db, String key) {
  // 1. Refuse to continue unless the encrypted build shipped.
  requireEncryptedSqlite(db);

  // 2. Refuse an empty key. This is a check on a value, not a statement, so it
  //    does not disturb the ordering below.
  if (key.trim().isEmpty) {
    throw EmptyDatabaseKeyError();
  }

  // 3. Apply the key. The pragma takes no bind parameters, so escape and
  //    inline. Never log or rethrow this statement — it contains the key, and
  //    SqliteException.toString() prints its causing statement verbatim.
  try {
    db.execute("pragma key = '${escapeSqlStringLiteral(key)}'");
  } on SqliteException catch (cause) {
    throw DatabaseKeyRejectedException(resultCode: cause.resultCode);
  } on Object {
    throw const DatabaseKeyRejectedException();
  }

  // 4. `PRAGMA key` does not validate: a wrong key succeeds above and fails at
  //    some arbitrary later read. Force the failure now, loudly.
  //
  //    Only SQLITE_NOTADB means "this key does not decrypt this file". Busy,
  //    locked, corrupt and I/O errors are different problems with different
  //    remedies, so they propagate as themselves. This statement contains no
  //    key, so rethrowing it leaks nothing.
  try {
    db.execute('select count(*) from sqlite_master');
  } on SqliteException catch (cause) {
    if (cause.resultCode == SqlError.SQLITE_NOTADB) {
      throw DatabaseKeyRejectedException(resultCode: cause.resultCode);
    }
    rethrow;
  }

  // Any further pragmas (WAL, foreign keys, ...) belong below this line, never
  // above it.
}

/// Opens a raw sqlite3 handle on [path].
///
/// Injectable only so the fail-closed verification below can be driven against
/// a library that lacks the cipher, which cannot otherwise be simulated on a
/// host where the correct library is installed.
typedef RawDatabaseOpener = CommonDatabase Function(String path);

/// The real opener: a plain sqlite3 handle on [path].
CommonDatabase openRawDatabase(String path) => sqlite3.open(path);

/// Resolves the database file, creating its directory if needed.
///
/// [databaseDirectory] may return a [Directory] or a path [String] and
/// defaults to the app-support directory.
Future<File> resolveDatabaseFile({
  Future<Object> Function()? databaseDirectory,
}) async {
  final directoryPath = _asPath(
    await (databaseDirectory ?? getApplicationSupportDirectory)(),
    'databaseDirectory',
  );

  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }

  return File('$directoryPath/$databaseFileName.sqlite');
}

/// Points sqlite3 at a temporary directory the app owns, and returns its path.
///
/// sqlite3 spills large intermediate results to a temporary directory, and the
/// global `/tmp` is unreachable from a sandboxed app on some platforms.
Future<String> configureSqliteTempDirectory({
  Future<Object> Function()? temporaryDirectory,
}) async {
  final tempPath = _asPath(
    await (temporaryDirectory ?? getTemporaryDirectory)(),
    'temporaryDirectory',
  );
  sqlite3.tempDirectory = tempPath;
  return tempPath;
}

/// Proves, synchronously and before any drift object exists, that the shipped
/// library is encrypted and the key unlocks [file].
///
/// **This is the fail-closed gate.** It is deliberately plain, synchronous code
/// running on the calling isolate: no drift, no `LazyDatabase`, no background
/// isolate, no future chain that anything could swallow. Whatever it throws
/// lands in the caller's `try`/`catch` with its type intact.
///
/// It exists because an unencrypted build left the app on a black screen with
/// no error on Android — debug and release both — when the check ran inside a
/// `LazyDatabase` opener and startup depended on drift surfacing the throw.
///
/// The mechanism was never pinned down, and `LazyDatabase` is probably not the
/// culprit: it forwards opener errors correctly
/// (`onError: delegate.completeError`), the same lazy arrangement propagates
/// the throw on the host — with directories injected *and* with a mocked
/// `path_provider` channel — and the same code renders the error surface
/// correctly on an iOS device artifact. The hang did not reproduce anywhere
/// except Android hardware.
///
/// One Android-specific hazard fits: with `source: sqlite3` the bundled
/// library is `libsqlite3.so`, the same soname as Android's own system SQLite,
/// which is already loaded in every app process. What `dlopen` returns there
/// is not guaranteed to be the bundled build. `sqlite3mc` has a unique soname
/// and no such collision — so the hazard exists only in the misconfiguration
/// this check is here to catch.
///
/// Whatever the mechanism, the fail-closed guarantee must not depend on it.
/// Do not move this check back behind a drift abstraction, and do not assume an
/// exception raised inside one will reach `main`.
///
/// Note the limit: this cannot rescue a native call that blocks rather than
/// returning. If Android is wedging inside the library itself, this wedges too
/// — just earlier and before any data is touched.
///
/// `sqlite3.open` creates the file before the check can run, so a failed
/// attempt would leave a zero-byte file behind — and a zero-byte file passes a
/// "does not start with the plaintext header" check for free. Remove it again
/// if it did not exist before this attempt.
void verifyEncryptedDatabaseFile(
  File file,
  String key, {
  RawDatabaseOpener openRaw = openRawDatabase,
}) {
  final existedBefore = file.existsSync();
  final probe = openRaw(file.path);
  try {
    configureEncryptedDatabase(probe, key);
  } on Object {
    probe.close();
    if (!existedBefore && file.existsSync() && file.lengthSync() == 0) {
      file.deleteSync();
    }
    rethrow;
  }
  probe.close();
}

/// Opens the Jotno database with an already-resolved [key].
///
/// Everything asynchronous — resolving directories, reading the key — happens
/// here, awaited, before the connection is built. The fail-closed check then
/// runs synchronously via [verifyEncryptedDatabaseFile]. The returned executor
/// is therefore already proven, and no `LazyDatabase` is involved.
///
/// [databaseDirectory] and [temporaryDirectory] exist so tests can drive this
/// exact function rather than a lookalike.
///
/// This deliberately opens the database through `package:drift` directly
/// rather than through the Flutter convenience wrapper. That wrapper drags the
/// two discontinued `*_flutter_libs` packages banned by AD-2 into the resolved
/// dependency tree as end-of-life markers, and Jotno's dependency tree has to
/// survive an audit. CI greps `pubspec.lock` for them, so do not reintroduce
/// the wrapper.
Future<QueryExecutor> encryptedDatabaseConnection(
  String key, {
  Future<Object> Function()? databaseDirectory,
  Future<Object> Function()? temporaryDirectory,
  RawDatabaseOpener openRaw = openRawDatabase,
}) async {
  final file = await resolveDatabaseFile(databaseDirectory: databaseDirectory);
  final tempPath = await configureSqliteTempDirectory(
    temporaryDirectory: temporaryDirectory,
  );

  verifyEncryptedDatabaseFile(file, key, openRaw: openRaw);

  return NativeDatabase.createInBackground(
    file,
    // Defence in depth. The background isolate opens its own connection, so it
    // must verify for itself rather than trusting the check above.
    //
    // Sent across isolates, so it may only capture sendable values; `key` is a
    // String.
    setup: (db) => configureEncryptedDatabase(db, key),
    isolateSetup: () async => sqlite3.tempDirectory = tempPath,
  );
}

/// Resolves the key from [keyProvider] and opens the Jotno database.
Future<QueryExecutor> openEncryptedDatabase({
  DatabaseKeyProvider keyProvider = const DevelopmentKeyProvider(),
  Future<Object> Function()? databaseDirectory,
  Future<Object> Function()? temporaryDirectory,
  RawDatabaseOpener openRaw = openRawDatabase,
}) async {
  final key = await keyProvider.databaseKey();
  return encryptedDatabaseConnection(
    key,
    databaseDirectory: databaseDirectory,
    temporaryDirectory: temporaryDirectory,
    openRaw: openRaw,
  );
}

/// Normalises a [Directory] or path [String] to a path.
String _asPath(Object resolved, String argumentName) {
  return switch (resolved) {
    Directory(:final path) => path,
    final String path => path,
    _ => throw ArgumentError.value(
      resolved,
      argumentName,
      'must resolve to a Directory or a path String',
    ),
  };
}
