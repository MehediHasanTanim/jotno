import 'dart:async';

import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/database/connection.dart';
import 'core/database/database_key.dart';
import 'core/logging/analytics_events.dart';
import 'core/logging/app_logger.dart';
import 'core/result/app_failure.dart';

/// How long startup may take before the app gives up and says so.
///
/// Deliberately far beyond any plausible cold start (the NFR floor is three
/// seconds on a 2GB Android 10 device). It exists so a stall can never present
/// as a black screen with no explanation, which is what an unencrypted build
/// did on Android before the check below was made eager.
///
/// It cannot rescue a *synchronous* native call that blocks — that wedges the
/// isolate and no timer fires. It covers the awaited work: reading the key,
/// resolving directories over platform channels, and drift's own open.
const Duration startupTimeout = Duration(seconds: 30);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await startupSurface());
}

/// Opens the database and decides what the app shows.
///
/// Split out of [main] so the startup events below can be asserted against a
/// recording logger. `main` itself cannot be driven from a test — it opens a
/// real database and calls `runApp` — and an event nobody has watched being
/// emitted is worth about as much as a gate nobody has watched fail.
///
/// The awaited structure is Story 1.1's and must stay that way: the cipher and
/// the key are proven in plain awaited code before anything else happens, so a
/// failure lands in the `catch` below with its type intact rather than
/// depending on drift to surface an error raised inside a lazy opener. Only
/// `runApp` moved out.
@visibleForTesting
Future<Widget> startupSurface({
  AppLogger logger = const AppLogger(),
  Future<AppDatabase> Function() open = _openDatabase,
  Duration timeout = startupTimeout,
}) async {
  final stopwatch = Stopwatch()..start();

  try {
    final database = await open().timeout(timeout);
    logger.event(
      AnalyticsEvent.databaseOpened,
      elapsed: stopwatch.elapsed,
      succeeded: true,
    );
    logger.event(AnalyticsEvent.appOpened, elapsed: stopwatch.elapsed);
    return JotnoApp(database: database);
  } on TimeoutException {
    logger.event(
      AnalyticsEvent.appStartupFailed,
      elapsed: stopwatch.elapsed,
      succeeded: false,
      failure: const UnexpectedFailure(errorType: TimeoutException),
    );
    return const DatabaseUnavailableApp(reason: StartupFailure.timedOut);
  } on Object catch (error) {
    // A database that cannot be opened encrypted is not a recoverable state.
    // Show why, on screen, instead of a black rectangle.
    //
    // Only the error's *type* is recorded. `SqliteException.toString()` prints
    // its causing statement, and for the key pragma that statement is the key,
    // so `UnexpectedFailure.from` keeps the type and drops the error here —
    // the one place it could still have been read.
    logger.event(
      AnalyticsEvent.appStartupFailed,
      elapsed: stopwatch.elapsed,
      succeeded: false,
      failure: UnexpectedFailure.from(error),
    );
    return DatabaseUnavailableApp(reason: StartupFailure.classify(error));
  }
}

/// Opens the database and proves it is usable.
///
/// `openAppDatabase` has already verified the cipher and the key in plain
/// awaited code, so a failure has arrived by the time it returns. The warm-up
/// query then forces drift's own connection open, so any failure there also
/// happens here — inside `main`'s `try` — rather than on whichever screen
/// happens to read first.
Future<AppDatabase> _openDatabase() async {
  final database = await openAppDatabase();
  await database.customSelect('select 1').get();
  return database;
}

/// Why the database could not be opened, in terms the startup surface can
/// render without ever printing an error object.
///
/// Raw exceptions are deliberately not carried through here.
/// `SqliteException.toString()` prints its causing statement, and for the key
/// pragma that statement *is* the key.
///
/// This is not an `AppFailure`, and deliberately so. These failures fire
/// before any repository, any layer boundary or any localisation delegate
/// exists — there is nothing for a `Result` to cross and no ARB loaded to
/// resolve a key against, which is why [explanation] is a fixed English string
/// this surface can always render. Each reason nevertheless carries a
/// [localisationKey] so that when Story 1.3 wires ARB it wires one mechanism
/// covering startup and everything after it, rather than two.
enum StartupFailure {
  /// The shipped SQLite library is not the SQLite3MultipleCiphers build.
  missingCipher(
    localisationKey: 'startupFailureMissingCipher',
    explanation:
        'This build shipped an unencrypted SQLite library, so your records '
        'would not be protected. Jotno will not open the database in that '
        'state. Reinstall from an official build.',
  ),

  /// The key was empty, so the database would have been left unencrypted.
  emptyKey(
    localisationKey: 'startupFailureEmptyKey',
    explanation:
        'Jotno was given an empty database key, which would leave your '
        'records unencrypted. Jotno will not open the database in that state.',
  ),

  /// A release build reached the development key provider.
  developmentKeyInRelease(
    localisationKey: 'startupFailureDevelopmentKeyInRelease',
    explanation:
        'This build uses a development key that is the same on every install. '
        'Jotno will not open the database in that state. Reinstall from an '
        'official build.',
  ),

  /// The database exists but the key does not unlock it.
  keyRejected(
    localisationKey: 'startupFailureKeyRejected',
    explanation:
        'The database on this device could not be unlocked with the key '
        'available. Your records are still encrypted on disk and have not '
        'been changed.',
  ),

  /// Startup did not finish in time.
  timedOut(
    localisationKey: 'startupFailureTimedOut',
    explanation:
        'Jotno could not finish starting up on this device. Nothing has been '
        'changed. Try opening the app again.',
  ),

  /// Anything else — corruption, a locked file, an I/O error.
  unknown(
    localisationKey: 'startupFailureUnknown',
    explanation: 'The database could not be opened on this device.',
  );

  const StartupFailure({
    required this.localisationKey,
    required this.explanation,
  });

  /// The ARB key naming the message for this reason, wired in Story 1.3.
  ///
  /// A literal constant, like every `AppFailure` key, rather than something
  /// derived from the enum's `name`: renaming a constant or obfuscating a
  /// release build must not change which string a reader sees.
  final String localisationKey;

  /// What to tell the reader. Never contains anything derived from the key.
  ///
  /// Stays in place after Story 1.3 as the fallback for the case that makes
  /// this surface special: a failure this early can precede the localisations
  /// being loaded at all.
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
