import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/database/app_database.dart';
import 'package:jotno/core/database/connection.dart';
import 'package:jotno/core/database/database_key.dart';
import 'package:jotno/core/database/sqlite_file_format.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('jotno_encryption_test');
    dbFile = File('${tempDir.path}/$databaseFileName.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Asserts [file] holds a real database that is not plaintext.
  ///
  /// The length check is not decoration: a zero-byte or truncated file does
  /// not start with the plaintext header either, so without it the assertion
  /// passes for free.
  void expectEncryptedFile(File file) {
    expect(file.existsSync(), isTrue, reason: 'no database file was written');
    final bytes = file.readAsBytesSync();
    expect(
      bytes.length,
      greaterThanOrEqualTo(plaintextSqliteHeader.length),
      reason: 'file is too short to carry a header at all',
    );
    expect(
      startsWithPlaintextSqliteHeader(bytes),
      isFalse,
      reason:
          'file begins with the plaintext SQLite header: '
          '${describeLeadingBytes(bytes)}',
    );
  }

  group('the shipped SQLite library', () {
    test('is the SQLite3MultipleCiphers build', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      // The whole story in one line: upstream SQLite answers this with an
      // empty result set instead of an error.
      expect(db.select('pragma cipher'), isNotEmpty);
    });

    test('passes requireEncryptedSqlite', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      expect(() => requireEncryptedSqlite(db), returnsNormally);
    });
  });

  group('requireEncryptedSqlite', () {
    test('throws MissingCipherError when pragma cipher is empty', () {
      // Stands in for a build that shipped upstream SQLite, which reports the
      // unknown pragma as an empty result set rather than an error.
      final db = _UpstreamSqliteStub();

      expect(
        () => requireEncryptedSqlite(db),
        throwsA(
          isA<MissingCipherError>().having(
            (e) => e.message,
            'message',
            cipherMissingMessage,
          ),
        ),
      );
    });

    test(
      'MissingCipherError is an UnsupportedError, as the I/O matrix says',
      () {
        expect(MissingCipherError(), isA<UnsupportedError>());
      },
    );

    test('is keyed to `pragma cipher` specifically', () {
      // The stub answers only `pragma cipher` with an empty result set and
      // throws on anything else, so this fails if the check ever drifts onto
      // some other statement that happens to return no rows.
      final db = _UpstreamSqliteStub();

      expect(
        () => requireEncryptedSqlite(db),
        throwsA(isA<MissingCipherError>()),
      );
      expect(db.statementsSeen, ['pragma cipher']);
    });

    test('is not an assert, so it also fires in release', () {
      // Guards the one mistake that would silently disable this check: an
      // `assert` is stripped from release builds, which is precisely the build
      // that must refuse to start. Asserts are enabled under `flutter test`,
      // so a regression to `assert` would still throw here — hence the check
      // on the *type*, which an assert failure (AssertionError) would fail.
      final db = _UpstreamSqliteStub();

      expect(
        () => requireEncryptedSqlite(db),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e is AssertionError,
            'is an AssertionError',
            isFalse,
          ),
        ),
      );
    });
  });

  group('escapeSqlStringLiteral', () {
    test('leaves a plain key untouched', () {
      expect(escapeSqlStringLiteral('a-plain-key'), 'a-plain-key');
    });

    test('doubles a single quote', () {
      expect(escapeSqlStringLiteral("it's-a-key"), "it''s-a-key");
    });

    test('doubles every single quote', () {
      expect(escapeSqlStringLiteral("'a'b'"), "''a''b''");
    });
  });

  group('an empty key', () {
    // `PRAGMA key = ''` is not an error in SQLite3MultipleCiphers — it leaves
    // the database unencrypted. Refusing it is the difference between an
    // encrypted database and a plaintext one.
    for (final (label, key) in [
      ('empty', ''),
      ('a single space', ' '),
      ('whitespace only', '  \t\n '),
    ]) {
      test('is refused when the key is $label', () {
        final db = sqlite3.open(dbFile.path);
        addTearDown(db.close);

        expect(
          () => configureEncryptedDatabase(db, key),
          throwsA(isA<EmptyDatabaseKeyError>()),
        );
      });
    }

    test('would otherwise have produced a plaintext database', () {
      // Anchors the guard above: this is what the refused path actually does
      // if the pragma is allowed to run with an empty key.
      final db = sqlite3.open(dbFile.path);
      db
        ..execute("pragma key = ''")
        ..execute('create table smoke (value text)')
        ..execute("insert into smoke (value) values ('secret')");
      db.close();

      expect(startsWithPlaintextSqliteHeader(dbFile.readAsBytesSync()), isTrue);
    });

    test('is refused before the pragma runs, leaving no keyed file', () {
      final db = sqlite3.open(dbFile.path);
      addTearDown(db.close);

      expect(
        () => configureEncryptedDatabase(db, ''),
        throwsA(isA<EmptyDatabaseKeyError>()),
      );
      expect(dbFile.lengthSync(), 0);
    });
  });

  group('configureEncryptedDatabase', () {
    test('round-trips data written under the same key', () {
      _writeSmokeRow(dbFile, key: 'a-plain-key', value: 'kept');

      final reopened = sqlite3.open(dbFile.path);
      addTearDown(reopened.close);
      configureEncryptedDatabase(reopened, 'a-plain-key');

      expect(
        reopened.select('select value from smoke').single['value'],
        'kept',
      );
    });

    test('round-trips a key containing a single quote', () {
      const key = "it's-a-key";
      _writeSmokeRow(dbFile, key: key, value: 'quoted');

      final reopened = sqlite3.open(dbFile.path);
      addTearDown(reopened.close);

      expect(() => configureEncryptedDatabase(reopened, key), returnsNormally);
      expect(
        reopened.select('select value from smoke').single['value'],
        'quoted',
      );
    });

    test('an unescaped quoted key would not open the same database', () {
      // Proves the escaping is load-bearing rather than incidental: the raw
      // (unescaped) form of the same key is a different, invalid statement.
      const key = "it's-a-key";
      _writeSmokeRow(dbFile, key: key, value: 'quoted');

      final reopened = sqlite3.open(dbFile.path);
      addTearDown(reopened.close);
      requireEncryptedSqlite(reopened);

      expect(
        () => reopened.execute("pragma key = '$key'"),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects a wrong key with a distinct, named failure', () {
      _writeSmokeRow(dbFile, key: 'the-right-key', value: 'secret');

      final reopened = sqlite3.open(dbFile.path);
      addTearDown(reopened.close);

      expect(
        () => configureEncryptedDatabase(reopened, 'the-wrong-key'),
        throwsA(isA<DatabaseKeyRejectedException>()),
      );
    });

    test('the wrong-key failure is not the missing-cipher failure', () {
      _writeSmokeRow(dbFile, key: 'the-right-key', value: 'secret');

      final reopened = sqlite3.open(dbFile.path);
      addTearDown(reopened.close);

      expect(
        () => configureEncryptedDatabase(reopened, 'the-wrong-key'),
        throwsA(isNot(isA<UnsupportedError>())),
      );
    });

    test(
      'the wrong-key failure never carries the key or the key statement',
      () {
        const secretKey = 'the-wrong-key-that-must-not-leak';
        _writeSmokeRow(dbFile, key: 'the-right-key', value: 'secret');

        final reopened = sqlite3.open(dbFile.path);
        addTearDown(reopened.close);

        Object? caught;
        try {
          configureEncryptedDatabase(reopened, secretKey);
        } on Object catch (error) {
          caught = error;
        }

        expect(caught, isA<DatabaseKeyRejectedException>());
        // The startup surface renders text derived from this. It must not carry
        // the key, nor the pragma that contains it.
        expect('$caught', isNot(contains(secretKey)));
        expect('$caught', isNot(contains('pragma key')));
      },
    );

    test('only SQLITE_NOTADB is classified as a wrong key', () {
      // SQLITE_NOTADB means "this key does not decrypt this file". Busy,
      // locked, corrupt and I/O failures are different problems with different
      // remedies; mislabelling them sends the user after the wrong fix.
      //
      // Driven through a stub because SQLITE_BUSY and friends cannot be
      // provoked deterministically from a single-process test.
      final notADatabase = _ScriptedDatabase(
        probeFailure: SqliteException(
          extendedResultCode: SqlError.SQLITE_NOTADB,
          message: 'file is not a database',
        ),
      );

      expect(
        () => configureEncryptedDatabase(notADatabase, 'a-plain-key'),
        throwsA(isA<DatabaseKeyRejectedException>()),
      );
    });

    for (final (label, code) in [
      ('SQLITE_BUSY', SqlError.SQLITE_BUSY),
      ('SQLITE_LOCKED', SqlError.SQLITE_LOCKED),
      ('SQLITE_CORRUPT', SqlError.SQLITE_CORRUPT),
      ('SQLITE_IOERR', SqlError.SQLITE_IOERR),
    ]) {
      test('$label propagates instead of posing as a wrong key', () {
        final db = _ScriptedDatabase(
          probeFailure: SqliteException(
            extendedResultCode: code,
            message: 'simulated $label',
          ),
        );

        Object? caught;
        try {
          configureEncryptedDatabase(db, 'a-plain-key');
        } on Object catch (error) {
          caught = error;
        }

        expect(caught, isA<SqliteException>());
        expect(caught, isNot(isA<DatabaseKeyRejectedException>()));
        expect((caught! as SqliteException).extendedResultCode, code);
      });
    }

    test('a failure applying the key never rethrows the key statement', () {
      // SqliteException.toString() prints its causing statement, and for this
      // pragma that statement is the key. It must be swallowed, not rethrown.
      const secret = 'a-key-that-must-not-escape';
      final db = _ScriptedDatabase(
        keyFailure: SqliteException(
          extendedResultCode: SqlError.SQLITE_ERROR,
          message: 'simulated failure',
          causingStatement: "pragma key = '$secret'",
        ),
      );

      Object? caught;
      try {
        configureEncryptedDatabase(db, secret);
      } on Object catch (error) {
        caught = error;
      }

      expect(caught, isA<DatabaseKeyRejectedException>());
      expect('$caught', isNot(contains(secret)));
      expect('$caught', isNot(contains('pragma key')));
    });

    test('a real wrong key against a real database reports NOTADB', () {
      // Anchors the stub-driven classification above against the real library.
      _writeSmokeRow(dbFile, key: 'the-right-key', value: 'secret');
      final reopened = sqlite3.open(dbFile.path);
      addTearDown(reopened.close);

      Object? caught;
      try {
        configureEncryptedDatabase(reopened, 'the-wrong-key');
      } on Object catch (error) {
        caught = error;
      }

      expect(
        (caught! as DatabaseKeyRejectedException).resultCode,
        SqlError.SQLITE_NOTADB,
      );
    });
  });

  group('the database file on disk', () {
    test('is encrypted after a keyed write', () {
      _writeSmokeRow(dbFile, key: 'a-plain-key', value: 'secret');
      expectEncryptedFile(dbFile);
    });

    test('does not contain the written value in plaintext', () {
      _writeSmokeRow(
        dbFile,
        key: 'a-plain-key',
        value: 'a-very-distinct-value',
      );

      final bytes = dbFile.readAsBytesSync();
      expect(
        String.fromCharCodes(bytes),
        isNot(contains('a-very-distinct-value')),
      );
    });

    test('an unencrypted control file DOES begin with the header', () {
      // Anchors the assertion above: without `PRAGMA key` the same sqlite3mc
      // build writes an ordinary plaintext file, so the test would catch a
      // silently key-less database rather than passing vacuously.
      final control = File('${tempDir.path}/control.sqlite');
      final db = sqlite3.open(control.path);
      db
        ..execute('create table smoke (value text)')
        ..execute("insert into smoke (value) values ('secret')");
      db.close();

      expect(
        startsWithPlaintextSqliteHeader(control.readAsBytesSync()),
        isTrue,
      );
    });

    test('a truncated file is not mistaken for an encrypted one', () {
      // Guards the length check inside `expectEncryptedFile`.
      final short = File('${tempDir.path}/short.sqlite')
        ..writeAsBytesSync([0x53, 0x51, 0x4c]);
      expect(startsWithPlaintextSqliteHeader(short.readAsBytesSync()), isFalse);
      expect(() => expectEncryptedFile(short), throwsA(isA<TestFailure>()));
    });
  });

  group('DevelopmentKeyProvider', () {
    test('returns a constant', () async {
      const provider = DevelopmentKeyProvider();
      expect(
        await provider.databaseKey(),
        DevelopmentKeyProvider.developmentKey,
      );
      expect(await provider.databaseKey(), await provider.databaseKey());
    });

    test('is a DatabaseKeyProvider, so Story 1.13 can swap it', () async {
      const DatabaseKeyProvider provider = DevelopmentKeyProvider(
        key: 'injected',
      );
      expect(await provider.databaseKey(), 'injected');
    });

    test('hands out a key that is not empty', () async {
      // An empty constant here would sail past the provider and be caught only
      // by the guard in configureEncryptedDatabase.
      expect(DevelopmentKeyProvider.developmentKey.trim(), isNotEmpty);
    });
  });

  group('AppDatabase over an encrypted connection', () {
    test('creates schema v1 and round-trips a row', () async {
      final database = _openAppDatabase(dbFile, 'a-plain-key');
      addTearDown(database.close);

      expect(database.schemaVersion, 1);

      await _insertSmokeRow(database, '0199a0c8-0000-7000-8000-000000000001');

      final rows = await database.select(database.smokeRecords).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, '0199a0c8-0000-7000-8000-000000000001');
      expect(rows.single.deletedAt, isNull);
      expect(rows.single.deviceId, 'test-device');
    });

    test('written file is encrypted', () async {
      final database = _openAppDatabase(dbFile, 'a-plain-key');
      var closed = false;
      addTearDown(() async {
        if (!closed) await database.close();
      });

      await _insertSmokeRow(database, '0199a0c8-0000-7000-8000-000000000002');
      await database.close();
      closed = true;

      expectEncryptedFile(dbFile);
    });

    test('refuses to open with the wrong key', () async {
      final database = _openAppDatabase(dbFile, 'the-right-key');
      await _insertSmokeRow(database, '0199a0c8-0000-7000-8000-000000000003');
      await database.close();

      final reopened = _openAppDatabase(dbFile, 'the-wrong-key');
      addTearDown(() => _closeQuietly(reopened));

      await expectLater(
        reopened.select(reopened.smokeRecords).get(),
        throwsA(isA<DatabaseKeyRejectedException>()),
      );
    });
  });

  group('encryptedDatabaseConnection (the production open path)', () {
    // The groups above exercise NativeDatabase directly. This one exercises
    // what main.dart actually reaches, including the background isolate that
    // hosts the connection.
    //
    // Both seams are supplied because the defaults go through path_provider,
    // which has no implementation under `flutter test`.
    Future<Object> testDirectory() async => tempDir;

    AppDatabase open(String key) {
      return AppDatabase(
        encryptedDatabaseConnection(
          key,
          databaseDirectory: testDirectory,
          temporaryDirectory: testDirectory,
        ),
      );
    }

    test('creates an encrypted file in the resolved directory', () async {
      final database = open('a-plain-key');
      var closed = false;
      addTearDown(() async {
        if (!closed) await _closeQuietly(database);
      });

      await _insertSmokeRow(database, '0199a0c8-0000-7000-8000-000000000004');
      await database.close();
      closed = true;

      expectEncryptedFile(dbFile);
    });

    test('a wrong key still reaches startup as a named failure', () async {
      final database = open('the-right-key');
      await _insertSmokeRow(database, '0199a0c8-0000-7000-8000-000000000005');
      await database.close();

      final reopened = open('the-wrong-key');
      addTearDown(() => _closeQuietly(reopened));

      Object? caught;
      try {
        await reopened.select(reopened.smokeRecords).get();
      } on Object catch (error) {
        caught = error;
      }

      // The connection lives on a background isolate, but the cipher and key
      // are proven on the calling isolate first, so startup sees the failure
      // unwrapped and can still tell a bad key from a build that shipped
      // upstream SQLite.
      expect(caught, isA<DatabaseKeyRejectedException>());
    });

    test('an empty key is refused before any file is written', () async {
      final database = open('   ');
      addTearDown(() => _closeQuietly(database));

      await expectLater(
        database.select(database.smokeRecords).get(),
        throwsA(isA<EmptyDatabaseKeyError>()),
      );
      // P6: a failed attempt must not leave a zero-byte file behind, because
      // an empty file passes a "not plaintext" check for free.
      expect(dbFile.existsSync(), isFalse);
    });

    test('a failed open leaves no zero-byte file behind', () async {
      final database = open('   ');
      addTearDown(() => _closeQuietly(database));

      await expectLater(
        database.select(database.smokeRecords).get(),
        throwsA(isA<EmptyDatabaseKeyError>()),
      );

      expect(
        Directory(tempDir.path).listSync().map((e) => e.path),
        isEmpty,
        reason: 'a failed open left files in the database directory',
      );
    });
  });

  group('openEncryptedDatabase (the production entry point)', () {
    // Drives the exact function main.dart calls, through a DatabaseKeyProvider,
    // so the key actually used in production is the key under test. Without
    // this, replacing the key with '' anywhere along this path is invisible.
    Future<Object> testDirectory() async => tempDir;

    Future<AppDatabase> open(String key) async {
      return AppDatabase(
        await openEncryptedDatabase(
          keyProvider: DevelopmentKeyProvider(key: key),
          databaseDirectory: testDirectory,
          temporaryDirectory: testDirectory,
        ),
      );
    }

    test('writes an encrypted database using the provider key', () async {
      final database = await open('provided-key');
      var closed = false;
      addTearDown(() async {
        if (!closed) await _closeQuietly(database);
      });

      await _insertSmokeRow(database, '0199a0c8-0000-7000-8000-000000000006');
      await database.close();
      closed = true;

      expectEncryptedFile(dbFile);
    });

    test('reopening with a different key is rejected', () async {
      final database = await open('provided-key');
      await _insertSmokeRow(database, '0199a0c8-0000-7000-8000-000000000007');
      await database.close();

      final reopened = await open('a-different-key');
      addTearDown(() => _closeQuietly(reopened));

      await expectLater(
        reopened.select(reopened.smokeRecords).get(),
        throwsA(isA<DatabaseKeyRejectedException>()),
      );
    });

    test('an empty provider key is refused', () async {
      final database = await open('');
      addTearDown(() => _closeQuietly(database));

      await expectLater(
        database.select(database.smokeRecords).get(),
        throwsA(isA<EmptyDatabaseKeyError>()),
      );
    });
  });

  group('openAppDatabase', () {
    Future<Object> testDirectory() async => tempDir;

    test('forwards both directory seams', () async {
      final database = await openAppDatabase(
        keyProvider: const DevelopmentKeyProvider(key: 'app-key'),
        databaseDirectory: testDirectory,
        temporaryDirectory: testDirectory,
      );
      var closed = false;
      addTearDown(() async {
        if (!closed) await _closeQuietly(database);
      });

      await _insertSmokeRow(database, '0199a0c8-0000-7000-8000-000000000008');
      await database.close();
      closed = true;

      expectEncryptedFile(dbFile);
    });
  });
}

AppDatabase _openAppDatabase(File file, String key) {
  return AppDatabase(
    NativeDatabase(file, setup: (db) => configureEncryptedDatabase(db, key)),
  );
}

Future<void> _insertSmokeRow(AppDatabase database, String id) async {
  final now = DateTime.utc(2026, 8, 31, 12);
  await database
      .into(database.smokeRecords)
      .insert(
        SmokeRecordsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: 'test-device',
        ),
      );
}

/// Closes a database that may never have opened successfully.
Future<void> _closeQuietly(AppDatabase database) async {
  try {
    await database.close();
  } on Object {
    // Closing a connection that never opened is not interesting here.
  }
}

/// Creates [file] as an encrypted database holding one `smoke` row.
void _writeSmokeRow(File file, {required String key, required String value}) {
  final db = sqlite3.open(file.path);
  configureEncryptedDatabase(db, key);
  db
    ..execute('create table smoke (value text)')
    ..execute('insert into smoke (value) values (?)', [value]);
  db.close();
}

/// A [CommonDatabase] standing in for a build that shipped upstream SQLite.
///
/// It answers `pragma cipher` with no rows — the way upstream SQLite reports an
/// unknown pragma — and throws on anything else, so a check that drifts onto
/// some other empty-returning statement fails loudly instead of passing.
class _UpstreamSqliteStub implements CommonDatabase {
  final List<String> statementsSeen = [];

  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    statementsSeen.add(sql);
    if (sql.trim().toLowerCase() == 'pragma cipher') {
      return ResultSet(const [], const [], const []);
    }
    throw StateError('unexpected statement on the upstream stub: $sql');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [CommonDatabase] that reports the encrypted build and can be told to fail
/// at a chosen point, so error classification can be tested for result codes
/// that cannot be provoked deterministically from a single process.
class _ScriptedDatabase implements CommonDatabase {
  _ScriptedDatabase({this.keyFailure, this.probeFailure});

  /// Thrown from the `pragma key` statement, if set.
  final Object? keyFailure;

  /// Thrown from the `sqlite_master` probe, if set.
  final Object? probeFailure;

  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    if (sql.trim().toLowerCase() == 'pragma cipher') {
      return ResultSet(const ['cipher'], const [null], const [
        ['chacha20'],
      ]);
    }
    throw StateError('unexpected select on the scripted stub: $sql');
  }

  @override
  void execute(String sql, [List<Object?> parameters = const []]) {
    final normalised = sql.trim().toLowerCase();
    if (normalised.startsWith('pragma key')) {
      if (keyFailure != null) throw keyFailure!;
      return;
    }
    if (normalised.startsWith('select count(*) from sqlite_master')) {
      if (probeFailure != null) throw probeFailure!;
      return;
    }
    throw StateError('unexpected statement on the scripted stub: $sql');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
