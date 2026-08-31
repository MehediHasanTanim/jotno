import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database_key.dart';

/// File name (without extension) of the Jotno database.
///
/// The connection appends `.sqlite`.
const String databaseFileName = 'jotno';

/// The message carried by the [UnsupportedError] thrown when the shipped
/// SQLite library is not the SQLite3MultipleCiphers build.
const String cipherMissingMessage =
    'Jotno requires the SQLite3MultipleCiphers build. '
    'The shipped library is unencrypted — refusing to open the database.';

/// Thrown when the database exists and the cipher is present, but the supplied
/// key does not decrypt it.
///
/// Deliberately distinct from the [UnsupportedError] raised for a missing
/// cipher: "we shipped the wrong library" and "we have the wrong key" are
/// different failures with different remedies, and must never be conflated.
final class DatabaseKeyRejectedException implements Exception {
  /// Creates an exception wrapping the [cause] reported by SQLite.
  const DatabaseKeyRejectedException(this.cause);

  /// The underlying error thrown while probing `sqlite_master`.
  final Object cause;

  @override
  String toString() =>
      'DatabaseKeyRejectedException: the encrypted database could not be read '
      'with the supplied key. The database file exists and the cipher is '
      'present, so this is a key problem, not a build problem. '
      'Underlying error: $cause';
}

/// Escapes [value] for inlining into a single-quoted SQL string literal.
///
/// `PRAGMA key` does not accept bind parameters, so the key has to be inlined.
/// Doubling `'` is the whole of SQL string escaping.
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
    throw UnsupportedError(cipherMissingMessage);
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

  // 2. Apply the key. The pragma takes no bind parameters, so escape and
  //    inline. Never log this statement — it contains the key.
  db.execute("pragma key = '${escapeSqlStringLiteral(key)}'");

  // 3. `PRAGMA key` does not validate: a wrong key succeeds here and fails at
  //    some arbitrary later read. Force the failure now, loudly.
  try {
    db.execute('select count(*) from sqlite_master');
  } on Object catch (cause) {
    throw DatabaseKeyRejectedException(cause);
  }

  // Any further pragmas (WAL, foreign keys, ...) belong below this line, never
  // above it.
}

/// Opens the Jotno database with an already-resolved [key].
///
/// The returned connection is lazy; the cipher check and key application run
/// when the connection is first used.
///
/// [databaseDirectory] overrides where the file lives — used by the integration
/// test. It may return a [Directory] or a path [String]. It defaults to the
/// app-support directory.
///
/// [temporaryDirectory] overrides where sqlite3 spills intermediate results.
/// It defaults to the app's own temporary directory, because the global `/tmp`
/// is unreachable from a sandboxed app on some platforms.
///
/// This deliberately opens the database through `package:drift` directly
/// rather than through the Flutter convenience wrapper. That wrapper drags the
/// two discontinued `*_flutter_libs` packages banned by AD-2 into the resolved
/// dependency tree as end-of-life markers, and Jotno's dependency tree has to
/// survive an audit. CI greps `pubspec.lock` for them, so do not reintroduce
/// the wrapper.
QueryExecutor encryptedDatabaseConnection(
  String key, {
  Future<Object> Function()? databaseDirectory,
  Future<Object> Function()? temporaryDirectory,
}) {
  return LazyDatabase(() async {
    final directoryPath = _asPath(
      await (databaseDirectory ?? getApplicationSupportDirectory)(),
      'databaseDirectory',
    );

    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    final file = File('$directoryPath/$databaseFileName.sqlite');

    // sqlite3 spills large intermediate results to a temporary directory. The
    // global `/tmp` is unreachable from a sandboxed app on some platforms, so
    // point it at one the app owns — on the calling isolate and, below, on the
    // background isolate that actually hosts the connection.
    final tempPath = _asPath(
      await (temporaryDirectory ?? getTemporaryDirectory)(),
      'temporaryDirectory',
    );
    sqlite3.tempDirectory = tempPath;

    // Prove the cipher and the key here, on the calling isolate, before the
    // connection moves to a background one. A failure raised inside that
    // isolate reaches the caller wrapped in a `DriftRemoteException`, which
    // would blur the two failures this story exists to keep apart. Doing it
    // first means startup sees `UnsupportedError` and
    // [DatabaseKeyRejectedException] exactly as thrown.
    final probe = sqlite3.open(file.path);
    try {
      configureEncryptedDatabase(probe, key);
    } finally {
      probe.close();
    }

    return NativeDatabase.createInBackground(
      file,
      // Sent to the background isolate that hosts the connection, so it may
      // only capture sendable values. `key` is a String. The background
      // isolate opens its own connection, so it repeats the check rather than
      // trusting the probe above.
      setup: (db) => configureEncryptedDatabase(db, key),
      isolateSetup: () async => sqlite3.tempDirectory = tempPath,
    );
  });
}

/// Normalises a [Directory] or path [String] to a path.
String _asPath(Object resolved, String argumentName) {
  return switch (resolved) {
    Directory(:final path) => path,
    String path => path,
    _ => throw ArgumentError.value(
      resolved,
      argumentName,
      'must resolve to a Directory or a path String',
    ),
  };
}

/// Resolves the key from [keyProvider] and opens the Jotno database.
Future<QueryExecutor> openEncryptedDatabase({
  DatabaseKeyProvider keyProvider = const DevelopmentKeyProvider(),
  Future<Object> Function()? databaseDirectory,
}) async {
  final key = await keyProvider.databaseKey();
  return encryptedDatabaseConnection(key, databaseDirectory: databaseDirectory);
}
