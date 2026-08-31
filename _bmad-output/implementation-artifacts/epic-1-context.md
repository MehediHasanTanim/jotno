# Epic 1 Context: Set up a family and start keeping records

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

A household installs Jotno, creates a family with no account of any kind, adds every member, and records the medical facts that do not change day to day — conditions, allergies, past illnesses, the doctors and clinics they use. By the end of this epic the app is genuinely useful on its own: it holds what a family currently keeps in a plastic folder. Because the architecture treats them as preconditions rather than polish, this epic also lays every foundation the eight later epics build on — the encrypted database with its runtime cipher assertion, the CI gates, the cross-cutting core services, the design-token theme and shared component library, the aggregator contracts, and both languages complete from the very first screen.

## Stories

- Story 1.1: A database that proves it is encrypted
- Story 1.2: The foundations every feature is required to use
- Story 1.3: The app speaks Bangla first
- Story 1.4: A design system the whole app inherits
- Story 1.5: Shared components that carry the rules
- Story 1.6: First launch leads with the promise
- Story 1.7: Create a family
- Story 1.8: Add and manage family members
- Story 1.9: Record conditions and allergies
- Story 1.10: Record medical history
- Story 1.11: Keep a directory of doctors and hospitals
- Story 1.12: See a member's health at a glance
- Story 1.13: A recovery phrase that can rebuild the key

## Requirements & Constraints

**No account, ever.** Family creation takes a name and nothing else — no email, password, OTP or registration field appears anywhere. Onboarding makes no network request.

**Onboarding order is fixed:** privacy promise and what the app is → medical disclaimer (record-keeping only, no diagnosis or advice; must be acknowledged to continue; stays reachable from Settings) → ad-network consent, shown before the ads SDK initialises, offering personalised or non-personalised and changeable later. The full privacy policy is bundled, not fetched, renders offline in the active language, and covers seven disclosures: on-device-only storage with no vendor server; encrypted cloud backup going directly to the user's own storage; what the ad network receives; that analytics gets event names and timestamps only; which permissions are requested and why; that crash reports carry no health data; and how to disconnect cloud storage and delete backups.

**Permissions are requested at first use, never during onboarding**, each preceded by an in-app rationale screen in the active language. A denial degrades the feature visibly (hide the control) rather than leaving a broken affordance.

**Records the app must hold:** members (unlimited, full profile with derived age), conditions with status, allergies with severity, medical history events, and a family-wide doctor and hospital directory that is not scoped to a single member. The member dashboard is computed entirely from the local database.

**The app records; it never interprets.** No condition is inferred or suggested, no value is judged.

**Non-functional floor for this epic:** every screen works with no connection; interactive within 3 seconds of cold start on a 2GB Android 10 device; no health data in logs, analytics or crash reports; encryption keys only in platform secure storage; soft deletion everywhere; Bangla renders without overflow, clipping or conjunct corruption; and every user-facing string exists in both languages.

## Technical Decisions

**Layering.** Feature-first clean architecture, three layers per feature: `presentation` (widgets, Riverpod notifiers) → `domain` (entities, repository interfaces, use cases, predicates) ← `data` (Drift tables, DAOs, repository impls). `presentation` never imports `data` or `core`. Use-case classes exist only for multi-repository or non-trivial operations; a use case that forwards one repository call is a defect. Riverpod with manual providers — no codegen, no `riverpod_generator`. Widgets never call repositories directly.

**Encryption, fail closed.** SQLite opens via `package:sqlite3` 3.x with SQLite3MultipleCiphers through Dart hooks. Before any query runs, the database service asserts the cipher pragma responds; if it does not, the app halts with an explicit error rather than opening. `sqlcipher_flutter_libs` and `sqlite3_flutter_libs` are forbidden (discontinued).

**Double-wrapped data key.** A random data encryption key encrypts the database and is stored twice — wrapped by a key in platform secure storage and by a key derived from the recovery phrase. Losing secure storage costs a prompt, not the data; the phrase alone reconstructs the key with no backup file involved. No code may assume secure storage survives. `FlutterSecureStorage.xml` is excluded from Android auto-backup.

**Identity and deletion.** Every table carries client-generated UUIDv7 `id` (TEXT, never autoincrement), `created_at`, `updated_at`, `deleted_at`, `device_id`. Application code never hard-deletes. One repository owns one entity; cross-entity writes go through a use case opening a single Drift transaction. No DAO call outside `data/`. Enums persist as TEXT matching the Dart name. Dates store UTC ISO-8601.

**Errors and logging.** `Result<T, AppFailure>` crosses every layer boundary; exceptions never reach `presentation`. `AppFailure` is sealed and carries a localisation key. Logging goes through `AppLogger` (event name plus typed non-PII fields only); analytics uses a compile-time event allowlist; `toString()` on health entities returns type and id only.

**Foundations this epic must create before features use them:** `AttachmentStore` in `core/storage` as sole owner of attachment paths and file deletion (binaries on the filesystem, metadata rows with relative path, mime, size, checksum, polymorphic `entity_type`/`entity_id`); `HeadlessScope` as the only path from non-widget entry points to repositories; the `TimelineContributor`, `CalendarContributor` and `SummaryContributor` domain interfaces; and domain predicates for derived clinical state (`isActiveCondition` and peers) with exactly one implementation each — no caller filters on `status` or dates directly.

**Navigation** is typed `go_router` routes declared centrally, with a declared deep-link path for every externally reachable surface. Features never hand-build another feature's route string.

**CI gates that block dependent work:** release-build cipher assertion; generated Drift migrations (`drift_dev make-migrations`) with tests for every version pair — hand-written migrations are not permitted; a grep gate failing the build on direct `print`/`debugPrint` under `features/`; an l10n parity check failing on any key present in one locale only; and NFR performance benchmarks against a committed reference fixture (10 members, 20 years, 10,000 measurements, 10,000 medication logs, 5,000 documents, 500 appointments). Repositories serving list surfaces expose paged queries only.

**Platform.** Flutter 3.47; Android compileSdk 35 / targetSdk 34 / minSdk 23, AGP 8.11.1. No starter template — plain `flutter create` then the mandated tree (`app/ core/ shared/ features/ l10n/`) and pinned dependency set. Optional subsystems (cloud, ads, analytics, IAP) each sit behind an interface with a no-op implementation, and the suite must pass with all four no-ops installed.

## UX & Interaction Patterns

**Register: calm and clinical** — white ground, hairline borders, restrained type, one deep green. Saturated colour is information, not decoration: red means severe allergy or destructive action and nothing else; amber means lapsed or overdue. Depth is hairlines, not shadows — the only shadow in the system is on bottom sheets. Cards use a 1px hairline and 8px radius; rows inside a card divide with the lighter soft hairline. No gradients, no second accent, no tinted category backgrounds.

**Bangla is primary, not a translation layer.** Body type sets 15/26 in Bangla against 15/24 in English, and every container is sized to the Bangla measure so a language switch never reflows. Noto Sans Bengali and Noto Sans load as one superfamily. Bengali numerals everywhere a number displays, with tabular figures, through a shared formatter — no raw `toString()` on a number reaches the UI. Long strings wrap; a truncated medication, condition or member name is a safety defect. No all-caps.

**Shell:** five fixed bottom tabs (Home, Timeline, Medications, Calendar, More). No drawer. Sheets stack one level, never two. Home opens on the family, not an individual. Emergency lives on Home, not buried in More.

**Offline is not a state** — no banner, no degraded mode, no spinner on local reads. Only cloud operations acknowledge the network.

**Shared components carry the rules** and exist once each: button, card, list row, input, severity badge, allergy badge, member chip, filter chip row, empty section. Tap targets are at least 48px and a bare gesture detector on a raw container in `features/` fails review. Icon-only controls take a required semantic label so omitting one fails compilation. Input focus changes border weight as well as hue. Badges always carry a word, never a bare colour dot. A severe allergy renders in the critical treatment and sorts above all others, identically on the member profile, the emergency card and the exported PDF. Empty sections state absence in words ("No known allergies recorded") — a blank area reads as "none" to a stranger and is forbidden. Filter chip rows are single-select, broadest option first, persisting within a session.

**Every phone number in the app dials on tap.**

**Voice:** a competent relative explaining something clearly. No exclamation marks, no emoji, no encouragement or streaks, no clinical judgement phrasing. Failures name the specific thing that failed and what to do about it. Real risks are stated plainly, never softened. Plain Bangla, keeping the English medical terms people actually say aloud.

**Accessibility verification is empirical.** Widget tests assert layout integrity at the largest dynamic-type setting for every screen, and Bangla screen-reader output must be checked on real devices with TalkBack and VoiceOver — Bengali TTS coverage is uneven and this cannot be satisfied in an emulator.

## Cross-Story Dependencies

- Stories 1.1 and 1.2 are hard prerequisites for everything else in the epic and in the project. No feature work should begin before the encrypted database, the CI gates and the cross-cutting core services exist.
- Stories 1.3, 1.4 and 1.5 (localisation, theme tokens, shared components) gate every screen-building story that follows, here and in later epics.
- Story 1.5 establishes the physical-device screen-reader verification protocol; every subsequent epic re-runs it over the screens it adds.
- Story 1.10 (medical history attachments) consumes the `AttachmentStore` built in Story 1.2, as do prescriptions, appointments, lab reports, vaccinations and the document vault in later epics.
- Story 1.11 (doctor and hospital directory) is referenced by appointments in Epic 3 and by lab reports in Epic 4; those entities are owned here and referenced by id elsewhere.
- Story 1.9's condition predicate and Story 1.2's contributor interfaces are the contracts the timeline, calendar, emergency card and PDF export depend on in Epics 3, 5, 6 and 9.
- Story 1.13's recovery-phrase key wrapping is the precondition for backup and restore in Epic 7.
- The voice-and-microcopy rules and the Bangla accessibility obligation are standing constraints on every story in every epic, not one-off deliverables.
