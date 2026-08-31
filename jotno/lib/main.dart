import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/database/connection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final database = await openAppDatabase();
    // The connection is lazy: the cipher check and `PRAGMA key` run on first
    // use. Force that now so an unencrypted build fails at startup rather than
    // on whichever screen happens to read first.
    await database.customSelect('select 1').get();
    runApp(JotnoApp(database: database));
  } on Object catch (error) {
    // A database that cannot be opened encrypted is not a recoverable state.
    // Show why, on screen, instead of a white rectangle.
    runApp(DatabaseUnavailableApp(error: error));
  }
}

/// The application, once the encrypted database is open.
class JotnoApp extends StatelessWidget {
  /// Creates the app over an open [database].
  const JotnoApp({required this.database, super.key});

  /// The open, encrypted database.
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jotno',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The encrypted database is open at schema version 1.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// The surface shown when the database refuses to open.
///
/// The overwhelmingly likely cause is a build that shipped upstream SQLite
/// instead of SQLite3MultipleCiphers, so the message names that first. It is
/// intentionally unlocalised: this can fire before anything else is ready.
class DatabaseUnavailableApp extends StatelessWidget {
  /// Creates the failure surface for [error].
  const DatabaseUnavailableApp({required this.error, super.key});

  /// The error that stopped the database from opening.
  final Object error;

  @override
  Widget build(BuildContext context) {
    final isCipherMissing =
        error is UnsupportedError &&
        (error as UnsupportedError).message == cipherMissingMessage;
    final isKeyRejected = error is DatabaseKeyRejectedException;

    final String explanation;
    if (isCipherMissing) {
      explanation =
          'This build shipped an unencrypted SQLite library, so your records '
          'would not be protected. Jotno will not open the database in that '
          'state. Reinstall from an official build.';
    } else if (isKeyRejected) {
      explanation =
          'The database on this device could not be unlocked with the key '
          'available. Your records are still encrypted on disk and have not '
          'been changed.';
    } else {
      explanation = 'The database could not be opened on this device.';
    }

    return MaterialApp(
      title: 'Jotno',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jotno cannot start',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(explanation),
                  const SizedBox(height: 16),
                  Text('$error', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
