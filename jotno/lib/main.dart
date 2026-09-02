import 'dart:async';

import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/database/connection.dart';
import 'core/database/database_key.dart';
import 'core/l10n/locale_controller.dart';
import 'core/l10n/number_format.dart';
import 'core/l10n/text_metrics.dart';
import 'core/logging/analytics_events.dart';
import 'core/logging/app_logger.dart';
import 'core/result/app_failure.dart';
import 'l10n/app_localizations.dart';

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
  List<Locale>? deviceLocales,
}) async {
  final stopwatch = Stopwatch()..start();
  final locales = deviceLocales ?? platformLocales();

  try {
    final database = await open().timeout(timeout);
    logger.event(
      AnalyticsEvent.databaseOpened,
      elapsed: stopwatch.elapsed,
      succeeded: true,
    );
    // Only now — with the database proven open — can the stored language
    // choice be read. A failure to read it degrades to the device-derived
    // default inside `load`; it is a settings row, not a reason to refuse to
    // start.
    final localeController = await LocaleController.load(
      store: DatabaseLanguageStore(database),
      deviceLocales: locales,
    );
    logger.event(AnalyticsEvent.appOpened, elapsed: stopwatch.elapsed);
    return JotnoApp(database: database, localeController: localeController);
  } on TimeoutException {
    logger.event(
      AnalyticsEvent.appStartupFailed,
      elapsed: stopwatch.elapsed,
      succeeded: false,
      failure: const UnexpectedFailure(errorType: TimeoutException),
    );
    return DatabaseUnavailableApp(
      reason: StartupFailure.timedOut,
      deviceLocales: locales,
    );
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
    return DatabaseUnavailableApp(
      reason: StartupFailure.classify(error),
      deviceLocales: locales,
    );
  }
}

/// The device's language preferences, in order.
///
/// This is the whole of what the startup error surface needs to localise
/// itself: it renders when the database will not open, so there is no stored
/// choice to read and nothing here touches storage. `main` calls
/// `WidgetsFlutterBinding.ensureInitialized()` before anything reaches this,
/// and a widget build is by definition later still, so the binding is always
/// present. An empty list is not an error — [resolveLanguage] answers Bangla,
/// which is the default anyway.
///
/// Read through the binding rather than `PlatformDispatcher.instance` so that
/// `tester.platformDispatcher.localesTestValue` is what tests see, instead of
/// whatever locale the machine running them happens to be set to.
List<Locale> platformLocales() =>
    WidgetsBinding.instance.platformDispatcher.locales;

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
/// before any repository or layer boundary exists, so there is nothing for a
/// `Result` to cross. They are localised all the same — [explain] resolves
/// each reason against the ARB — but from the *device* locale, never the
/// stored choice, because the store is the database that just refused to open.
/// [explanation] remains the fixed English fallback for the narrower case the
/// ARB cannot cover: a failure early enough that the delegates have not
/// loaded. A surface whose entire job is to explain a failure must not itself
/// have a way to fail.
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

  /// The ARB key naming the message for this reason.
  ///
  /// A literal constant, like every `AppFailure` key, rather than something
  /// derived from the enum's `name`: renaming a constant or obfuscating a
  /// release build must not change which string a reader sees.
  ///
  /// [explain] resolves the message by `switch` rather than by this key, since
  /// `AppLocalizations` generates a getter per message and not a map. The key
  /// remains the contract: `test/core/l10n/localised_surfaces_test.dart`
  /// checks every one of these exists in both ARB files, and
  /// `tool/l10n_parity_gate.sh` checks the two files agree.
  final String localisationKey;

  /// What to tell the reader. Never contains anything derived from the key.
  ///
  /// Stays in place after Story 1.3 as the fallback for the case that makes
  /// this surface special: a failure this early can precede the localisations
  /// being loaded at all.
  final String explanation;

  /// This reason's message in [strings]' language, or [explanation] if there
  /// are no localisations to read.
  ///
  /// A `switch` over the enum rather than a lookup by [localisationKey],
  /// because `AppLocalizations` exposes a getter per message and not a map —
  /// and that is the better arrangement anyway: adding a reason above without
  /// adding its message here does not compile, which is exactly what the
  /// parity gate does for the two ARB files.
  String explain(AppLocalizations? strings) {
    if (strings == null) {
      return explanation;
    }
    return switch (this) {
      StartupFailure.missingCipher => strings.startupFailureMissingCipher,
      StartupFailure.emptyKey => strings.startupFailureEmptyKey,
      StartupFailure.developmentKeyInRelease =>
        strings.startupFailureDevelopmentKeyInRelease,
      StartupFailure.keyRejected => strings.startupFailureKeyRejected,
      StartupFailure.timedOut => strings.startupFailureTimedOut,
      StartupFailure.unknown => strings.startupFailureUnknown,
    };
  }

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

/// The heading of the startup failure surface, in English.
///
/// The counterpart of [StartupFailure.explanation]: the fallback for the case
/// where the localisations themselves are not available. Kept identical to
/// `startupFailureTitle` in `app_en.arb`, which
/// `test/core/l10n/localised_surfaces_test.dart` enforces.
const String startupFailureFallbackTitle = 'Jotno cannot start';

/// The application, once the encrypted database is open.
///
/// A [ListenableBuilder] over [localeController] wraps the whole
/// [MaterialApp], so switching language rebuilds every string in the tree
/// without a restart. Wrapping the app rather than sitting inside it is the
/// point: `Localizations` is rebuilt from the new `locale`, and nothing below
/// has to know a switch happened.
class JotnoApp extends StatelessWidget {
  /// Creates the app over an open [database] in [localeController]'s language.
  const JotnoApp({
    required this.database,
    required this.localeController,
    super.key,
  });

  /// The open, encrypted database.
  final AppDatabase database;

  /// The language every string below renders in.
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final language = localeController.language;
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          locale: language.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedLocales,
          theme: ThemeData(textTheme: bodyTextTheme(language)),
          home: _DatabaseReadyScreen(schemaVersion: database.schemaVersion),
        );
      },
    );
  }
}

/// The placeholder the app renders until the first real screen lands.
///
/// Its one job beyond saying the database opened is to put a number on screen
/// through [AppNumberFormat], so the rule that no widget calls `toString()` on
/// a number is true from the first pixel this app ever draws rather than
/// adopted later.
class _DatabaseReadyScreen extends StatelessWidget {
  const _DatabaseReadyScreen({required this.schemaVersion});

  /// The schema version the open database reports.
  final int schemaVersion;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.databaseReady(context.numbers.integer(schemaVersion)),
            textAlign: TextAlign.center,
            style: TextStyle(fontFeatures: tabularFigures),
          ),
        ),
      ),
    );
  }
}

/// The surface shown when the database refuses to open.
///
/// Localised, but **not** from the stored language choice — it renders exactly
/// when the database that holds that choice will not open. It resolves from
/// the device locale instead, which is the trade the story names: this surface
/// has six fixed strings, and showing a user who picked English the Bangla
/// error once on a broken build costs less than keeping that one setting
/// outside the encrypted database.
///
/// Every string here falls back to the fixed English constants
/// ([StartupFailure.explanation], [startupFailureFallbackTitle]) if
/// `AppLocalizations.of` returns null. That is not defensive noise: a failure
/// this early can precede the delegates loading, and a surface whose whole
/// purpose is to explain a failure must not fail to render.
class DatabaseUnavailableApp extends StatelessWidget {
  /// Creates the failure surface for [reason].
  ///
  /// [deviceLocales] defaults to the platform's own list; tests and
  /// [startupSurface] pass it explicitly.
  const DatabaseUnavailableApp({
    required this.reason,
    this.deviceLocales,
    super.key,
  });

  /// Why the database could not be opened.
  final StartupFailure reason;

  /// The device's language preferences. Null means ask the platform.
  final List<Locale>? deviceLocales;

  @override
  Widget build(BuildContext context) {
    final language = resolveLanguage(
      deviceLocales: deviceLocales ?? platformLocales(),
    );
    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'Jotno',
      debugShowCheckedModeBanner: false,
      locale: language.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedLocales,
      theme: ThemeData(textTheme: bodyTextTheme(language)),
      home: _StartupFailureScreen(reason: reason),
    );
  }
}

class _StartupFailureScreen extends StatelessWidget {
  const _StartupFailureScreen({required this.reason});

  final StartupFailure reason;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings?.startupFailureTitle ?? startupFailureFallbackTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                // Wraps rather than truncates. Every one of these messages
                // ends in what to do about it, and an ellipsis would eat that
                // sentence.
                Text(reason.explain(strings)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
