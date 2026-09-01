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

  group('the release build writes nothing', () {
    // The branch that matters most is the one a test can never be running in,
    // so it is injected — the same reason `RawDatabaseOpener` is injectable in
    // the database connection.
    setUp(_captured.clear);

    test('a release build emits no line at all', () {
      const AppLogger(
        writer: DeveloperLogWriter(isReleaseBuild: true, emit: _capture),
      ).event(AnalyticsEvent.appOpened, count: 1);

      expect(_captured, isEmpty);
    });

    test('a non-release build emits the rendered line', () {
      const AppLogger(
        writer: DeveloperLogWriter(isReleaseBuild: false, emit: _capture),
      ).event(AnalyticsEvent.appOpened, count: 1);

      expect(_captured, ['app_opened count=1']);
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

    test('the entry it builds has no free-text field either', () {
      // Pinned exactly, so adding a field to `LogEntry` — or to the writer —
      // has to be a decision taken here as well as there. Text exists in that
      // file in exactly one place: the writer's emit callback, which is fed by
      // `formatLogEntry`, never by a caller. That declaration spans a
      // parenthesised function type and is therefore not matched below.
      final entryCode = readPackageCode('lib/core/logging/log_writer.dart');
      final fields = RegExp(
        r'^\s*final\s+([\w<>?, ]+?)\s+\w+\s*;',
        multiLine: true,
      ).allMatches(entryCode).map((match) => match.group(1)!.trim()).toSet();

      expect(fields, {
        'AnalyticsEvent',
        'int?',
        'Duration?',
        'bool?',
        'AppFailure?',
        'bool',
      });
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
