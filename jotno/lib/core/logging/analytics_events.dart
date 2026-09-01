/// The complete list of events Jotno is permitted to record.
///
/// This enum *is* the allowlist. `AppLogger` takes an [AnalyticsEvent], not a
/// name, so an event that is not declared here cannot be logged: the code
/// referring to it does not compile. There is no runtime rejection path
/// because there is no runtime path at all.
///
/// **Adding an event is a privacy decision, not a plumbing one.** The name is
/// the payload — it leaves the device — so it must describe an action, never
/// its subject. `dose_actioned` is permitted; `dose_actioned_metformin` is
/// not. Nothing derived from a member, a condition, a medication, a
/// measurement, a lab value or a document may appear in a name, and a name
/// must never be assembled at runtime.
///
/// The privacy policy tells the reader that analytics receives event names and
/// timestamps only. This list is what that sentence is promising.
enum AnalyticsEvent {
  /// The app reached a usable state.
  appOpened('app_opened'),

  /// Startup failed and the unavailable surface was shown instead.
  ///
  /// Which failure it was travels as an `AppFailure`, whose localisation key
  /// is a fixed string; the underlying error never does.
  appStartupFailed('app_startup_failed'),

  /// The encrypted database was opened and answered a query.
  databaseOpened('database_opened');

  const AnalyticsEvent(this.eventName);

  /// The wire name, in `lower_snake_case`.
  ///
  /// Declared explicitly rather than taken from the enum's own `name` so that
  /// renaming the Dart constant cannot change what analytics receives, and so
  /// that an obfuscated release build reports the same string as a debug one.
  final String eventName;
}
