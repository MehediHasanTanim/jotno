import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotno/core/database/app_database.dart';
import 'package:jotno/core/database/connection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// The first 16 bytes of every unencrypted SQLite file.
const _plaintextHeader = 'SQLite format 3 ';

/// The host test in `test/core/database/encryption_test.dart` proves the logic.
/// It cannot prove what the *shipped device artifact* links against, which is
/// the only thing that actually protects a user's records. That is this file.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/$databaseFileName.sqlite');
    if (file.existsSync()) {
      file.deleteSync();
    }

    final database = await openAppDatabase();
    addTearDown(database.close);

    // Forces the connection open: cipher check, then PRAGMA key.
    await database.customSelect('select 1').get();
    // Writing guarantees the header page has been flushed to disk.
    await database.customStatement('vacuum');

    expect(file.existsSync(), isTrue);
    final header = file.readAsBytesSync().take(16).toList();
    expect(
      String.fromCharCodes(header),
      isNot(_plaintextHeader),
      reason: 'The database file on the device is not encrypted.',
    );
  });
}
