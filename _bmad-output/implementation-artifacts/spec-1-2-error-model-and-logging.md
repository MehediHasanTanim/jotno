---
title: 'Story 1.2 — The error model and logging every feature is required to use'
type: 'feature'
created: '2026-09-01'
status: 'in-review'
baseline_commit: 'b33dd53ccfc01cb9ff9567a933e0aaf79c467edc'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Fifty-eight stories are about to be built on top of this codebase, and there is no agreed way to return a failure or record an event. Left to accrete, every feature invents its own — and in a health app, the one that matters is a stray `print` putting a diagnosis in a device log.

**Approach:** Fix the two seams before anything is built on them. `Result<T, AppFailure>` becomes the only way a failure crosses a layer boundary, `AppLogger` becomes the only way anything is recorded, and a CI gate makes the alternative fail the build rather than rely on memory.

## Boundaries & Constraints

**Always:**
- Health data never reaches a log, an analytics payload, or a crash report. Member names, medication names, condition names, measurement values, lab values and document contents are all health data.
- `AppLogger` accepts an event name and typed non-PII fields. It has no parameter that can carry free text, so a diagnosis cannot be passed even by accident.
- Analytics events come from a compile-time allowlist. Event *names* must not encode health content either — `dose_actioned` is permitted, `dose_actioned_metformin` is not.
- Every `AppFailure` variant carries a stable localisation key. Story 1.3 wires those keys to ARB; this story defines them.
- Exceptions never cross into `presentation`. Layer boundaries return `Result`.

**Ask First:**
- **Story 1.1's throws — RESOLVED before approval.** `MissingCipherError`, `EmptyDatabaseKeyError`, `DatabaseKeyRejectedException` and `DevelopmentKeyInReleaseBuildError` stay as startup throws. They fire before any repository or layer boundary exists, so there is nothing for `Result` to cross, and that code took three review rounds and on-device testing to get right. Do not refactor them. Give `StartupFailure`'s reasons localisation keys so Story 1.3 wires one mechanism rather than two.
- Adding a crash-reporting SDK. That would be a third external data flow and needs declaring in the architecture, the privacy policy and the store forms.

**Never:**
- Build `HeadlessScope`, `AttachmentStore`, the contributor interfaces, or the reference fixture — each is now its own deferred story.
- Wire ARB files or localisation delegates. This story defines keys; Story 1.3 resolves them.
- Add a logging backend, log levels, or log persistence. `AppLogger` is a façade with one implementation that writes nothing in release.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Operation succeeds | a repository returns a value | `Result.success(value)`; callers read it without a null check | N/A |
| Operation fails | a repository hits a known failure | `Result.failure(AppFailure)` carrying a localisation key | Caller decides; nothing throws across the boundary |
| Unknown error inside a boundary | an unexpected exception is raised | Converted to an `AppFailure` at the boundary, never rethrown outward | Original error's *type* may be recorded; its message may not |
| Logging an event | `AppLogger.event('dose_actioned', memberCount: 3)` | Recorded with the name and typed fields | N/A |
| Attempting to log health data | free-text or entity parameter | **Impossible** — no such parameter exists on the API | Compilation fails |
| Analytics event off the allowlist | an unlisted event name | Rejected at compile time, not at runtime | Build fails |
| `toString()` on a health entity | any entity holding health data | Type and id only — never field values | N/A |
| A `print` under `features/` | a direct `print` or `debugPrint` | The CI gate fails the build, naming file and line | N/A |

</frozen-after-approval>

## Code Map

Story 1.1's surface this story must reconcile with, not duplicate:

- `jotno/lib/core/database/connection.dart:29,40,61` — `MissingCipherError`, `EmptyDatabaseKeyError`, `DatabaseKeyRejectedException`. Thrown at startup, before any layer boundary. Leave as throws; see Ask First.
- `jotno/lib/core/database/database_key.dart:18` — `DevelopmentKeyInReleaseBuildError`. Same.
- `jotno/lib/main.dart:55` — `StartupFailure` enum and its `classify` switch. The existing precedent for classifying failures into fixed, renderable text. Its reasons need localisation keys so Story 1.3 can wire startup and the rest together.
- `.github/workflows/ci.yaml:142` — the `Analyze` step. The new logging gate belongs beside it, in the same style as the existing encryption-switch and forbidden-package gates, both of which distinguish grep exit 1 from exit ≥2.
- `jotno/lib/` — no logging of any kind exists today. Clean slate.

New:

- `jotno/lib/core/result/result.dart` — `Result<T, AppFailure>`.
- `jotno/lib/core/result/app_failure.dart` — the sealed hierarchy and its localisation keys.
- `jotno/lib/core/logging/app_logger.dart` — the façade.
- `jotno/lib/core/logging/analytics_events.dart` — the compile-time allowlist.

## Tasks & Acceptance

**Execution:**
- [x] `jotno/lib/core/result/result.dart` — sealed `Result<T, F>` with success and failure variants, pattern-matchable, no nullable unwrapping
- [x] `jotno/lib/core/result/app_failure.dart` — sealed `AppFailure` with the variants this codebase already needs (storage, validation, notFound, permission, unexpected), each exposing a stable `localisationKey`
- [x] `jotno/lib/core/logging/analytics_events.dart` — an enum or sealed set of permitted event names; nothing else can be logged as analytics
- [x] `jotno/lib/core/logging/app_logger.dart` — `AppLogger` taking an event name plus typed non-PII fields; no free-text parameter; writes nothing in release
- [x] `jotno/lib/main.dart` — give each `StartupFailure` reason a localisation key so Story 1.3 wires one mechanism, not two
- [x] `.github/workflows/ci.yaml` — a gate failing on direct `print`/`debugPrint` under `lib/features/` and `lib/core/`, matching the exit-code handling of the existing gates
- [x] `jotno/test/core/result/result_test.dart` — success and failure paths, pattern matching, no path that yields null
- [x] `jotno/test/core/result/app_failure_test.dart` — every variant has a distinct, non-empty localisation key; keys are stable strings, not derived from runtime type names
- [x] `jotno/test/core/logging/app_logger_test.dart` — recorded output contains the event name and typed fields and nothing else; a test asserting the API surface cannot accept free text

**Acceptance Criteria:**
- Given any layer boundary, when it fails, then it returns `Result.failure` rather than throwing, and `presentation` never catches a raw exception.
- Given `AppLogger`'s public API, when a developer attempts to pass a member name, medication name or any free-text string, then the code does not compile.
- Given a direct `print` or `debugPrint` added anywhere under `lib/`, when CI runs, then the build fails naming the file and line.
- Given the analytics allowlist, when an event name not on it is used, then the build fails.
- Given every `AppFailure` variant, when its localisation key is read, then the key is unique, stable, and present for every variant — verified by a test that enumerates the sealed hierarchy.
- Given the CI gate, when it is run against a file containing a deliberate `print`, then it fails — proven, not assumed.

## Spec Change Log

## Design Notes

The point of `AppLogger` is not that it filters health data — it is that health data has nowhere to go. A signature like `event(AnalyticsEvent name, {int? count, Duration? elapsed, bool? succeeded})` cannot carry a diagnosis. A `Map<String, Object?>` parameter can, so there must not be one.

Story 1.1 established the pattern worth copying: `NotificationContentBuilder` makes the privacy violation unrepresentable rather than forbidden, and `StartupFailure` renders fixed text rather than an error object. Both are the shape this story generalises.

Two CI gates already exist that distinguish grep exit 1 from exit ≥2, because a missing path returning exit 2 silently passes an `if grep; then fail; fi`. The new gate must follow them.

## Verification

**Commands:**
- `cd jotno && flutter analyze --fatal-infos` — expected: no issues
- `cd jotno && flutter test` — expected: all pass, including the new suites
- `cd jotno && dart format --output=none --set-exit-if-changed .` — expected: clean
- Add a temporary `print('x')` under `lib/features/`, run the CI gate script locally — expected: it fails and names the file. Remove it afterwards.

**Manual checks:**
- Read `AppLogger`'s public signature and confirm by inspection that no parameter can carry arbitrary text.
