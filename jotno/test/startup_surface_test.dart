import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/database/app_database.dart';
import 'package:jotno/core/database/connection.dart';
import 'package:jotno/core/database/database_key.dart';
import 'package:jotno/core/logging/analytics_events.dart';
import 'package:jotno/core/logging/app_logger.dart';
import 'package:jotno/core/logging/log_writer.dart';
import 'package:jotno/core/result/app_failure.dart';
import 'package:jotno/main.dart';

import 'support/dart_source.dart';

/// A [LogWriter] that keeps what it was given.
final class _RecordingLogWriter implements LogWriter {
  final List<LogEntry> entries = <LogEntry>[];

  @override
  void write(LogEntry entry) => entries.add(entry);
}

/// The startup surface is the user-visible form of the distinction this story
/// exists to preserve: "this build is not encrypted" and "this key is wrong"
/// are different failures with different remedies. Swapping the branches would
/// otherwise break nothing.
void main() {
  group('StartupFailure.classify', () {
    test('maps a missing cipher to the build-is-unencrypted reason', () {
      expect(
        StartupFailure.classify(MissingCipherError()),
        StartupFailure.missingCipher,
      );
    });

    test('maps a rejected key to the key reason', () {
      expect(
        StartupFailure.classify(const DatabaseKeyRejectedException()),
        StartupFailure.keyRejected,
      );
    });

    test('maps an empty key to its own reason', () {
      expect(
        StartupFailure.classify(EmptyDatabaseKeyError()),
        StartupFailure.emptyKey,
      );
    });

    test('maps a development key in release to its own reason', () {
      expect(
        StartupFailure.classify(DevelopmentKeyInReleaseBuildError()),
        StartupFailure.developmentKeyInRelease,
      );
    });

    test('maps anything else to unknown', () {
      expect(
        StartupFailure.classify(StateError('disk on fire')),
        StartupFailure.unknown,
      );
    });

    test('does not fold a rejected key into the missing-cipher reason', () {
      // The two branches must stay distinct: conflating them would tell a user
      // with a key problem to reinstall the app, and vice versa.
      expect(
        StartupFailure.classify(const DatabaseKeyRejectedException()),
        isNot(StartupFailure.classify(MissingCipherError())),
      );
    });

    test(
      'a DevelopmentKeyInReleaseBuildError is not read as a missing cipher',
      () {
        // Both are UnsupportedErrors, so an `is UnsupportedError` test would
        // wrongly merge them.
        expect(DevelopmentKeyInReleaseBuildError(), isA<UnsupportedError>());
        expect(
          StartupFailure.classify(DevelopmentKeyInReleaseBuildError()),
          isNot(StartupFailure.missingCipher),
        );
      },
    );
  });

  group('DatabaseUnavailableApp', () {
    testWidgets('names the build for a missing cipher', (tester) async {
      await tester.pumpWidget(
        const DatabaseUnavailableApp(reason: StartupFailure.missingCipher),
      );

      expect(find.text('Jotno cannot start'), findsOneWidget);
      expect(find.textContaining('unencrypted SQLite library'), findsOneWidget);
    });

    testWidgets('reassures that records are intact for a rejected key', (
      tester,
    ) async {
      await tester.pumpWidget(
        const DatabaseUnavailableApp(reason: StartupFailure.keyRejected),
      );

      expect(find.textContaining('still encrypted on disk'), findsOneWidget);
      expect(find.textContaining('unencrypted SQLite library'), findsNothing);
    });

    testWidgets('renders every reason without an exception object', (
      tester,
    ) async {
      // The surface must never print a raw error: SqliteException.toString()
      // includes its causing statement, and for the key pragma that statement
      // is the key.
      for (final reason in StartupFailure.values) {
        await tester.pumpWidget(DatabaseUnavailableApp(reason: reason));
        await tester.pumpAndSettle();

        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join('\n');

        expect(texts, contains('Jotno cannot start'));
        expect(texts, contains(reason.explanation));
        expect(texts, isNot(contains('SqliteException')));
        expect(texts, isNot(contains('pragma key')));
        expect(texts, isNot(contains('Causing statement')));
      }
    });

    testWidgets('no reason renders an empty explanation', (tester) async {
      for (final reason in StartupFailure.values) {
        expect(reason.explanation.trim(), isNotEmpty);
      }
    });
  });

  group('the localisation keys', () {
    // Startup failures are not `AppFailure`s — they fire before any layer
    // boundary exists — but they carry keys in the same form so Story 1.3
    // wires one mechanism rather than two. These checks mirror the ones in
    // `test/core/result/app_failure_test.dart` on purpose.
    test('every reason has a non-empty key', () {
      for (final reason in StartupFailure.values) {
        expect(reason.localisationKey.trim(), isNotEmpty, reason: '$reason');
      }
    });

    test('every reason has a distinct key', () {
      final keys = StartupFailure.values
          .map((reason) => reason.localisationKey)
          .toList();

      expect(keys.toSet(), hasLength(keys.length));
    });

    test('the keys are literals, not derived from the enum name', () {
      // `name` is stripped by obfuscation and changes under a rename, either
      // of which would silently repoint a message once ARB is wired.
      //
      // Read through the comment-stripping helper, not `File(...)` directly:
      // with comments left in, a key mentioned only in a doc comment would
      // satisfy this assertion while no code produced it.
      final code = readPackageCode('lib/main.dart');

      for (final reason in StartupFailure.values) {
        expect(code, contains("'${reason.localisationKey}'"));
      }
    });

    test('a key never contains anything derived from a database key', () {
      for (final reason in StartupFailure.values) {
        expect(
          RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$').hasMatch(reason.localisationKey),
          isTrue,
          reason:
              '${reason.localisationKey} is not a plain identifier, so it was '
              'not written as a fixed constant',
        );
      }
    });
  });

  group('startupSurface records what happened', () {
    // The events are the only trace a startup failure leaves. If they are
    // emitted with the wrong fields — or carry the error rather than its type
    // — nobody finds out from reading the code, so they are asserted here
    // against a recording logger.

    test('a successful start records the open and the app', () async {
      final writer = _RecordingLogWriter();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final surface = await startupSurface(
        logger: AppLogger(writer: writer),
        open: () async => database,
      );

      expect(surface, isA<JotnoApp>());
      expect(writer.entries.map((entry) => entry.event).toList(), [
        AnalyticsEvent.databaseOpened,
        AnalyticsEvent.appOpened,
      ]);
      expect(writer.entries.first.succeeded, isTrue);
      expect(writer.entries.first.elapsed, isNotNull);
      expect(writer.entries.first.failure, isNull);
    });

    test(
      'a timeout records the failure and shows the timeout surface',
      () async {
        final writer = _RecordingLogWriter();

        final surface = await startupSurface(
          logger: AppLogger(writer: writer),
          open: () => Completer<AppDatabase>().future,
          timeout: const Duration(milliseconds: 10),
        );

        expect(surface, isA<DatabaseUnavailableApp>());
        expect(
          (surface as DatabaseUnavailableApp).reason,
          StartupFailure.timedOut,
        );
        expect(writer.entries.single.event, AnalyticsEvent.appStartupFailed);
        expect(writer.entries.single.succeeded, isFalse);
        expect(
          writer.entries.single.failure,
          const UnexpectedFailure(errorType: TimeoutException),
        );
      },
    );

    test('a rejected key records the type and never the error', () async {
      final writer = _RecordingLogWriter();

      final surface = await startupSurface(
        logger: AppLogger(writer: writer),
        open: () async => throw const DatabaseKeyRejectedException(),
      );

      expect(
        (surface as DatabaseUnavailableApp).reason,
        StartupFailure.keyRejected,
      );
      expect(
        writer.entries.single.failure,
        const UnexpectedFailure(errorType: DatabaseKeyRejectedException),
      );
    });

    test('nothing recorded at startup can carry the database key', () async {
      // The whole point. A SqliteException whose causing statement holds the
      // key goes in; only the type comes out, and the rendered line proves it.
      const key = 'super-secret-key';
      final writer = _RecordingLogWriter();

      await startupSurface(
        logger: AppLogger(writer: writer),
        open: () async => throw SqliteException(
          extendedResultCode: 26,
          message: 'file is not a database',
          causingStatement: "pragma key = '\$key'",
        ),
      );

      for (final entry in writer.entries) {
        expect(formatLogEntry(entry), isNot(contains(key)));
        expect(formatLogEntry(entry), isNot(contains('pragma')));
      }
      expect(
        formatLogEntry(writer.entries.single),
        contains('errorType=SqliteException'),
      );
    });
  });

  group('the failure text', () {
    test('never carries a key, even for a real SqliteException', () {
      // Walks the whole path: a SqliteException whose causing statement holds
      // the key, through classification, to the rendered explanation.
      const key = 'super-secret-key';
      final sqliteError = SqliteException(
        extendedResultCode: 26,
        message: 'file is not a database',
        causingStatement: "pragma key = '$key'",
      );
      expect('$sqliteError', contains(key)); // the raw form does leak

      final rejected = DatabaseKeyRejectedException(
        resultCode: sqliteError.resultCode,
      );
      expect('$rejected', isNot(contains(key)));

      final reason = StartupFailure.classify(rejected);
      expect(reason.explanation, isNot(contains(key)));
    });
  });
}
