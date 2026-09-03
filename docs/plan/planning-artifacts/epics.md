---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-bmad-test-2026-08-29/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-bmad-test-2026-08-30/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/ux-designs/ux-bmad-test-2026-08-29/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-bmad-test-2026-08-29/EXPERIENCE.md
---

# Jotno - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for **Jotno**, a Bangla-first, offline-first family health record for Bangladeshi households, decomposing the requirements from the PRD, the UX design contract (DESIGN.md + EXPERIENCE.md), and the Architecture Spine into implementable stories.

Requirement IDs are stable across all four upstream documents. `FR-n` and `NFR-*` come from the PRD; `AD-n` from the Architecture Spine; `UX-DR-n` are derived here from the UX spine pair.

## Requirements Inventory

### Functional Requirements

**Onboarding, consent and permissions**
- FR-1: First-launch welcome and privacy promise — leads with the promise, before any legal text
- FR-2: Medical disclaimer — record-keeping only, no diagnosis or advice
- FR-3: AdMob consent screen — personalised vs non-personalised, before SDK init
- FR-4: In-app privacy policy — bilingual, readable offline, seven named disclosures
- FR-5: Device permission requests — at first use, with rationale, denial handled

**Family and members**
- FR-6: Family creation — no account, email, password or OTP
- FR-7: Member management — unlimited members, full profile fields
- FR-8: Member dashboard — computed entirely from the local database

**Medical records**
- FR-9: Medical History records — typed events with status and linked documents
- FR-10: Condition tracking — active/resolved/chronic
- FR-11: Allergy management — severity, with Severe surfaced prominently everywhere
- FR-12: Doctor directory — shared across the Family
- FR-13: Hospital directory — hospital, clinic, diagnostic centre, pharmacy

**Medications**
- FR-14: Medication records — dosage, route, purpose, dates, status
- FR-15: Medication Schedules — frequency, times, auto-creation mode
- FR-16: Medication Engine — OS-scheduled delivery, rolling horizon, catch-up reconciliation
- FR-17: Dose logging — taken, skipped, snoozed, missed; retroactive allowed
- FR-18: Medication adherence history — per-dose calendar plus aggregate percentage
- FR-19: Prescriptions — a first-class entity; one prescription yields many medications

**Appointments and reminders**
- FR-20: Appointment management — doctor, hospital, date, status
- FR-21: Appointment reminders — up to four lead times
- FR-22: Post-visit notes and attachments
- FR-23: Standalone reminders — lab test due, measurement due, follow-up

**Vaccinations**
- FR-24: Vaccination records — dose number, provider, batch, next due
- FR-25: Vaccination reminders — configurable lead time

**Measurements**
- FR-26: Measurement recording — BP, glucose, weight, height, temperature, heart rate, SpO₂, custom
- FR-27: Blood Pressure detailed entry — systolic, diastolic, pulse, context, arm, position
- FR-28: Blood Glucose detailed entry — value, unit, measurement type
- FR-29: Measurement trend charts — 7d / 30d / 3m / 6m / 1y

**Lab reports and documents**
- FR-30: Lab Report entry — date, lab, ordering doctor
- FR-31: Lab Result entry — value, unit, reference range, user-set out-of-range flag
- FR-32: Lab Result history and trend — reuses the FR-29 chart component
- FR-33: Document attachment and vault — categorised, filterable, searchable

**Timeline, emergency, calendar**
- FR-34: Health Timeline feed — all events, all members, filterable
- FR-35: Emergency Contacts — typed, Family-wide or per-member, call/SMS/copy
- FR-36: Emergency Health Card content — allergies first, every number dials
- FR-37: Emergency Health Card access — at most two taps from Home
- FR-38: Rapid emergency access without app unlock — ≤3 actions from a locked device
- FR-39: Family Health Calendar — month view, all event types, filterable by member

**Security and data lifecycle**
- FR-40: Encrypted local database
- FR-41: PIN lock — with failure cooldown
- FR-42: Biometric authentication — falls back to PIN
- FR-43: Auto-lock — configurable timeout
- FR-44: Data deletion — delete a Member, or delete all data

**Backup and restore**
- FR-45: Local backup — encrypted `.hfm` to device storage
- FR-46: Recovery Phrase — generated on device, saveable, warned about
- FR-47: Local restore — atomic, free forever
- FR-48: Backup and restore failure handling — six named failure modes
- FR-49: Cloud connection lifecycle — expiry surfaced, never silent

**Cloud (paid IAP)**
- FR-50: Cloud backup — Google Drive
- FR-51: Cloud backup — OneDrive and Dropbox
- FR-52: Cloud restore
- FR-53: Automatic cloud backup — daily or weekly, 7-backup retention

**Import and export**
- FR-54: PDF health summary export — one member
- FR-55: Family Health Report export — whole household
- FR-56: CSV export
- FR-57: JSON export — complete enough to round-trip
- FR-58: CSV import — transactional
- FR-59: JSON import — completes the round trip
- FR-60: Backup File import — free forever

**Localisation**
- FR-61: Bangla-default UI
- FR-62: English UI option

### NonFunctional Requirements

**Availability**
- NFR-P1: Offline completeness — every feature except the four cloud operations works with no connection
- NFR-P2: Reminder reliability — OS delivers whether or not the app is running

**Performance** *(all measured against the reference fixture: 10 members, 20 years, 10,000 measurements, 10,000 medication logs, 5,000 documents, 500 appointments)*
- NFR-P3: App launch — interactive within 3s on a 2GB Android 10 device
- NFR-P4: Scroll — 60fps on Timeline and Calendar at reference size
- NFR-P5: Search — Document Vault results within 1s
- NFR-P6: Chart rendering — within 2s for any range, including 1y over 10,000 measurements
- NFR-P7: Adherence computation — within 2s against 10,000 logs
- NFR-P8: PDF generation — single member within 10s; family report shows progress, does not block
- NFR-P9: Backup and restore — accurate progress, cancellable, survives backgrounding

**Security and privacy**
- NFR-S1: No health data in logs, analytics or crash reports — including OS-level crash channels
- NFR-S2: Notification privacy — member name and item name only, never dosage or condition
- NFR-S3: Secure key storage — Keystore / Secure Enclave only
- NFR-S4: Soft deletion — with two named permanent-erasure exceptions

**Accessibility and localisation**
- NFR-A1: Bangla rendering — no overflow, clipping or conjunct corruption; layouts absorb longer strings
- NFR-A2: Language parity — every user-facing string exists in both languages

### Additional Requirements

*Derived from the Architecture Spine. These are preconditions and cross-cutting obligations, not features.*

**Project setup**
- No greenfield starter template. Plain `flutter create` on Flutter 3.47, then the mandated source tree from the Spine's Structural Seed (`app/ core/ shared/ features/ l10n/`) and the pinned dependency set.
- Android: compileSdk 35, targetSdk 34, minSdk 23, AGP 8.11.1.
- Forbidden dependencies: `sqlcipher_flutter_libs`, `sqlite3_flutter_libs` (both discontinued), `riverpod_generator` (AD-16).

**Mandatory CI gates** *(each blocks feature work that depends on it)*
- Release-build cipher assertion — proves the encrypted SQLite build actually shipped (AD-2)
- Drift migration tests for every version pair, generated via `make-migrations` (AD-17)
- Logging grep gate — fails the build on direct `print`/`debugPrint` under `features/` (AD-11)
- l10n parity check — fails on a key present in one locale and missing in the other (AD-18)
- NFR-P benchmark suite against the committed reference fixture (AD-27)

**Cross-cutting foundations that must precede feature work**
- Encrypted database with double-wrapped DEK — Keystore KEK plus recovery-phrase KEK (AD-2, AD-3)
- `Result<T, AppFailure>` and sealed failure types with localisation keys
- `AppLogger` and the analytics event allowlist (AD-11)
- `HeadlessScope` container for non-widget entry points — notification handler, boot receiver, WorkManager (AD-16)
- `AttachmentStore` as sole owner of attachment paths and file deletion (AD-12)
- `ReminderScheduler` as sole writer to the OS notification queue (AD-7)
- `EmergencyProjectionService` and its separate encrypted store (AD-21)
- `EntitlementService`, tri-state, no-op returns `unknown` (AD-19, AD-30)
- `CloudStorageProvider` interface plus three implementations (AD-13)
- Typed `go_router` routes with declared deep links for every externally-reachable surface (AD-28)
- Domain predicates for derived clinical state — one implementation each (AD-22)
- Aggregator contributor interfaces: `TimelineContributor`, `CalendarContributor`, `SummaryContributor` (AD-23)
- Generated reference-dataset test fixture (AD-27)

**Platform obligations**
- `SCHEDULE_EXACT_ALARM` (not `USE_EXACT_ALARM` — Play-ineligible for medication reminders), plus `RECEIVE_BOOT_COMPLETED` and a boot receiver
- Battery-optimisation exemption request, which also lifts the Android 14 exact-alarm denial
- `FlutterSecureStorage.xml` excluded from Android auto-backup
- Play Data Safety declaration covering AdMob identifiers and Firebase Analytics events
- iOS permission usage strings matching the in-app rationale copy, in both languages
- Public privacy-policy URL mirroring the in-app policy

### UX Design Requirements

*Extracted from DESIGN.md and EXPERIENCE.md. Each is scoped to generate a story with testable criteria.*

**Design system foundations**
- UX-DR1: Implement the DESIGN.md token set as Flutter theme extensions — colours (ground, surface, ink ×4, primary ×3, critical ×3, attention ×3, hairline ×2, border-input, chart-secondary), radii (4/6/8/14/18/full), spacing (4/8/12/16/20/24/32), elevation (hairline borders; exactly one shadow, on sheets).
- UX-DR2: Implement the type ramp with the Bangla line-height contract — body 15/26 in Bangla against 15/24 in English, display/title/heading/label/caption per DESIGN.md, Noto Sans Bengali + Noto Sans as one superfamily.
- UX-DR3: Implement a shared numeric formatter producing Bengali numerals in the Bangla locale, with `tabular-nums` on every numeric run. No raw `toString()` on a number may reach the UI.
- UX-DR4: Size every container to the Bangla measure so a language switch never reflows; long strings wrap rather than truncate.

**Shared components** *(single implementation each, per AD-23 and AD-29)*
- UX-DR5: `JotnoButton` — primary 52px, secondary/tertiary 48px, destructive; all ≥48px tap target.
- UX-DR6: `JotnoCard` and `JotnoListRow` — 1px hairline, 8px radius, no shadow; nested rows divide with the soft hairline.
- UX-DR7: `JotnoInput` — 50px, 16px text minimum (iOS zoom floor), focus state carrying a weight change as well as a hue change.
- UX-DR8: `SeverityBadge` — three semantic fills (done, attention, critical); every badge carries a word, never a bare colour dot.
- UX-DR9: `AllergyBadge` — severe treatment identical on member profile, emergency card and exported PDF; sorts above all other allergies.
- UX-DR10: `TrendChart` — one implementation serving measurements (FR-29), lab results (FR-32) and the PDF (FR-54). Draws no threshold line, no zone shading, no colour judgement.
- UX-DR11: `MemberChip` and `FilterChipRow` — single-select, broadest option first, selection persists within a session.
- UX-DR12: `JotnoSheet` — bottom sheet, one level only, grabber, the system's single shadow.
- UX-DR13: `EmptySection` — states absence in words ("No known allergies recorded"); a blank area reads as "none" to a stranger and is forbidden.

**Interaction and state**
- UX-DR14: Five fixed bottom tabs (Home, Timeline, Medications, Calendar, More); no drawer; sheets never stack two deep.
- UX-DR15: Offline is not a state — no banner, no degraded mode, no spinner on local reads. Only the four cloud operations acknowledge the network.
- UX-DR16: Determinate progress for PDF generation, backup and restore — never an indeterminate spinner.
- UX-DR17: Tap-to-call on every phone number in the app (emergency contacts, doctors, hospitals, emergency card).
- UX-DR18: Missed-dose treatment — amber, in place, retroactively actionable, never scolding; bulk review when several accumulate.
- UX-DR19: Destructive confirmation pattern — states what will be destroyed by count, requires typed or held confirmation, offers a backup first, states that cloud backups are unaffected.

**Accessibility**
- UX-DR20: Icon-only controls take a required semantic label parameter, so omitting one fails compilation.
- UX-DR21: Widget tests assert layout integrity at the largest dynamic-type setting for every screen.
- UX-DR22: Emergency card screen-reader order is name → blood group → allergies → conditions → medications → contacts.
- UX-DR23: Verify Bangla screen-reader output on real devices (TalkBack and VoiceOver) — Bengali TTS coverage is uneven and medication names must be announced intelligibly.

**Voice and microcopy**
- UX-DR24: Implement the EXPERIENCE.md voice rules in all copy — no exclamation marks, no encouragement or streaks, no clinical judgement phrasing, failures name the specific thing that failed and what to do.

### FR Coverage Map

| FR | Epic | Capability |
| --- | --- | --- |
| FR-1 | Epic 1 | First-launch welcome and privacy promise |
| FR-2 | Epic 1 | Medical disclaimer |
| FR-3 | Epic 1 | AdMob consent screen |
| FR-4 | Epic 1 | In-app privacy policy |
| FR-5 | Epic 1 | Device permission requests |
| FR-6 | Epic 1 | Family creation |
| FR-7 | Epic 1 | Member management |
| FR-8 | Epic 1 | Member dashboard |
| FR-9 | Epic 1 | Medical History records |
| FR-10 | Epic 1 | Condition tracking |
| FR-11 | Epic 1 | Allergy management |
| FR-12 | Epic 1 | Doctor directory |
| FR-13 | Epic 1 | Hospital directory |
| FR-14 | Epic 2 | Medication records |
| FR-15 | Epic 2 | Medication Schedules |
| FR-16 | Epic 2 | Medication Engine |
| FR-17 | Epic 2 | Dose logging |
| FR-18 | Epic 2 | Medication adherence history |
| FR-19 | Epic 2 | Prescriptions |
| FR-20 | Epic 3 | Appointment management |
| FR-21 | Epic 3 | Appointment reminders |
| FR-22 | Epic 3 | Post-visit notes and attachments |
| FR-23 | Epic 3 | Standalone reminders |
| FR-24 | Epic 3 | Vaccination records |
| FR-25 | Epic 3 | Vaccination reminders |
| FR-26 | Epic 4 | Measurement recording |
| FR-27 | Epic 4 | Blood Pressure detailed entry |
| FR-28 | Epic 4 | Blood Glucose detailed entry |
| FR-29 | Epic 4 | Measurement trend charts |
| FR-30 | Epic 4 | Lab Report entry |
| FR-31 | Epic 4 | Lab Result entry |
| FR-32 | Epic 4 | Lab Result history and trend |
| FR-33 | Epic 5 | Document attachment and vault |
| FR-34 | Epic 5 | Health Timeline feed |
| FR-35 | Epic 6 | Emergency Contacts |
| FR-36 | Epic 6 | Emergency Health Card content |
| FR-37 | Epic 6 | Emergency Health Card access |
| FR-38 | Epic 6 | Rapid emergency access without app unlock |
| FR-39 | Epic 3 | Family Health Calendar |
| FR-40 | Epic 1 | Encrypted local database *(foundation — everything depends on it)* |
| FR-41 | Epic 7 | PIN lock |
| FR-42 | Epic 7 | Biometric authentication |
| FR-43 | Epic 7 | Auto-lock |
| FR-44 | Epic 7 | Data deletion |
| FR-45 | Epic 7 | Local backup |
| FR-46 | Epic 1 | Recovery Phrase *(AD-3 wraps the data key with it at first launch)* |
| FR-47 | Epic 7 | Local restore |
| FR-48 | Epic 7 | Backup and restore failure handling |
| FR-49 | Epic 8 | Cloud connection lifecycle |
| FR-50 | Epic 8 | Cloud backup — Google Drive |
| FR-51 | Epic 8 | Cloud backup — OneDrive and Dropbox |
| FR-52 | Epic 8 | Cloud restore |
| FR-53 | Epic 8 | Automatic cloud backup |
| FR-54 | Epic 9 | PDF health summary export |
| FR-55 | Epic 9 | Family Health Report export |
| FR-56 | Epic 9 | CSV export |
| FR-57 | Epic 9 | JSON export |
| FR-58 | Epic 9 | CSV import |
| FR-59 | Epic 9 | JSON import |
| FR-60 | Epic 9 | Backup File import |
| FR-61 | Epic 1 | Bangla-default UI *(cross-cutting from day one — AD-18)* |
| FR-62 | Epic 1 | English UI option *(cross-cutting from day one — AD-18)* |

All 62 FRs mapped. No FR appears in two epics.

## Epic List

Nine epics. Every upstream document is final, so there is no feedback loop between epics that would change direction — this favours fewer, larger epics over many small ones.

**Dependency rule observed:** each epic builds only on epics before it. No epic requires a later one to function.

### Epic 1: Set up a family and start keeping records

A household installs Jotno, creates their family with no account, adds every member, and records the medical facts that never change day to day — conditions, allergies, past illnesses, their doctors. By the end of this epic the app is genuinely useful on its own: it holds the information a family currently keeps in a plastic folder.

This epic also lays the foundations every later epic depends on, because the architecture makes them preconditions rather than polish: the encrypted database with its runtime cipher assertion, the five CI gates, the design-token theme and shared components, the three aggregator contracts, and both languages complete from the first screen.

**FRs covered:** FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8, FR-9, FR-10, FR-11, FR-12, FR-13, FR-40, FR-46, FR-61, FR-62

### Epic 2: Never miss a dose

The family's medications are recorded, scheduled, and reminded — reliably, on real Bangladeshi devices. A dose fires at 8pm whether or not the app is open, and taking it is one tap from the notification. Adherence is visible without anyone having to remember.

This is the loop the product is judged on, and the hardest thing in the build: a 64-slot iOS ceiling, an Android permission that is denied by default, and OEMs that kill background work.

**FRs covered:** FR-14, FR-15, FR-16, FR-17, FR-18, FR-19

### Epic 3: Keep every appointment and vaccination on one calendar

Doctor visits are scheduled with reminders and closed out with notes. Children's vaccination courses are tracked dose by dose with due dates. Standalone reminders cover the rest — a lab test due, a follow-up, a weekly blood-pressure check. One month calendar shows all of it, filterable by member.

**FRs covered:** FR-20, FR-21, FR-22, FR-23, FR-24, FR-25, FR-39

### Epic 4: See health change over time

Blood pressure, glucose, weight and the rest are recorded with the clinical context that makes them meaningful, and charted across five time ranges. Lab reports carry their results and reference ranges, and any test can be tracked across years. Jotno shows the numbers and their trend; it never says whether they are good.

**FRs covered:** FR-26, FR-27, FR-28, FR-29, FR-30, FR-31, FR-32

### Epic 5: Find any document, see the whole history

Every prescription photo, lab PDF and X-ray lands in a searchable vault, filterable by member, type and date. The timeline puts every health event across every member in one chronological feed — the answer to "when did this start?"

**FRs covered:** FR-33, FR-34

### Epic 6: Be ready for the emergency

Typed emergency contacts that dial in one tap. An emergency card that leads with severe allergies, reachable in two taps from Home — or from a locked phone, without the PIN, in three actions. This is the screen read by a stranger under stress, and the only place health data lives outside the encrypted database.

**FRs covered:** FR-35, FR-36, FR-37, FR-38

### Epic 7: Protect the data and never lose it

The app locks with a PIN or fingerprint. Members and the whole family can be permanently erased, with the consequences stated by count. Encrypted backups are written to the device, protected by a password and a recovery phrase that can rebuild the key even if the phone's keystore drops it. Restore is atomic, and every failure mode says exactly what went wrong.

**FRs covered:** FR-41, FR-42, FR-43, FR-44, FR-45, FR-47, FR-48

### Epic 8: Back up to your own cloud

Connect Google Drive, OneDrive or Dropbox and encrypted backups go straight from the phone to the user's own storage — Jotno never holds them. Automatic daily or weekly backup, restore from any kept version, and a connection that says so when it breaks rather than failing silently. This is the paid tier, and it is where the in-app purchase and the free tier's ads are wired.

**FRs covered:** FR-49, FR-50, FR-51, FR-52, FR-53

### Epic 9: Take the records anywhere

A one-page health summary PDF for the doctor, a whole-family report, CSV and JSON export for anything else, and imports that complete the round trip. Nothing here is locked behind the paid tier — a user can always get their data out.

**FRs covered:** FR-54, FR-55, FR-56, FR-57, FR-58, FR-59, FR-60

---

## Epic 1: Set up a family and start keeping records

A household installs Jotno, creates their family with no account, adds every member, and records the medical facts that never change day to day. By the end of this epic the app holds what a family currently keeps in a plastic folder.

**FRs:** FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8, FR-9, FR-10, FR-11, FR-12, FR-13, FR-40, FR-46, FR-61, FR-62
**NFRs:** NFR-P1, NFR-P3, NFR-S1, NFR-S3, NFR-S4, NFR-A1, NFR-A2
**UX-DRs:** UX-DR1–9, UX-DR11, UX-DR13, UX-DR14, UX-DR15, UX-DR20, UX-DR21, UX-DR23, UX-DR24
**ADs:** AD-1, AD-2, AD-3, AD-4, AD-5, AD-6, AD-11, AD-12, AD-16, AD-17, AD-18, AD-20, AD-22, AD-23, AD-27, AD-28, AD-29

> **Validated 2026-08-30.** An independent dependency review found 7 blocking sequence violations; all are closed. Story 1.2 was added to own the eight cross-cutting foundations that had no home, `AttachmentStore` moved from Epic 2 to Epic 1 where its first consumers live, Epic 4 was reordered so `TrendChart` precedes the stories that render charts, and three Epic 7 acceptance criteria were rewritten to stop depending on Epic 8. Every named component is now created in or before the story that first uses it, and all three story cross-references point backward.

> **Re-validated 2026-09-02.** Story 1.2 was narrowed during implementation and four of its six foundations lost their owner — the same orphaning the 2026-08-30 review closed. Stories 1.4 and 1.5 reclaim them: 1.4 owns the runtime services (`HeadlessScope`, `AttachmentStore`, the contributor interfaces), 1.5 owns the measurement apparatus (reference fixture, benchmark gate). Both sit ahead of their first consumers — 1.10 and 1.12 for attachments, 1.14 for the fixture, Epic 2 for headless entry points.

> **UX-DR23 is a standing obligation, not a one-off story.** Bangla screen-reader output must be verified on real devices with TalkBack and VoiceOver — Bengali TTS coverage is uneven, and a medication name announced unintelligibly is a safety defect. Story 1.7 establishes the protocol and verifies the screens that exist at that point; every epic thereafter re-runs it over the screens it added. It cannot be satisfied in an emulator.

> **UX-DR24 (voice and microcopy) is likewise cross-cutting.** Every story that writes user-facing copy is bound by the EXPERIENCE.md voice rules: no exclamation marks, no encouragement or streaks, no clinical judgement phrasing, and failures that name the specific thing that failed and what to do about it.

### Story 1.1: A database that proves it is encrypted

As someone about to trust this app with my family's medical history,
I want the app to refuse to run rather than store my records unencrypted,
So that a build mistake can never silently expose them.

**Acceptance Criteria:**

**Given** a fresh Flutter 3.47 project with the mandated source tree (`app/ core/ shared/ features/ l10n/`) and the pinned dependency set
**When** the app starts
**Then** the database opens through `package:sqlite3` 3.x with SQLite3MultipleCiphers via Dart hooks
**And** neither `sqlcipher_flutter_libs` nor `sqlite3_flutter_libs` appears in `pubspec.yaml`

**Given** the app is starting
**When** `DatabaseService` initialises, before any query runs
**Then** it asserts the `cipher` pragma responds
**And** if it does not, the app halts with an explicit error and never opens the database

**Given** a release build
**When** the CI cipher-assertion integration test runs
**Then** it fails the build if the shipped binary produces an unencrypted database

**Given** the Drift schema at version 1
**When** `drift_dev make-migrations` runs
**Then** versioned schema files, `.steps.dart` and migration tests are generated
**And** the migration test suite runs in CI

### Story 1.2: The foundations every feature is required to use

As the person who will build fifty-eight more stories on top of this,
I want every cross-cutting service the architecture mandates to exist before any feature needs it,
So that no feature invents its own version and has to be unpicked later.

**Acceptance Criteria:**

**Given** the domain layer
**When** this story completes
**Then** `Result<T, AppFailure>` and the sealed `AppFailure` type with localisation keys exist and are exported
**And** exceptions never cross into `presentation`

**Given** logging is needed anywhere
**When** this story completes
**Then** `AppLogger` exists, accepting an event name and typed non-PII fields only
**And** the analytics event allowlist is compile-time, with no free-form parameters
**And** `toString()` on health entities returns type and id only
**And** the CI grep gate fails the build on direct `print` or `debugPrint` under `features/`

> **Narrowed 2026-09-02.** As built, this story delivered `Result`/`AppFailure` and `AppLogger` only. The four further foundations it originally carried — `HeadlessScope`, `AttachmentStore`, the three contributor interfaces, and the reference fixture with its benchmark harness — were split out during implementation and left without an owner. Stories 1.4 and 1.5 now own them, and both precede the stories that first consume them.

### Story 1.3: The app speaks Bangla first

As a Bangladeshi user,
I want the app to open in Bangla and let me switch to English,
So that I can read my family's health records in my own language.

**Acceptance Criteria:**

**Given** a fresh install on a device with any locale
**When** the app first opens
**Then** the UI renders in Bangla unless the device locale is English

**Given** the app is running
**When** the user changes language in Settings
**Then** every string switches immediately without an app restart
**And** the preference persists across launches

**Given** any number displayed in the UI in the Bangla locale
**When** it renders
**Then** it uses Bengali numerals (০–৯) via the shared formatter
**And** numeric runs set `tabular-nums`
**And** no raw `toString()` on a number reaches the UI

**Given** the ARB files
**When** the l10n parity gate runs in CI
**Then** it fails if any key exists in one locale and not the other

**Given** Bangla text at the largest dynamic-type setting
**When** any screen renders
**Then** no text overflows, clips, or corrupts a conjunct
**And** long strings wrap rather than truncate

### Story 1.4: The services no feature is allowed to reinvent

As the person about to build the first screen that stores a photo,
I want the file store, the headless container and the aggregator contracts to exist before anything needs them,
So that no feature writes a file path of its own or reaches a repository by a route nobody sanctioned.

**Acceptance Criteria:**

**Given** code that must run outside the widget tree — a notification action, a boot receiver, a background task
**When** this story completes
**Then** `HeadlessScope` exists and builds the container those entry points use to reach repositories
**And** it is the only permitted path for doing so
**And** a test drives a repository call through it with no widget tree present, because that is the condition it exists to survive

**Given** files must be attached to records
**When** this story completes
**Then** `AttachmentStore` exists in `core/storage` as the only code that constructs attachment paths or deletes attachment files
**And** the `attachments` table is created here, carrying relative path, mime, size, checksum, polymorphic `entity_type` and `entity_id`, and the standard identity columns
**And** binary content is never stored in a database column

**Given** an attachment whose owning record is deleted
**When** the deletion commits
**Then** the attachment row soft-deletes and the file remains on disk until a permanent-erasure path runs
**And** no code outside `AttachmentStore` removes an attachment file, in this story or any later one

**Given** four surfaces will later aggregate across features
**When** this story completes
**Then** `TimelineContributor`, `CalendarContributor` and `SummaryContributor` exist as domain interfaces with fixed output shapes
**And** each is a pure interface with no implementation, because the features that implement them do not exist yet

**Given** a file under `lib/features/`
**When** the CI gates run
**Then** the build fails if it constructs an attachment path or touches the filesystem directly, in the same style as the logging gate

### Story 1.5: Performance budgets that something actually measures

As the person who will be held to a three-second cold start,
I want the reference dataset and its benchmarks to exist before the first story that cites them,
So that a performance budget is a test that can fail rather than a sentence in a document.

**Acceptance Criteria:**

**Given** the reference dataset defined by the architecture
**When** this story completes
**Then** a generated fixture exists in `test/fixtures` — 10 members, 20 years, 10,000 measurements, 10,000 medication logs, 5,000 documents, 500 appointments
**And** it is seeded, so two generations produce identical data and a regression is never mistaken for noise
**And** it is regenerable by one documented command, and the generator is committed alongside it

**Given** the fixture and a budget whose surface exists
**When** the benchmark harness runs in CI on a fixed profile
**Then** the budget is asserted as a test that fails when exceeded, not reported as a number nobody reads

**Given** a budget whose surface does not exist yet — the timeline, the calendar, the PDF
**When** the harness runs
**Then** a benchmark for it is registered and skipped, naming the story that will enable it
**And** the count of skipped budgets is printed, so an unmeasured budget is visible rather than absent

**Given** the device-bound budgets — cold start (NFR-P3) and 60fps scroll (NFR-P4)
**When** this story completes
**Then** the harness states plainly that they cannot be asserted on a host runner
**And** they are recorded against the same deferred emulator job that Story 1.1's release-build cipher assertion needs, so one infrastructure decision closes both

**Given** a repository serving a list surface
**When** it is written
**Then** it exposes paged queries only; an unpaged `getAll` on a growing table fails review

**Given** the fixture generator
**When** it runs in CI
**Then** nothing it produces reaches a log or a CI annotation, because the logging gate binds test code that handles record-shaped data as firmly as it binds `lib/`

### Story 1.6: A design system the whole app inherits

As the person building every later screen,
I want the palette, type ramp and spacing to exist as theme tokens,
So that no screen invents its own colours or sizes.

**Acceptance Criteria:**

**Given** the DESIGN.md token set
**When** the theme is defined
**Then** all colour, radius, spacing and elevation tokens exist as Flutter theme extensions
**And** no widget in `features/` declares a literal colour or radius

**Given** the type ramp
**When** text renders
**Then** body sets 15/26 in the Bangla locale and 15/24 in English
**And** display, title, heading, label and caption match DESIGN.md
**And** Noto Sans Bengali and Noto Sans are loaded as one superfamily

**Given** any container holding translatable text
**When** the language switches
**Then** the layout does not reflow, because containers are sized to the Bangla measure

**Given** the elevation rules
**When** a card renders
**Then** it uses a 1px hairline border and no shadow
**And** the only shadow in the system is on bottom sheets

### Story 1.7: Shared components that carry the rules

As the person building every later screen,
I want buttons, cards, rows, inputs and badges to come from one place,
So that the accessibility floor and the severity treatment cannot drift.

**Acceptance Criteria:**

**Given** the shared component library
**When** this story completes
**Then** `JotnoButton`, `JotnoCard`, `JotnoListRow`, `JotnoInput`, `SeverityBadge`, `AllergyBadge`, `MemberChip`, `FilterChipRow` and `EmptySection` exist in `shared/`

**Given** any tappable component
**When** it renders
**Then** its tap target is at least 48px
**And** a bare `GestureDetector` on a raw container in `features/` fails review

**Given** an icon-only control
**When** it is constructed without a semantic label
**Then** compilation fails, because the label parameter is required

**Given** `JotnoInput`
**When** it receives focus
**Then** the focus state changes both border weight and hue, so it is visible without colour alone
**And** its text size is at least 16px

**Given** a section with no records
**When** it renders via `EmptySection`
**Then** it states the absence in words — "No known allergies recorded" — and never renders as a blank area

**Given** `SeverityBadge` and `AllergyBadge`
**When** either renders
**Then** it carries a word, never a bare colour dot
**And** a Severe allergy renders in the critical treatment and sorts above all other allergies

**Given** the component library and the screens built so far
**When** they are tested on a physical Android device with TalkBack and a physical iPhone with VoiceOver in Bangla
**Then** every control announces intelligibly, and the verification protocol is written down for later epics to re-run
**And** widget tests assert layout integrity at the largest dynamic-type setting

### Story 1.8: First launch leads with the promise

As someone who has never heard of this app,
I want to understand what it is and what it does with my data before I agree to anything,
So that I can decide whether to trust it.

**Acceptance Criteria:**

**Given** a fresh install
**When** the app opens for the first time
**Then** the first screen states the privacy promise and what Jotno is — no account needed, works offline, data stays on this device
**And** no registration, email or OTP field appears anywhere in onboarding
**And** no network request is made

**Given** the welcome screen is acknowledged
**When** the user proceeds
**Then** the medical disclaimer appears, stating Jotno is for record keeping only and does not diagnose or advise
**And** onboarding cannot continue until it is acknowledged
**And** the disclaimer remains reachable from Settings afterwards

**Given** the disclaimer is acknowledged
**When** the user proceeds
**Then** the AdMob consent screen appears before the AdMob SDK initialises
**And** it explains that the ad network receives a device identifier and that health records never are
**And** the user can choose personalised or non-personalised ads
**And** the choice persists and is changeable in Settings

**Given** the consent screen
**When** the user opens the privacy policy
**Then** the full policy renders in-app, in the active language, with no internet connection
**And** it covers all seven required disclosures

### Story 1.9: Create a family

As the person who manages my household's health,
I want to name my family and start,
So that the app is set up in seconds without an account.

**Acceptance Criteria:**

**Given** onboarding is complete
**When** the user reaches family creation
**Then** they can enter a family name and continue
**And** creation requires no internet connection

**Given** a family exists
**When** the user opens Settings
**Then** the family name can be edited

**Given** the family is created
**When** the app opens thereafter
**Then** Home shows the family, not an individual member

### Story 1.10: Add and manage family members

As the person who manages my household's health,
I want to add everyone in my family with their basic details,
So that each person has somewhere their records can live.

**Acceptance Criteria:**

**Given** a family exists
**When** the user adds a member
**Then** they can record full name, nickname, date of birth, gender, relationship, blood group, height, weight, profile photo and notes
**And** age is calculated and displayed from the date of birth
**And** the member is persisted with a client-generated UUIDv7 and the standard identity columns

**Given** members exist
**When** the user views the member list
**Then** all members appear, with no cap on how many can be added

**Given** a member exists
**When** the user edits or deletes them
**Then** edits persist immediately
**And** deletion is a soft delete, warns with a count of affected records, and never hard-deletes from application code

**Given** the user wants a profile photo
**When** they choose to add one
**Then** the photo-library permission is requested at that moment, preceded by an in-app rationale screen in the active language
**And** denying it hides the photo option rather than showing a broken control

### Story 1.11: Record conditions and allergies

As someone caring for a family member with a chronic illness,
I want their conditions and allergies recorded and impossible to miss,
So that anyone reading their profile sees the dangerous facts first.

**Acceptance Criteria:**

**Given** a member exists
**When** the user adds a condition
**Then** they can record name, status (Active / Resolved / Chronic), diagnosed date, linked doctor and notes
**And** the app never infers or suggests a condition

**Given** a member exists
**When** the user adds an allergy
**Then** they can record substance, type (Medication / Food / Environmental / Other), severity (Mild / Moderate / Severe / Unknown) and reaction

**Given** a member has a Severe allergy
**When** their profile renders
**Then** the allergy displays in the critical treatment, sorted above all other allergies
**And** the same treatment appears anywhere else that allergy is shown

**Given** a member has no allergies recorded
**When** the allergy section renders
**Then** it states "No known allergies recorded" rather than rendering empty

**Given** the domain layer
**When** any surface needs to know which conditions are current
**Then** it calls the `isActiveCondition` predicate, and no caller filters on status directly

### Story 1.12: Record medical history

As someone whose family has a long medical past,
I want past illnesses, surgeries and hospitalisations recorded,
So that a new doctor can be told what has already happened.

**Acceptance Criteria:**

**Given** a member exists
**When** the user adds a medical history entry
**Then** they can record type (Illness / Surgery / Hospitalisation / Injury / Other), title, date, linked doctor, linked hospital, description, status and notes

**Given** history entries exist
**When** the user views them
**Then** they are sortable by date and filterable by status

**Given** the user has a discharge summary or scan from the event
**When** they attach it
**Then** the file is written through `AttachmentStore` under the Hospital Record category
**And** the camera and photo-library permissions are requested at that moment with a rationale screen

**Given** a history entry has linked documents
**When** the entry is deleted
**Then** the entry soft-deletes and the linked documents are not deleted

### Story 1.13: Keep a directory of doctors and hospitals

As someone who takes several family members to several clinics,
I want the doctors and places we use saved once,
So that I do not retype them for every appointment.

**Acceptance Criteria:**

**Given** a family exists
**When** the user adds a doctor
**Then** they can record name, specialty, linked hospital or free-text clinic, phone, address, chamber information and notes
**And** the doctor is available to every member, not scoped to one

**Given** a family exists
**When** the user adds a hospital
**Then** they can record type (Hospital / Clinic / Diagnostic Centre / Pharmacy), name, address, phone, website and notes

**Given** doctors exist
**When** the user searches the directory
**Then** results match on name and specialty

**Given** a doctor or hospital record with a phone number
**When** the user taps the number
**Then** the device dialler opens with that number

### Story 1.14: See a member's health at a glance

As the person managing my family's health,
I want each member's dashboard to summarise what matters today,
So that I know their state without opening five screens.

**Acceptance Criteria:**

**Given** a member with records
**When** their dashboard renders
**Then** it shows calculated age, blood group, active conditions, severe allergies, and the counts and summaries available from records that exist so far
**And** every value is computed from the local database with no network call

**Given** the dashboard
**When** the user taps any section
**Then** the app navigates to that feature via a typed route

**Given** the app has no connection
**When** the dashboard renders
**Then** it displays fully, with no offline banner and no degraded mode

**Given** the reference test fixture
**When** the dashboard is benchmarked
**Then** the app is interactive within 3 seconds of cold start on a 2GB Android 10 device

### Story 1.15: A recovery phrase that can rebuild the key

As someone whose phone might be replaced or restored,
I want a phrase that can unlock my records even if the phone forgets its key,
So that a keystore failure costs me a prompt instead of my family's history.

**Acceptance Criteria:**

**Given** the database is being created for the first time
**When** the data encryption key is generated
**Then** it is stored twice — wrapped by a key held in platform secure storage, and wrapped by a key derived from the recovery phrase
**And** both wrapped copies are persisted beside the database

**Given** the recovery phrase has been generated
**When** the user has not yet confirmed saving it
**Then** a persistent, non-dismissible reminder appears in the app until they do

**Given** the recovery phrase screen
**When** it renders
**Then** the phrase is shown in numbered words
**And** the user can copy it to the clipboard or save it as a file to device storage
**And** the screen states plainly that Jotno holds no copy of it

**Given** platform secure storage has lost its key
**When** the app starts
**Then** it prompts for the recovery phrase rather than failing
**And** entering a valid phrase reconstructs the data key and opens the database with no backup file involved

**Given** the Android manifest
**When** the app is built
**Then** `FlutterSecureStorage.xml` is excluded from auto-backup

---

## Epic 2: Never miss a dose

The family's medications are recorded, scheduled and reminded — reliably, on real Bangladeshi devices. A dose fires at 8pm whether or not the app is open, and taking it is one tap from the notification.

**FRs:** FR-14, FR-15, FR-16, FR-17, FR-18, FR-19
**NFRs:** NFR-P2, NFR-P7, NFR-S2
**UX-DRs:** UX-DR10 *(partial)*, UX-DR12, UX-DR16, UX-DR18
**ADs:** AD-7, AD-8, AD-9, AD-10, AD-12, AD-15, AD-16, AD-22, AD-24, AD-25, AD-26

### Story 2.1: Record a medication

As someone managing a relative's treatment,
I want each medicine recorded with its dosage and purpose,
So that anyone can see exactly what they are taking.

**Acceptance Criteria:**

**Given** a member exists
**When** the user adds a medication
**Then** they can record name, generic name, dosage, unit, route, purpose, start date, optional end date, prescribing doctor, instructions and status

**Given** medications exist for a member
**When** any surface needs to know which are current
**Then** it calls the `isActiveMedication` domain predicate
**And** no caller filters on `status` or `end_date` directly

**Given** a medication is paused or completed
**When** the medication list renders
**Then** it remains in history and is visually distinguished from active ones

### Story 2.2: Set when a medicine is taken

As someone managing a twice-daily prescription,
I want to say what times a medicine is due,
So that the app knows when to remind us.

**Acceptance Criteria:**

**Given** a medication exists
**When** the user adds a schedule
**Then** they can set frequency (daily / specific days of week / monthly on a date), one or more times of day, dose per intake, start date and optional end date

**Given** a medicine taken three times a day
**When** the user sets 8:00, 14:00 and 20:00
**Then** this is stored as one schedule with three times, not three schedules

**Given** a schedule is being created
**When** the user chooses how it behaves
**Then** they can select Automatic, Confirmation, or Reminder-only, and the choice is stored per schedule

**Given** a schedule
**When** it is persisted
**Then** times are stored as local wall-clock plus an IANA timezone id, so a dose at 8:00 remains 8:00 after travel

### Story 2.3: Reminders that fire when the app is closed

As someone who will not remember on their own,
I want the reminder to arrive at the scheduled minute even if I never open the app,
So that the medicine actually gets taken.

**Acceptance Criteria:**

**Given** the user creates their first medication schedule
**When** the schedule is saved
**Then** one explanation screen appears, then notification permission, then exact-alarm permission, then the battery-optimisation exemption request
**And** the app declares `SCHEDULE_EXACT_ALARM`, never `USE_EXACT_ALARM`

**Given** active schedules exist
**When** `ReminderScheduler` refills
**Then** it derives the horizon from actual dose density and the platform budget — 64 pending on iOS, 500 alarms on Samsung — never a fixed number of days
**And** it partitions the budget by class (medication 60%, appointment 20%, vaccination 10%, standalone 10%) and reserves one slot for the coverage anchor
**And** it is the only code that writes to the OS notification queue

**Given** a reminder cannot fit inside its class horizon
**When** the user creates it
**Then** the app tells them at that moment that it may not fire unless the app is opened
**And** the reminder is never silently dropped

**Given** a scheduled dose
**When** the notification is built
**Then** it contains member name, medicine name and time only, produced by `NotificationContentBuilder`
**And** dosage, condition and lab values cannot be passed, because they are not parameters

**Given** the device reboots, changes timezone, or changes system clock
**When** the app or boot receiver runs
**Then** the entire pending queue is recomputed and re-registered

**Given** notification permission is revoked at OS level
**When** the app opens
**Then** a persistent banner on Medications explains that reminders cannot fire, with a route to system settings

### Story 2.4: Log a dose from the notification

As someone taking a medicine in the kitchen,
I want to confirm it from the notification without opening the app,
So that logging costs one tap.

**Acceptance Criteria:**

**Given** a reminder notification is showing
**When** the user taps Taken, Skipped or Snooze
**Then** the dose is logged without the app coming to the foreground
**And** the handler runs through `HeadlessScope`, the only path permitted to reach repositories outside the widget tree

**Given** `medication_logs`
**When** the table is created
**Then** it carries a unique constraint on `(schedule_id, scheduled_time)` in addition to its UUID

**Given** any of the three writers — notification handler, medications screen, catch-up reconciliation
**When** a dose outcome is recorded
**Then** it goes through the single `upsertLog` repository method, resolving by natural key
**And** the same dose can never produce two log rows

**Given** the user taps Snooze
**Then** the notification is rescheduled 15 minutes later and the log records `SNOOZED`

**Given** a past dose with no logged outcome
**When** the user opens the medication screen
**Then** they can log it retroactively as Taken or Skipped

### Story 2.5: Catch up after days away

As someone who did not open the app all week,
I want to see what was missed and settle it in one pass,
So that the record is accurate without me editing seven days by hand.

**Acceptance Criteria:**

**Given** the app has not been opened for several days and doses have passed unlogged
**When** the app opens
**Then** reconciliation transitions those doses from `PENDING` to `MISSED`
**And** reconciliation may never overwrite an outcome the user supplied

**Given** missed doses exist
**When** the app opens
**Then** a summary appears — "You have N missed doses across M family members" — before the home screen
**And** the user can mark all Taken, mark all Skipped, or review individually

**Given** the app opens
**When** reconciliation compares expected deliveries since last open against logged outcomes
**Then** a shortfall raises an in-app reliability warning with a route to the permission remediation
**And** this check does not depend on the notification queue, so it works when notifications are suppressed

### Story 2.6: See whether medicines are actually being taken

As someone caring for a relative at a distance,
I want to see their adherence over time,
So that I know whether the treatment is really happening.

**Acceptance Criteria:**

**Given** a medication with logged doses
**When** the user opens its history
**Then** a month calendar shows per-dose status (Taken / Skipped / Missed)
**And** an aggregate adherence percentage is shown for a selectable range

**Given** the adherence calculation
**When** it runs
**Then** it is Taken ÷ total scheduled doses in the period, expressed as a percentage
**And** it can never exceed 100%

**Given** the reference test fixture with 10,000 medication logs
**When** adherence is computed for any range
**Then** it completes within 2 seconds

### Story 2.7: Photograph a prescription once, not once per medicine

As someone leaving a clinic with a slip listing three medicines,
I want to photograph it once and attach all three medicines to it,
So that I am not storing the same photo three times.

**Acceptance Criteria:**

**Given** a member exists
**When** the user creates a prescription
**Then** they can record prescribing doctor, hospital, date, notes, and attach one or more images or PDFs
**And** attachments are written through the `AttachmentStore` built in Story 1.4, under the Prescription category

**Given** a prescription exists
**When** the user adds medications
**Then** one prescription can link to many medications, and one medication links to at most one prescription
**And** the user can create the prescription first or the medication first — neither order is forced

**Given** a prescription linked to medications
**When** the prescription is deleted
**Then** it soft-deletes and its medications become unlinked rather than being deleted

---

## Epic 3: Keep every appointment and vaccination on one calendar

Doctor visits are scheduled with reminders and closed out with notes. Children's vaccination courses are tracked dose by dose. One month calendar shows everything.

**FRs:** FR-20, FR-21, FR-22, FR-23, FR-24, FR-25, FR-39
**NFRs:** NFR-P4, NFR-S2
**UX-DRs:** UX-DR11, UX-DR14
**ADs:** AD-7, AD-15, AD-22, AD-23, AD-24, AD-25, AD-28

### Story 3.1: Schedule a doctor's appointment

As the person who takes family members to the clinic,
I want appointments recorded with who, where and when,
So that nobody misses a visit.

**Acceptance Criteria:**

**Given** a member exists
**When** the user creates an appointment
**Then** they can select the member, a doctor from the directory or free text, a hospital or free text, date, time, reason and notes
**And** status is one of Scheduled / Completed / Cancelled / Rescheduled / Missed

**Given** an appointment exists
**When** the user changes its status
**Then** the change is user-driven; the app never auto-transitions status

**Given** appointments exist
**When** the user views the list
**Then** it can be filtered to upcoming, completed, or all

### Story 3.2: Get reminded before an appointment

As someone with a 5:30pm cardiology appointment next Thursday,
I want a reminder in advance,
So that I have time to get there.

**Acceptance Criteria:**

**Given** an appointment exists
**When** the user enables reminders
**Then** they can select any combination of 1 day, 3 hours, 1 hour and 30 minutes before

**Given** reminders are scheduled
**When** they are registered
**Then** they go through `ReminderScheduler` within the appointment budget class, never directly to the OS queue
**And** the notification contains member name, doctor name, time and location only

**Given** an appointment is rescheduled
**When** the new date and time are saved
**Then** existing reminders are cancelled and new ones scheduled in the same transaction

**Given** an appointment is cancelled or its member is deleted
**When** the change is committed
**Then** `cancelFor` is called inside the same transaction, so no notification survives referencing it

### Story 3.3: Record what the doctor said

As someone who forgets the details on the way home,
I want to write down the doctor's instructions and attach what they gave me,
So that the advice is not lost.

**Acceptance Criteria:**

**Given** an appointment has taken place
**When** the user adds post-visit notes
**Then** free text is saved and visible from the appointment record

**Given** the user has a prescription, referral or lab order from the visit
**When** they attach it
**Then** the file lands in the document vault via `AttachmentStore` and links to the appointment

**Given** a prescription was created from this appointment
**When** the appointment is viewed
**Then** the linked prescription is reachable from it

### Story 3.4: Track a child's vaccination course

As a parent with a four-year-old,
I want each vaccine dose recorded with what comes next,
So that a course is never left half finished.

**Acceptance Criteria:**

**Given** a member exists
**When** the user adds a vaccination
**Then** they can record vaccine name, dose number, date administered, provider, batch number and notes
**And** they can optionally set a next-dose due date

**Given** a multi-dose vaccine
**When** its records are viewed
**Then** doses are grouped under the vaccine name in dose order, showing which are complete and which remain

**Given** the user has a vaccination card or clinic slip
**When** they attach it to a vaccination record
**Then** the file is written through `AttachmentStore` under the Vaccination category

**Given** the app
**When** vaccination records are created
**Then** no vaccination schedule is pre-loaded or recommended by the app; all due dates are user-entered

### Story 3.5: Get reminded when a vaccine dose is due

As a parent who will not remember a date six months out,
I want a reminder before the next dose is due,
So that the course completes on time.

**Acceptance Criteria:**

**Given** a vaccination has a next-dose due date
**When** the user enables a reminder
**Then** they can choose a lead time of 0, 1, 3 or 7 days before

**Given** the reminder is scheduled
**When** it is registered
**Then** it goes through `ReminderScheduler` within the vaccination budget class

**Given** the dose is administered
**When** the user marks it complete
**Then** they are offered the creation of the next dose record

### Story 3.6: Set a reminder for anything else

As someone whose father needs an HbA1c test every three months,
I want to set a reminder that is not tied to a medicine or appointment,
So that recurring health tasks are not forgotten.

**Acceptance Criteria:**

**Given** a member exists
**When** the user creates a standalone reminder
**Then** they can choose type (Lab test due / Health measurement due / Follow-up), title, date, time, optional repeat (none / daily / weekly / monthly) and notes

**Given** a standalone reminder
**When** it is scheduled
**Then** it goes through `ReminderScheduler` within the standalone budget class, with the same content restriction as every other reminder

**Given** a Follow-up reminder created from an appointment
**When** the user acts on it
**Then** they are offered a new appointment prefilled with the same doctor

**Given** a reminder is completed or dismissed
**When** the action is taken
**Then** it is logged so the timeline reflects what was acted on

### Story 3.7: See the whole family's month

As the person coordinating four people's health,
I want one calendar showing every dose, visit and vaccination,
So that I can see the month at a glance.

**Acceptance Criteria:**

**Given** medications, appointments, vaccinations and standalone reminders exist
**When** the calendar renders
**Then** all four appear on the month grid, visually distinguished by type
**And** each source feature supplies its events by implementing `CalendarContributor`
**And** the calendar never imports a source feature directly

**Given** the calendar
**When** the user selects a member filter
**Then** only that member's events display

**Given** a calendar event
**When** the user taps it
**Then** the app navigates to the underlying record via its declared typed route

**Given** the reference test fixture
**When** the calendar is scrolled
**Then** it holds 60fps, loading windowed pages rather than the full event set

---

## Epic 4: See health change over time

Vitals and lab results are recorded with the context that makes them meaningful, and charted across five time ranges. Jotno shows the numbers and their trend; it never says whether they are good.

**FRs:** FR-26, FR-27, FR-28, FR-29, FR-30, FR-31, FR-32
**NFRs:** NFR-P6
**UX-DRs:** UX-DR10, UX-DR12
**ADs:** AD-5, AD-6, AD-23, AD-27

### Story 4.1: Record a measurement

As someone tracking a relative's weight,
I want to record a reading in a few taps,
So that logging it is not a chore.

**Acceptance Criteria:**

**Given** a member exists
**When** the user records a measurement
**Then** they can choose type — blood pressure, blood glucose, weight, height, temperature, heart rate, SpO₂ — and enter value, unit, date, time and notes

**Given** both current weight and height are on record
**When** the member's measurements render
**Then** BMI is calculated and displayed automatically

**Given** the user needs a type Jotno does not offer
**When** they create a custom measurement type
**Then** they can define a name, one numeric value field and a unit string

**Given** any measurement
**When** it renders
**Then** the value uses Bengali numerals in the Bangla locale with tabular figures

### Story 4.2: See a measurement trend

As someone who cannot tell from one reading whether anything is improving,
I want to see the shape over months,
So that I can tell the treatment is working.

**Acceptance Criteria:**

**Given** measurements of one type exist for a member
**When** the user opens the trend chart
**Then** they can select 7 days, 30 days, 3 months, 6 months or 1 year

**Given** the chart component
**When** it is built
**Then** it exists once in `shared/` as `TrendChart`, and is the only chart implementation in the app — blood pressure, glucose, lab results and the PDF export all use it

**Given** the chart renders
**Then** it draws no threshold line, no zone shading and no colour judgement on any value

**Given** a data point
**When** the user taps it
**Then** the full measurement record for that entry is shown

**Given** the reference fixture with 10,000 measurements
**When** the 1-year chart renders
**Then** it completes within 2 seconds

### Story 4.3: Record blood pressure with its context

As someone whose mother measures her BP at home twice a week,
I want the surrounding detail captured,
So that the reading means something to her doctor.

**Acceptance Criteria:**

**Given** the user records a blood pressure measurement
**When** the entry sheet opens
**Then** systolic and diastolic are required, and pulse, context (before/after medication, before/after meal), arm and position are optional

**Given** systolic or diastolic is missing
**When** the user tries to save
**Then** the save is refused with a message naming which value is needed

**Given** blood pressure readings exist
**When** the chart renders
**Then** systolic and diastolic appear as two distinct lines on one chart

### Story 4.4: Record blood glucose with its measurement type

As someone managing a diabetic father,
I want each glucose reading tagged fasting or post-meal,
So that the numbers are comparable to each other.

**Acceptance Criteria:**

**Given** the user records a glucose measurement
**When** the entry sheet opens
**Then** the value is required and the measurement type — Fasting / Before meal / After meal / Random / Bedtime — is selectable

**Given** the glucose unit setting
**When** the user changes it between mmol/L and mg/dL
**Then** the change applies to display and entry for all members
**And** historical readings retain the unit they were recorded in, with conversion applied at display only

**Given** glucose readings of mixed measurement types exist
**When** the trend chart renders
**Then** the user can filter to one measurement type, because a fasting reading and a post-meal reading are not comparable on one line

**Given** a glucose value outside any plausible physiological range
**When** the user tries to save it
**Then** the app asks them to confirm the value rather than rejecting it, since Jotno records what the user reports and does not judge clinical plausibility

### Story 4.5: Record a lab report and its results

As someone who collects a CBC printout from the diagnostic centre,
I want the values typed in alongside the scan,
So that they are searchable and comparable later.

**Acceptance Criteria:**

**Given** a member exists
**When** the user creates a lab report
**Then** they can record report date, lab or diagnostic centre name, ordering doctor and notes
**And** they can attach the scan or PDF via `AttachmentStore`

**Given** a lab report exists
**When** the user adds results
**Then** each result carries test name (from a preset list or custom), value, unit, optional reference range, and a user-set out-of-range flag

**Given** a lab result
**When** it renders
**Then** the value and its reference range are displayed side by side
**And** the app never evaluates the value against the range, and never colours it good or bad

**Given** the out-of-range flag
**When** it is displayed
**Then** it is presented as the user's own marker, not the app's assessment

### Story 4.6: Track one test across years

As someone watching a father's HbA1c come down,
I want one test's history across every report,
So that I can see the direction of travel.

**Acceptance Criteria:**

**Given** multiple lab reports contain the same test name for one member
**When** the user opens that test's history
**Then** all values appear as a list sorted by date and as a trend chart

**Given** the trend chart on this screen
**When** it renders
**Then** it is the same `TrendChart` component from Story 4.2, not a second implementation

**Given** the same test recorded with different units across reports
**When** the history renders
**Then** values in incompatible units are not plotted on one line; the user is told which readings were excluded and why

**Given** a test appears in only one report
**When** the user opens its history
**Then** the single value is shown without a chart, rather than a chart with one point

---

## Epic 5: Find any document, see the whole history

Every prescription photo, lab PDF and X-ray lands in a searchable vault. The timeline puts every event across every member in one feed.

**FRs:** FR-33, FR-34
**NFRs:** NFR-P4, NFR-P5
**UX-DRs:** UX-DR11, UX-DR13
**ADs:** AD-12, AD-23, AD-27

### Story 5.1: Keep every document in one vault

As someone with three years of scans across four family members,
I want every file in one place, organised,
So that I am not hunting through the phone gallery.

**Acceptance Criteria:**

**Given** attachments have been added from prescriptions, appointments, lab reports, medical history and vaccinations
**When** the user opens the document vault for a member
**Then** every attachment appears, grouped by category — Prescription / Lab Report / Imaging / Hospital Record / Vaccination / Other

**Given** the user adds a document directly to the vault
**When** they choose a source
**Then** they can photograph it or select an existing image or PDF
**And** the file is written through `AttachmentStore`, the only owner of attachment paths

**Given** a document
**When** the user opens it
**Then** images and PDFs render in-app without leaving the encrypted context

**Given** a document's owning record is deleted
**When** the deletion commits
**Then** the attachment row soft-deletes and the file remains until permanent erasure runs

### Story 5.2: Find a document from three years ago

As someone at a clinic being asked for last year's X-ray,
I want to find it in seconds,
So that the appointment is not wasted.

**Acceptance Criteria:**

**Given** documents exist
**When** the user searches
**Then** results match on document title, notes and linked entity fields

**Given** documents exist
**When** the user applies filters
**Then** they can filter by member, document type, date range, doctor and hospital, in combination

**Given** the reference fixture with 5,000 documents across 10 members
**When** a search runs
**Then** results return within 1 second

**Given** a filter combination that matches nothing
**When** results render
**Then** the empty state names what was searched for rather than showing a blank area

### Story 5.3: See every health event in one feed

As someone trying to remember when a problem started,
I want one chronological feed of everything that has happened,
So that I can find the beginning.

**Acceptance Criteria:**

**Given** records exist across medications, appointments, measurements, lab reports, vaccinations, documents, reminders, prescriptions, medical history events and condition diagnoses
**When** the timeline renders
**Then** all of them appear in reverse-chronological order
**And** every feature that owns a dated record contributes to the timeline; a dated record type absent from the feed is a defect
**And** each source feature supplies its events by implementing `TimelineContributor`
**And** the timeline never imports a source feature directly

**Given** the timeline
**When** the user filters
**Then** they can filter by member and by event type

**Given** a timeline entry
**When** it renders
**Then** it shows date, member name, an event-type icon and a one-line summary
**And** tapping it navigates to the full record via its typed route

**Given** the reference fixture
**When** the timeline is scrolled
**Then** it holds 60fps, loading windowed pages rather than the full event set

---

## Epic 6: Be ready for the emergency

Contacts that dial in one tap. A card that leads with severe allergies, reachable in two taps from Home or from a locked phone without the PIN.

**FRs:** FR-35, FR-36, FR-37, FR-38
**NFRs:** NFR-S3, NFR-A1
**UX-DRs:** UX-DR9, UX-DR17, UX-DR22
**ADs:** AD-1, AD-5, AD-10, AD-21, AD-22, AD-23, AD-28, AD-29

### Story 6.1: Save the numbers that matter in an emergency

As someone who will be shaking when they need these,
I want the ambulance, the doctor and my brother saved and dialable,
So that I am not searching contacts in a crisis.

**Acceptance Criteria:**

**Given** a family exists
**When** the user adds an emergency contact
**Then** they can record name, phone, type (Family / Doctor / Hospital / Ambulance / Insurance / Other) and an optional note
**And** they can mark it Family-wide or assign it to one member

**Given** an emergency contact
**When** it renders
**Then** it offers Call, SMS and Copy actions
**And** Call opens the dialler with the number

**Given** a doctor or hospital already in the directory
**When** the user promotes it to an emergency contact
**Then** its details carry over without retyping

**Given** contacts exist
**When** the user reorders them
**Then** the order persists, and the first contact of each type is the one surfaced on the emergency card

### Story 6.2: One card with the facts a paramedic needs

As a stranger helping someone unconscious,
I want the dangerous facts first and in large type,
So that I can act in seconds.

**Acceptance Criteria:**

**Given** a member with records
**When** the emergency card renders
**Then** it shows name, age, blood group, all allergies, active conditions, current medications with dosages, and applicable emergency contacts

**Given** the member has a severe allergy
**When** the card renders
**Then** it appears in the critical treatment, sorted above every other allergy
**And** the same treatment appears on the member profile and the exported PDF

**Given** the member has no allergies recorded
**When** the card renders
**Then** it states "No known allergies recorded" rather than showing an empty section

**Given** the card needs to know which medications are current
**When** it renders
**Then** it calls the `isActiveMedication` predicate, so it can never disagree with the PDF export

**Given** any phone number on the card
**When** it is tapped
**Then** the dialler opens

**Given** a screen reader
**When** it reads the card
**Then** the order is name, blood group, allergies, conditions, medications, contacts

### Story 6.3: Reach the card in two taps

As someone in a hospital corridor,
I want the card without navigating a menu,
So that I find it under pressure.

**Acceptance Criteria:**

**Given** the app is open on Home
**When** the user taps the Emergency control
**Then** they reach any member's card in at most two taps — the control, then the member

**Given** the family has exactly one member
**When** the user taps the Emergency control
**Then** the card opens directly, skipping the member picker

**Given** the app's navigation
**When** it is built
**Then** the Emergency control sits on Home, not inside the More menu

### Story 6.4: Reach the card from a locked phone

As the person holding an unconscious relative's phone,
I want their allergies without knowing their PIN,
So that the ER can treat them correctly.

**Acceptance Criteria:**

**Given** the setting is off by default
**When** the user enables rapid access for a member
**Then** they do so explicitly, per member

**Given** rapid access is enabled for a member
**When** `EmergencyProjectionService` writes the projection
**Then** it contains only the emergency card field set, encrypted with its own key shared via App Group keychain on iOS or a dedicated Keystore alias on Android
**And** it never uses the main database key
**And** it is the only health data stored outside the main database
**And** it has exactly one writer

**Given** the source data for a projected member changes
**When** the change commits
**Then** the projection is rewritten

**Given** the user disables rapid access, deletes the member, or wipes all data
**When** the action commits
**Then** the projection is deleted synchronously in the same transaction

**Given** a locked device
**When** a user who knows the shortcut invokes it
**Then** the card displays within three actions, without the app PIN or biometric
**And** no other Health Profile data is reachable

**Given** a platform where no mechanism meets that requirement
**When** the feature ships
**Then** it ships on the platforms that do, and Settings explains its absence on the other

---

## Epic 7: Protect the data and never lose it

The app locks. Records can be permanently erased with the consequences stated. Encrypted backups are written to the device, and restore is atomic with every failure mode named.

**FRs:** FR-41, FR-42, FR-43, FR-44, FR-45, FR-47, FR-48
**NFRs:** NFR-P9, NFR-S3, NFR-S4
**UX-DRs:** UX-DR16, UX-DR19
**ADs:** AD-3, AD-4, AD-6, AD-12, AD-14, AD-19, AD-21, AD-24, AD-30

### Story 7.1: Lock the app with a PIN

As someone who hands their phone to a child,
I want the health records behind a PIN,
So that they are not opened by accident.

**Acceptance Criteria:**

**Given** the user sets a PIN
**When** they enter it
**Then** it must be at least 4 digits, and is stored as a salted hash in platform secure storage

**Given** a PIN is set
**When** the app launches
**Then** the PIN is required before any health data renders

**Given** five consecutive incorrect entries
**When** the fifth fails
**Then** the app locks for 30 seconds, doubling for each subsequent failure group
**And** the cooldown state survives the app being killed and relaunched

**Given** the lock screen
**When** it renders
**Then** the emergency access affordance is present and reachable without the PIN

### Story 7.2: Unlock with a fingerprint

As someone who opens the app several times a day,
I want to unlock with my fingerprint,
So that a PIN is not required every time.

**Acceptance Criteria:**

**Given** a PIN is already configured
**When** the user enables biometric unlock
**Then** fingerprint on Android or Face ID / Touch ID on iOS becomes the primary unlock

**Given** no PIN is configured
**When** the user tries to enable biometrics
**Then** they are required to set a PIN first

**Given** biometric authentication fails or is cancelled
**When** the attempt ends
**Then** the app falls back to PIN entry

**Given** a device without biometric hardware
**When** Settings renders
**Then** the option is absent rather than shown disabled

### Story 7.3: Lock automatically

As someone who puts their phone down mid-task,
I want the app to lock itself,
So that it does not sit open on a medical record.

**Acceptance Criteria:**

**Given** the user opens auto-lock settings
**When** they choose a timeout
**Then** the options are Immediately, After 1 minute (default), After 5 minutes, After 15 minutes and Never

**Given** auto-lock is set to Immediately
**When** the app is sent to the background
**Then** it locks at once

**Given** the app is locked by timeout
**When** the rapid emergency access surface is invoked
**Then** it still works, because it operates independently of the in-app lock

### Story 7.4: Make an encrypted backup on the phone

As someone whose phone is the only copy,
I want a backup file I control,
So that a lost phone does not erase my family's history.

**Acceptance Criteria:**

**Given** the user creates a backup
**When** it is written
**Then** it produces a `.hfm` archive containing `manifest.json` (format version, schema version, device id, counts, checksum), the database and all attachments
**And** the whole package is encrypted with a key derived from a user-set backup password of at least 8 characters

**Given** a backup is being created
**When** it runs
**Then** determinate progress is shown, it is cancellable, and it survives the app being backgrounded

**Given** insufficient device storage
**When** the user starts a backup
**Then** the app checks before beginning and states how much space is needed rather than failing midway

**Given** the backup completes
**When** the user is shown the result
**Then** they are reminded that losing both the password and the recovery phrase makes the file permanently unreadable

**Given** the reference fixture
**When** a backup runs
**Then** it completes without the OS terminating the app for unresponsiveness

### Story 7.5: Restore from a backup file

As someone setting up a replacement phone,
I want to restore from my backup file,
So that everything comes back.

**Acceptance Criteria:**

**Given** a `.hfm` file on the device
**When** the user starts a restore
**Then** the manifest checksum is verified before the payload is decrypted
**And** a schema version newer than the running app is refused with a message to update

**Given** the restore proceeds
**When** it runs
**Then** it stages to a temporary location and swaps only on full success
**And** existing local data is untouched until the swap
**And** a failure at any stage leaves the device exactly as it was

**Given** the restore requires credentials
**When** the user is prompted
**Then** either the backup password or the recovery phrase is accepted

**Given** the user is about to restore
**When** they confirm
**Then** they are warned that current data will be replaced and offered a backup of it first

**Given** the restore swap completes
**When** it commits
**Then** `cancelAll()` then `refill()` run on `ReminderScheduler`, so no notification references ids from the replaced database

**Given** local restore
**When** it is implemented
**Then** it carries no purchase or entitlement check of any kind, in this epic or any later one

### Story 7.6: Understand exactly what went wrong

As someone whose restore just failed,
I want to know which thing failed and what to do,
So that I am not staring at a generic error.

**Acceptance Criteria:**

**Given** an incorrect password or recovery phrase
**When** the attempt fails
**Then** the message states the credential is incorrect and offers to retry or use the other
**And** it does not reveal whether the file itself is valid
**And** it does not count toward the app-lock cooldown

**Given** a corrupted or truncated backup file
**When** it is checked
**Then** the failure is detected via the manifest checksum before decryption is attempted
**And** the file is named as unreadable, and an older backup is offered where one exists

**Given** a backup whose database restores but whose attachment files are missing
**When** the restore completes
**Then** it succeeds and reports exactly which records have missing attachments, rather than failing wholesale or dropping them silently

**Given** a backup write that was interrupted — the app was killed or storage filled mid-write
**When** the backup list is shown
**Then** the incomplete file is not listed as restorable
**And** the operation is reported as failed, not succeeded
**And** the partial file is cleaned up on the next backup attempt

**Given** any of these failures
**When** they occur
**Then** existing local data is intact

### Story 7.7: Delete a member, or everything

As someone who no longer wants this data on this phone,
I want to erase it permanently and know exactly what goes,
So that I am not guessing what remains.

**Acceptance Criteria:**

**Given** the user chooses to delete a member
**When** the confirmation appears
**Then** it states a count of that member's records by type

**Given** the user chooses to delete all data
**When** the confirmation appears
**Then** it states the family name and total member count
**And** requires typed or held confirmation, never a single tap

**Given** either deletion is confirmed
**When** it executes
**Then** database rows, their soft-deleted predecessors and the associated attachment files are permanently removed
**And** `AttachmentStore` performs all file removal
**And** `ReminderScheduler.cancelFor` runs inside the same transaction
**And** any emergency projection for the affected members is deleted in the same transaction

**Given** delete-all
**When** it completes
**Then** every secret held in secure storage is cleared — the encryption key, the PIN hash, the ad-consent choice, and any provider tokens present
**And** the app returns to its first-launch state

**Given** backup files exist outside the app — on device storage, or in a connected cloud once that exists
**When** either deletion is confirmed
**Then** the confirmation states plainly that those copies are not affected

**Given** either deletion
**When** the user confirms
**Then** they are offered a backup first

---

## Epic 8: Back up to your own cloud

Connect Google Drive, OneDrive or Dropbox and encrypted backups go straight from the phone to the user's own storage. This is the paid tier.

**FRs:** FR-49, FR-50, FR-51, FR-52, FR-53
**NFRs:** NFR-P1, NFR-P9
**UX-DRs:** UX-DR15, UX-DR16
**ADs:** AD-1, AD-13, AD-14, AD-19, AD-20, AD-30

### Story 8.1: Buy Private Backup and remove ads

As someone who wants my records safe off this phone,
I want to pay once and unlock cloud backup,
So that I am not relying on a single device.

**Acceptance Criteria:**

**Given** the free tier
**When** the user opens a cloud backup feature
**Then** the Private Backup purchase screen appears, stating what it unlocks and that local backup, restore and export remain free

**Given** `EntitlementService`
**When** it is queried
**Then** it returns one of `entitled`, `notEntitled` or `unknown`
**And** the no-op implementation returns `unknown`, never `notEntitled`
**And** recovery paths treat `unknown` as permitted

**Given** a purchase completes
**When** entitlement refreshes
**Then** cloud features unlock and, for the ad-free purchase, all AdMob surfaces are removed

**Given** ads are displayed
**When** any screen renders
**Then** no ad appears on the emergency card, a medication reminder screen, or any active data-entry screen
**And** the excluded-screen list is a constant owned by the ads module, not a per-screen decision

**Given** health data
**When** ads are requested
**Then** no health content is passed as a targeting signal

### Story 8.2: Connect Google Drive and back up

As someone who already uses Google Drive,
I want backups going to my own Drive,
So that nobody else is holding my family's records.

**Acceptance Criteria:**

**Given** the user has Private Backup
**When** they connect Google Drive
**Then** OAuth runs, requesting only the app-folder scope, not full Drive access
**And** scopes are obtained via `authorizationClient.authorizeScopes`, separate from sign-in
**And** the token is stored in platform secure storage

**Given** Drive is connected
**When** the user backs up
**Then** the same encrypted `.hfm` produced by local backup is uploaded to a dedicated app folder
**And** the transfer goes device-to-provider directly, with no Jotno server involved

**Given** the provider implementation
**When** it is written
**Then** it satisfies the `CloudStorageProvider` interface, and no provider type name appears outside its own file and the registry

**Given** a provider is now connected
**When** the user revisits the recovery phrase screen from Story 1.15
**Then** saving the phrase to that provider becomes available as a destination
**And** choosing the same provider that holds their backups shows an explicit warning that one account compromise then yields both the encrypted backup and the means to open it
**And** the app recommends a different location without preventing the choice

### Story 8.3: Connect OneDrive or Dropbox

As someone who does not use Google,
I want the same backup to my own OneDrive or Dropbox,
So that I am not forced into one ecosystem.

**Acceptance Criteria:**

**Given** the user has Private Backup
**When** they connect OneDrive
**Then** authentication runs through MSAL and uploads go via Graph REST to an app folder

**Given** the user has Private Backup
**When** they connect Dropbox
**Then** authentication runs through the Dropbox client and uploads go to an app folder

**Given** either provider
**When** it is implemented
**Then** it satisfies the same `CloudStorageProvider` interface as Drive, adding no new interface methods

**Given** multiple providers connected
**When** the user backs up
**Then** they can choose which provider receives the backup

### Story 8.4: Restore from your cloud

As someone with a new phone in their hand,
I want to pull my backup down and restore it,
So that setup takes minutes.

**Acceptance Criteria:**

**Given** a connected provider with backups
**When** the user browses them
**Then** each entry shows backup date, file size and provider

**Given** the user selects a backup
**When** the restore proceeds
**Then** it follows the same verification, staging, atomic swap and failure handling as local restore

**Given** a corrupted backup in the list
**When** the list renders
**Then** it is shown greyed and labelled as unreadable, never silently omitted

**Given** the restore requires credentials
**When** the user is prompted
**Then** either the backup password or the recovery phrase is accepted

### Story 8.5: Back up automatically

As someone who will never remember to do this manually,
I want backups to happen on their own,
So that the copy stays current.

**Acceptance Criteria:**

**Given** a connected provider
**When** the user enables automatic backup
**Then** they can choose Daily or Weekly

**Given** automatic backup is enabled
**When** the interval has elapsed
**Then** a backup is triggered on app open or by the background task
**And** it does not depend on an exact-time background execution

**Given** automatic backups accumulate
**When** the eighth is written
**Then** the oldest is deleted, keeping the seven most recent per provider

**Given** an automatic backup fails
**When** the failure occurs
**Then** the user is notified in-app, and the failure is not retried silently forever

### Story 8.6: Know when the connection breaks

As someone who assumed backups were still running,
I want to be told when they stopped,
So that I do not discover it when I need the backup.

**Acceptance Criteria:**

**Given** a cloud operation returns an authentication failure
**When** it is handled
**Then** the provider is marked Disconnected in Backup & Sync with a Reconnect action that re-runs OAuth

**Given** automatic backup fails on authentication
**When** the first failure occurs
**Then** a persistent notice appears on Backup & Sync and a local notification is sent, both naming the provider and how long since the last successful backup

**Given** the Backup & Sync screen
**When** it renders
**Then** it shows, per provider, the time of the last **successful** backup — not the last attempt

**Given** the user disconnects a provider
**When** they confirm
**Then** the stored OAuth token is deleted from secure storage and automatic backups to it stop
**And** backups already in their cloud are not deleted

**Given** a quota-exceeded or network-unavailable failure
**When** it is reported
**Then** it is distinguished from an authentication failure, because the remedy differs

---

## Epic 9: Take the records anywhere

A one-page summary for the doctor, a family report, CSV and JSON export, and imports that complete the round trip. None of it gated.

**FRs:** FR-54, FR-55, FR-56, FR-57, FR-58, FR-59, FR-60
**NFRs:** NFR-P8
**UX-DRs:** UX-DR9, UX-DR10, UX-DR16
**ADs:** AD-6, AD-14, AD-22, AD-23, AD-27, AD-30

### Story 9.1: One page for the doctor

As someone walking into a paediatrician's office,
I want a single page with everything they will ask for,
So that the consultation starts informed.

**Acceptance Criteria:**

**Given** a member with records
**When** the user exports a health summary
**Then** the PDF contains name, age, blood group, allergies with severe highlighted, active conditions, current medications with dosages, upcoming appointments, vaccination record, recent measurements, recent lab results and emergency contacts

**Given** the PDF is generated
**When** it renders
**Then** it is in the app's active language
**And** each page carries the member's name and the generation date
**And** it carries the same medical disclaimer the app does

**Given** the PDF assembles content
**When** it gathers each section
**Then** it does so through `SummaryContributor` implementations, never by importing source features
**And** it calls the same domain predicates as the emergency card, so the two can never disagree

**Given** the user exports
**When** generation completes
**Then** they can preview before sharing, and share via the device share sheet

**Given** the reference fixture
**When** a single-member PDF is generated
**Then** it completes within 10 seconds

### Story 9.2: A report for the whole family

As someone registering the household with a new family doctor,
I want one document covering everyone,
So that I hand over one file, not five.

**Acceptance Criteria:**

**Given** multiple members exist
**When** the user exports a family report
**Then** they can select which members to include rather than always all

**Given** the report generates
**When** it renders
**Then** a family summary page precedes one section per member, each in the same shape as the single-member summary

**Given** generation is running
**When** it takes time
**Then** determinate progress is shown and the UI is not blocked

### Story 9.3: Export to CSV

As someone who wants to chart readings in Excel,
I want the data as a spreadsheet,
So that I can work with it outside the app.

**Acceptance Criteria:**

**Given** records exist
**When** the user exports CSV
**Then** they can export measurements, medications, medication logs, appointments, vaccinations, medical history and lab results

**Given** the export scope
**When** the user chooses
**Then** they can export one member or the whole family
**And** whole-family exports carry a member column identifying each row's owner

**Given** Bangla text in the data
**When** the CSV is written
**Then** it uses UTF-8 with BOM so it opens correctly in Excel

### Story 9.4: Export to JSON

As someone who wants a complete machine-readable copy,
I want everything as JSON,
So that nothing is lost in translation.

**Acceptance Criteria:**

**Given** records exist
**When** the user exports JSON
**Then** they can export one member's full health profile or the entire family

**Given** the JSON export
**When** it is written
**Then** every field the app stores is represented, so it can be re-imported without loss
**And** it carries a schema version, so an importer can refuse a file it does not understand

**Given** attachments exist
**When** the JSON export runs
**Then** attachment metadata is included and the export states plainly that the files themselves are not — a full copy including files requires a `.hfm` backup

**Given** the export is shared
**When** the user chooses a destination
**Then** it goes through the device share sheet, and the app warns that JSON is unencrypted plain text

### Story 9.5: Import from CSV

As someone moving from a spreadsheet,
I want to bring my existing records in,
So that I do not retype three years of readings.

**Acceptance Criteria:**

**Given** a CSV file
**When** the user imports it
**Then** the flow is file select, column mapping, preview of the first 10 rows, validation, then commit

**Given** the app proposes a column mapping from the header row
**When** the user reviews it
**Then** they can adjust every mapping before continuing

**Given** validation finds errors
**When** results are shown
**Then** each problem is reported per row with a description, before any data is written

**Given** the import commits
**When** it runs
**Then** it is a single database transaction — all rows commit or none do

**Given** a file spanning several members
**When** the user maps it
**Then** they can map a member column, or choose a single target member

### Story 9.6: Import from JSON

As someone restoring to a different app installation,
I want my JSON export to import cleanly,
So that the round trip actually works.

**Acceptance Criteria:**

**Given** a Jotno JSON export
**When** the user imports it
**Then** the file is validated against the expected schema before import begins

**Given** the import proceeds
**When** the user chooses how to apply it
**Then** they can merge into the existing family or replace it
**And** replace offers a backup first

**Given** a JSON file from a newer app version
**When** it is validated
**Then** it is refused with a message to update, never partially imported

**Given** the import commits
**When** it runs
**Then** it is a single transaction — all or nothing

### Story 9.7: Import a backup file

As someone handed a `.hfm` from an old phone,
I want to open it here,
So that I can recover without the cloud.

**Acceptance Criteria:**

**Given** a `.hfm` file
**When** the user imports it
**Then** it follows the same verification, staging, atomic swap and failure handling as local and cloud restore

**Given** entitlement state is unknown or the user has not purchased
**When** they import a `.hfm` file
**Then** it proceeds, because backup-file import is never gated

**Given** a `.hfm` produced on a different device
**When** it is imported
**Then** it restores normally — the backup carries a device id for future sync, but nothing binds a backup to the device that made it

**Given** the app currently holds data
**When** the user imports a `.hfm`
**Then** they choose replace or merge, are offered a backup of current data first, and are warned that replace discards what is on the device
