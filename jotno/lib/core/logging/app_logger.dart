import '../result/app_failure.dart';
import 'analytics_events.dart';
import 'log_writer.dart';

/// The only way anything in Jotno is recorded.
///
/// The guarantee this class makes is not that it filters health data out. It
/// is that health data has nowhere to go. Read the signature of [event]: an
/// allowlisted enum, a count, a duration, a flag, and a sealed failure that
/// carries a localisation key. A member name, a medication, a condition, a
/// measurement or an error message has no parameter to travel in, so passing
/// one is a compile error rather than a review finding.
///
/// That is why there is no free-text parameter and, in particular, no
/// map or list of extras. One such parameter would undo the whole class, and
/// it would be added by someone in a hurry who only needed to log one string
/// this once.
///
/// If a future event genuinely needs a new dimension, add another closed-type
/// named parameter here and think about it once, in this file, rather than at
/// each of the several hundred call sites.
///
/// Nothing is written in a release build — see [DeveloperLogWriter].
final class AppLogger {
  /// Creates a logger writing through [writer].
  ///
  /// The default is the writer Jotno ships; tests pass their own to observe
  /// what was recorded.
  const AppLogger({this.writer = const DeveloperLogWriter()});

  /// Where recorded entries go.
  final LogWriter writer;

  /// Records that [event] happened.
  ///
  /// Every field is optional and every field is a closed type. Supply the ones
  /// that apply.
  void event(
    AnalyticsEvent event, {
    int? count,
    Duration? elapsed,
    bool? succeeded,
    AppFailure? failure,
  }) {
    writer.write(
      LogEntry(
        event,
        count: count,
        elapsed: elapsed,
        succeeded: succeeded,
        failure: failure,
      ),
    );
  }
}
