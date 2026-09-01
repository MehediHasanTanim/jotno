import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/logging/analytics_events.dart';
import 'package:jotno/core/logging/app_logger.dart';
import 'package:jotno/core/logging/log_writer.dart';
import 'package:jotno/core/result/app_failure.dart';

import '../../support/dart_source.dart';

/// A [LogWriter] that keeps what it was given, so a test can see it.
final class RecordingLogWriter implements LogWriter {
  final List<LogEntry> entries = <LogEntry>[];

  @override
  void write(LogEntry entry) => entries.add(entry);
}

void main() {
  group('what gets recorded', () {
    test('an event with no fields records just its name', () {
      final writer = RecordingLogWriter();

      AppLogger(writer: writer).event(AnalyticsEvent.appOpened);

      expect(writer.entries, hasLength(1));
      expect(formatLogEntry(writer.entries.single), 'app_opened');
    });

    test('the typed fields appear, and only the ones supplied', () {
      final writer = RecordingLogWriter();

      AppLogger(writer: writer).event(
        AnalyticsEvent.databaseOpened,
        count: 3,
        elapsed: const Duration(milliseconds: 1200),
        succeeded: true,
      );

      expect(
        formatLogEntry(writer.entries.single),
        'database_opened count=3 elapsed=1200ms succeeded=true',
      );
    });

    test('a partial set of fields does not leave gaps or nulls', () {
      final writer = RecordingLogWriter();

      AppLogger(writer: writer).event(AnalyticsEvent.appOpened, count: 0);

      expect(formatLogEntry(writer.entries.single), 'app_opened count=0');
      expect(formatLogEntry(writer.entries.single), isNot(contains('null')));
    });

    test('a failure records its localisation key, never a message', () {
      final writer = RecordingLogWriter();

      AppLogger(writer: writer).event(
        AnalyticsEvent.appStartupFailed,
        succeeded: false,
        failure: const StorageFailure(),
      );

      expect(
        formatLogEntry(writer.entries.single),
        'app_startup_failed succeeded=false failure=failureStorage',
      );
    });

    test('an unexpected failure records the error type, not the error', () {
      final writer = RecordingLogWriter();

      AppLogger(writer: writer).event(
        AnalyticsEvent.appStartupFailed,
        failure: UnexpectedFailure.from(
          StateError('opening /data/user/0/jotno.sqlite failed'),
        ),
      );

      final line = formatLogEntry(writer.entries.single);
      expect(
        line,
        'app_startup_failed failure=failureUnexpected errorType=StateError',
      );
      expect(line, isNot(contains('jotno.sqlite')));
    });

    test('an unexpected failure with no known type renders just its key', () {
      expect(
        formatLogEntry(
          const LogEntry(
            AnalyticsEvent.appStartupFailed,
            failure: UnexpectedFailure(),
          ),
        ),
        'app_startup_failed failure=failureUnexpected',
      );
    });

    test('a sub-millisecond duration renders as 0ms, not as nothing', () {
      // `inMilliseconds` truncates. The field was supplied, so it must still
      // appear — a missing `elapsed=` reads as "not measured" rather than
      // "faster than a millisecond".
      expect(
        formatLogEntry(
          const LogEntry(
            AnalyticsEvent.databaseOpened,
            elapsed: Duration(microseconds: 400),
          ),
        ),
        'database_opened elapsed=0ms',
      );
    });

    test('the rendered line holds nothing beyond name and typed fields', () {
      // Every field set at once. If a rendering branch ever grows a new source
      // of text, this exact match is what notices.
      expect(
        formatLogEntry(
          LogEntry(
            AnalyticsEvent.databaseOpened,
            count: 2,
            elapsed: const Duration(seconds: 1),
            succeeded: false,
            failure: const NotFoundFailure(),
          ),
        ),
        'database_opened count=2 elapsed=1000ms succeeded=false '
        'failure=failureNotFound',
      );
    });
  });

  group('a shipping build writes nothing', () {
    // The branch that matters most is the one a test can never be running in,
    // so it is injected — the same reason `RawDatabaseOpener` is injectable in
    // the database connection.
    setUp(_captured.clear);

    test('a shipping build emits no line at all', () {
      const AppLogger(
        writer: DeveloperLogWriter(isShippingBuild: true, emit: _capture),
      ).event(AnalyticsEvent.appOpened, count: 1);

      expect(_captured, isEmpty);
    });

    test('a debug build emits the rendered line', () {
      const AppLogger(
        writer: DeveloperLogWriter(isShippingBuild: false, emit: _capture),
      ).event(AnalyticsEvent.appOpened, count: 1);

      expect(_captured, ['app_opened count=1']);
    });

    test('profile counts as shipping, not as debug', () {
      // `flutter build --profile` is what goes onto a tester's real phone to
      // measure the three-second cold start. Gating on `kReleaseMode` alone
      // would leave every line of it in that device's logcat. The default is
      // a compile-time constant, so the guard has to be read off the source.
      final code = readPackageCode('lib/core/logging/log_writer.dart');

      expect(
        code,
        contains('kReleaseMode || kProfileMode'),
        reason:
            'the default silence gate no longer covers profile builds, which '
            'run on real devices with real records on them',
      );
    });

    test('a debug test run is not treated as shipping', () {
      // Proves the constant resolves the way the tests above assume, rather
      // than every one of them passing vacuously against a silent writer.
      expect(const DeveloperLogWriter().isShippingBuild, isFalse);
    });

    test('the shipped writer runs its real emit path', () {
      // Every other test injects `emit:`, which leaves the one line deciding
      // where a real log actually goes with no coverage at all. This calls it.
      const writer = DeveloperLogWriter();

      expect(
        () => writer.write(const LogEntry(AnalyticsEvent.appOpened, count: 1)),
        returnsNormally,
      );
    });
  });

  group('the API surface cannot accept free text', () {
    // The guarantee is that a member name, a medication or an error message
    // has no parameter to travel in — passing one is a compile error, so the
    // attempt cannot be written as a test. What can be checked is the
    // declaration: `AppLogger` is the only public entry point, and its file
    // must mention none of the types that can carry arbitrary content.
    final code = readPackageCode('lib/core/logging/app_logger.dart');

    test('the file exists and was actually read', () {
      expect(code, contains('class AppLogger'));
      expect(code, contains('AnalyticsEvent event'));
    });

    for (final freeTextType in const [
      'String',
      'Object',
      'dynamic',
      'Map',
      'List',
      'Set',
      'Iterable',
      'Symbol',
      'Function',
      'StringBuffer',
      'Exception',
      'Error',
    ]) {
      test('mentions no $freeTextType', () {
        expect(
          RegExp('\\b$freeTextType\\b').hasMatch(code),
          isFalse,
          reason:
              'app_logger.dart mentions $freeTextType. One free-text parameter '
              'undoes the whole class: it will be added by someone in a hurry '
              'who only needs to log one string this once, and a diagnosis '
              'ends up in adb logcat. If a new dimension is genuinely needed, '
              'add another closed-type named parameter instead.',
        );
      });
    }

    test('the entry it builds can hold no text either', () {
      // Scoped to `LogEntry`'s own body rather than the whole file. Text does
      // legitimately exist in `log_writer.dart` — `formatLogEntry` builds the
      // line, and the writer's `emit` callback takes it — so a whole-file scan
      // would either fail on the rendering code or have to exempt so much
      // that it stopped meaning anything. What must hold no text is the
      // record. An unrelated private field is not a failure here; a
      // `String? note` is.
      final entryCode = readPackageCode('lib/core/logging/log_writer.dart');
      final body = RegExp(
        r'final class LogEntry \{(.*?)\n\}',
        dotAll: true,
      ).firstMatch(entryCode);

      expect(
        body,
        isNotNull,
        reason:
            'could not find the LogEntry class body, so this test is scanning '
            'nothing and would pass whatever happened',
      );
      expect(
        freeTextShapesIn(body!.group(1)!),
        isEmpty,
        reason:
            'LogEntry gained somewhere text can sit. Every field must be a '
            'closed type — an allowlisted event, a count, a duration, a flag, '
            'or a sealed AppFailure — so that a member name has no field to '
            'travel in.',
      );
    });
  });

  group('the analytics allowlist', () {
    test('event names are unique', () {
      final names = AnalyticsEvent.values
          .map((event) => event.eventName)
          .toList();

      expect(names.toSet(), hasLength(names.length));
    });

    test('event names are lower_snake_case literals', () {
      // A name is the payload — it leaves the device. Constraining the shape
      // also rules out a name assembled at runtime from something a member
      // typed, because an interpolated name would not survive this.
      for (final event in AnalyticsEvent.values) {
        expect(
          RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$').hasMatch(event.eventName),
          isTrue,
          reason: '${event.eventName} is not lower_snake_case',
        );
      }
    });

    test('a name is not derived from the Dart constant', () {
      // Declared explicitly so an obfuscated release build reports the same
      // string as a debug one.
      final code = readPackageCode('lib/core/logging/analytics_events.dart');

      expect(code, isNot(contains('.name')));
      for (final event in AnalyticsEvent.values) {
        expect(code, contains("'${event.eventName}'"));
      }
    });
  });
}

/// Where [_capture] puts what it was given.
final List<String> _captured = <String>[];

void _capture(String line) => _captured.add(line);
