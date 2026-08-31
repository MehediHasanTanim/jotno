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

/// Opens the Jotno database with an already-resolved [key].
///
/// The returned connection is lazy; the cipher check and key application run
/// when the connection is first used.
///
/// [databaseDirectory] overrides where the file lives. [temporaryDirectory]
/// overrides where sqlite3 spills intermediate results — the global `/tmp` is
/// unreachable from a sandboxed app on some platforms. Both may return a
/// [Directory] or a path [String], and both default to the app's own
/// directories via `path_provider`. They exist so tests can drive this exact
/// function rather than a lookalike.
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
    // first means startup sees [MissingCipherError] and
    // [DatabaseKeyRejectedException] exactly as thrown.
    //
    // `sqlite3.open` creates the file before the check can run, so a failed
    // attempt would leave a zero-byte file behind — and a zero-byte file
    // passes a "does not start with the plaintext header" check for free.
    // Remove it again if it did not exist before this attempt.
    final existedBefore = file.existsSync();
    final probe = sqlite3.open(file.path);
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

/// Resolves the key from [keyProvider] and opens the Jotno database.
Future<QueryExecutor> openEncryptedDatabase({
  DatabaseKeyProvider keyProvider = const DevelopmentKeyProvider(),
  Future<Object> Function()? databaseDirectory,
  Future<Object> Function()? temporaryDirectory,
}) async {
  final key = await keyProvider.databaseKey();
  return encryptedDatabaseConnection(
    key,
    databaseDirectory: databaseDirectory,
    temporaryDirectory: temporaryDirectory,
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
