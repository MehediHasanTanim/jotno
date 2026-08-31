import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/database/connection.dart';
import 'core/database/database_key.dart';

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
    runApp(DatabaseUnavailableApp(reason: StartupFailure.classify(error)));
  }
}

/// Why the database could not be opened, in terms the startup surface can
/// render without ever printing an error object.
///
/// Raw exceptions are deliberately not carried through here.
/// `SqliteException.toString()` prints its causing statement, and for the key
/// pragma that statement *is* the key.
enum StartupFailure {
  /// The shipped SQLite library is not the SQLite3MultipleCiphers build.
  missingCipher(
    'This build shipped an unencrypted SQLite library, so your records would '
    'not be protected. Jotno will not open the database in that state. '
    'Reinstall from an official build.',
  ),

  /// The key was empty, so the database would have been left unencrypted.
  emptyKey(
    'Jotno was given an empty database key, which would leave your records '
    'unencrypted. Jotno will not open the database in that state.',
  ),

  /// A release build reached the development key provider.
  developmentKeyInRelease(
    'This build uses a development key that is the same on every install. '
    'Jotno will not open the database in that state. Reinstall from an '
    'official build.',
  ),

  /// The database exists but the key does not unlock it.
  keyRejected(
    'The database on this device could not be unlocked with the key '
    'available. Your records are still encrypted on disk and have not '
    'been changed.',
  ),

  /// Anything else — corruption, a locked file, an I/O error.
  unknown('The database could not be opened on this device.');

  const StartupFailure(this.explanation);

  /// What to tell the reader. Never contains anything derived from the key.
  final String explanation;

  /// Maps a startup [error] onto the reason to display.
  ///
  /// Classification is by type, not by matching message text, so renaming a
  /// message cannot silently reclassify a failure.
  static StartupFailure classify(Object error) {
    return switch (error) {
      MissingCipherError() => StartupFailure.missingCipher,
      EmptyDatabaseKeyError() => StartupFailure.emptyKey,
      DevelopmentKeyInReleaseBuildError() =>
        StartupFailure.developmentKeyInRelease,
      DatabaseKeyRejectedException() => StartupFailure.keyRejected,
      _ => StartupFailure.unknown,
    };
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
/// Intentionally unlocalised: this can fire before anything else is ready.
class DatabaseUnavailableApp extends StatelessWidget {
  /// Creates the failure surface for [reason].
  const DatabaseUnavailableApp({required this.reason, super.key});

  /// Why the database could not be opened.
  final StartupFailure reason;

  @override
  Widget build(BuildContext context) {
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
                  Text(reason.explanation),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
