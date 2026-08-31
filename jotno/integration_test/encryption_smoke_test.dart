import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotno/core/database/app_database.dart';
import 'package:jotno/core/database/connection.dart';
import 'package:jotno/core/database/sqlite_file_format.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// The host test in `test/core/database/encryption_test.dart` proves the logic.
/// It cannot prove what the *shipped device artifact* links against, which is
/// the only thing that actually protects a user's records. That is this file.
///
/// The plaintext header is imported, never retyped: an on-device assertion that
/// silently drifts from the host one proves nothing while looking green.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Removes the database and every sibling sqlite writes next to it.
  void removeDatabaseFiles(String basePath) {
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('$basePath$suffix');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  late String basePath;

  setUp(() async {
    final directory = await getApplicationSupportDirectory();
    basePath = '${directory.path}/$databaseFileName.sqlite';
    removeDatabaseFiles(basePath);
  });

  tearDown(() {
    removeDatabaseFiles(basePath);
  });

  testWidgets('the library on the device is the SQLite3MultipleCiphers build', (
    tester,
  ) async {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);

    expect(
      db.select('pragma cipher'),
      isNotEmpty,
      reason: cipherMissingMessage,
    );
  });

  testWidgets('a fresh install creates an encrypted database', (tester) async {
    final database = await openAppDatabase();
    var closed = false;
    addTearDown(() async {
      if (!closed) await database.close();
    });

    // Forces the connection open: cipher check, then PRAGMA key.
    await database.customSelect('select 1').get();
    // Writing guarantees the header page has been flushed to disk.
    await database.customStatement('vacuum');
    await database.close();
    closed = true;

    final file = File(basePath);
    expect(file.existsSync(), isTrue, reason: 'no database file was written');

    final bytes = file.readAsBytesSync();
    // Without this, a zero-byte or truncated file would pass the header check
    // below for free.
    expect(
      bytes.length,
      greaterThanOrEqualTo(plaintextSqliteHeader.length),
      reason: 'the database file on the device is too short to inspect',
    );
    expect(
      startsWithPlaintextSqliteHeader(bytes),
      isFalse,
      reason:
          'the database file on the device is NOT encrypted; it begins '
          '${describeLeadingBytes(bytes)}',
    );
  });

  testWidgets('an unencrypted control file on the same device IS detected', (
    tester,
  ) async {
    // Anchors the assertion above. Same device, same library, same helper —
    // but no `PRAGMA key`. If this does not come back plaintext, the check in
    // the previous test cannot be trusted to notice a plaintext database.
    final directory = await getApplicationSupportDirectory();
    final control = File('${directory.path}/control.sqlite');
    addTearDown(() {
      if (control.existsSync()) control.deleteSync();
    });
    if (control.existsSync()) control.deleteSync();

    final db = sqlite3.open(control.path);
    db
      ..execute('create table smoke (value text)')
      ..execute("insert into smoke (value) values ('secret')");
    db.close();

    final bytes = control.readAsBytesSync();
    expect(bytes.length, greaterThanOrEqualTo(plaintextSqliteHeader.length));
    expect(
      startsWithPlaintextSqliteHeader(bytes),
      isTrue,
      reason:
          'the plaintext detector does not recognise a plaintext file on '
          'this device, so the encryption assertion above proves nothing',
    );
  });
}
