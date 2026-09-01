import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../result/app_failure.dart';
import 'analytics_events.dart';

/// One thing that happened, in the only shape Jotno can record.
///
/// Every field is a closed type: an allowlisted [AnalyticsEvent], a count, a
/// duration, a flag, and a sealed [AppFailure] that itself carries only a
/// localisation key. There is nowhere in this record for a member name, a
/// medication, a measurement or an error message to sit.
@immutable
final class LogEntry {
  /// Records that [event] happened, with whatever typed fields apply.
  const LogEntry(
    this.event, {
    this.count,
    this.elapsed,
    this.succeeded,
    this.failure,
  });

  /// What happened. Comes from the compile-time allowlist.
  final AnalyticsEvent event;

  /// How many of something — members, rows, retries.
  ///
  /// A count is a magnitude, not a fact about a person.
  final int? count;

  /// How long the operation took.
  final Duration? elapsed;

  /// Whether the operation succeeded.
  final bool? succeeded;

  /// Why it failed, when it failed.
  final AppFailure? failure;
}

/// Where an [LogEntry] goes once it has been recorded.
///
/// A seam, not an extension point: [DeveloperLogWriter] is the only
/// implementation Jotno ships. It exists so tests can observe what was
/// recorded, and so a future sink (an analytics interface with a no-op
/// implementation, per the architecture) has a place to attach without
/// widening `AppLogger`'s signature.
abstract interface class LogWriter {
  /// Records [entry].
  void write(LogEntry entry);
}

/// Renders [entry] as one line.
///
/// Only the event name and the fields that were supplied appear. There is no
/// branch that can emit anything else, because [LogEntry] holds nothing else.
String formatLogEntry(LogEntry entry) {
  final parts = <String>[entry.event.eventName];

  final count = entry.count;
  if (count != null) {
    parts.add('count=$count');
  }

  final elapsed = entry.elapsed;
  if (elapsed != null) {
    parts.add('elapsed=${elapsed.inMilliseconds}ms');
  }

  final succeeded = entry.succeeded;
  if (succeeded != null) {
    parts.add('succeeded=$succeeded');
  }

  final failure = entry.failure;
  if (failure != null) {
    // The localisation key, never a message: `AppFailure` has no message to
    // render, which is the reason it has none.
    parts.add('failure=${failure.localisationKey}');
    if (failure case UnexpectedFailure(errorType: final Type errorType)) {
      parts.add('errorType=$errorType');
    }
  }

  return parts.join(' ');
}

/// The one [LogWriter] Jotno ships.
///
/// In a release build it writes nothing at all. That is not a level filter
/// that someone can turn up later — there is no backend, no persistence and no
/// level, so a release build has no log for a device-log scraper or a support
/// bundle to pick a diagnosis out of.
///
/// In debug and profile builds it goes to `dart:developer`'s `log`, not to the
/// console functions the CI gate forbids under `lib/`. Those two facts are the
/// same decision seen from either side.
@immutable
final class DeveloperLogWriter implements LogWriter {
  /// Creates the writer.
  ///
  /// [isReleaseBuild] and [emit] are injectable for the same reason
  /// `RawDatabaseOpener` is: the release branch is the one that matters most
  /// and cannot otherwise be exercised from a test, which always runs in
  /// debug.
  const DeveloperLogWriter({
    this.isReleaseBuild = kReleaseMode,
    this.emit = _emitToDeveloperLog,
  });

  /// Whether this is a release build, in which case nothing is written.
  final bool isReleaseBuild;

  /// Where a rendered line goes in a non-release build.
  final void Function(String line) emit;

  @override
  void write(LogEntry entry) {
    if (isReleaseBuild) {
      return;
    }
    emit(formatLogEntry(entry));
  }
}

void _emitToDeveloperLog(String line) => developer.log(line, name: 'jotno');
