# Epics Validation — Dependency Violations and Orphaned Infrastructure

Target: `_bmad-output/planning-artifacts/epics.md` (59 stories, 9 epics)
Date: 2026-08-31
Scope: A) orphaned infrastructure, B) table creation ownership, C) forward dependencies, D) FR coverage at story level, E) story sizing.

Findings are appended in discovery order. Severity: **BLOCKER** (a story cannot be built in sequence), **MAJOR** (missing owner / unclaimed artifact), **MINOR** (clarity or sizing).

---

## A. Infrastructure creation ownership

| Component | Created by | Status |
| --- | --- | --- |
| `Result`/`AppFailure` | Story 1.1 | OK |
| `AppLogger` | Story 1.1 | OK |
| `TimelineContributor` / `CalendarContributor` / `SummaryContributor` (interfaces) | Story 1.1 | OK (interfaces only — see registrations below) |
| `AttachmentStore` | Story 2.7 | Created late — see C-1, C-2 |
| `NotificationContentBuilder` | Story 2.3 | OK |
| `ReminderScheduler` | Story 2.3 | OK |
| `isActiveCondition` | Story 1.8 | OK |
| `isActiveMedication` | Story 2.1 | OK |
| `TrendChart` | Story 4.4 | Created late within Epic 4 — see C-6 |
| `EmergencyProjectionService` | Story 6.4 | OK |
| `EntitlementService` | Story 8.1 | Created late — see C-7 |
| `CloudStorageProvider` | **no story creates the interface** | ORPHANED (implicit) — see A-1 |
| `HeadlessScope` | **no story** | **ORPHANED** — see A-2 |
| Reference test fixture (AD-27) | **no story** | **ORPHANED** — see A-3 |
| NFR-P benchmark CI suite (AD-27) | **no story** | **ORPHANED** — see A-3 |
| Typed `go_router` route layer + deep links (AD-28) | **no story** | **ORPHANED** — see A-4 |
| Contributor *registrations* (as opposed to interfaces) | 3.7 / 5.3 / 9.1 retrofit them | see A-5 |

---

## Findings

### C-1 — Story 1.9 depends on `AttachmentStore`, built in Story 2.7 — BLOCKER

Story 1.9 (Record medical history) AC: "**Given** a history entry has linked documents / **When** the entry is deleted / **Then** the entry soft-deletes and the linked documents are not deleted." Linked documents require the `attachments` table and `AttachmentStore`, which Story 2.7 explicitly introduces ("**Given** `AttachmentStore` does not yet exist / **When** this story completes / **Then** it exists in `core/storage`"). Epic 1 cannot satisfy this AC. Also affects FR-9's "linked documents" clause.

### A-1 — `CloudStorageProvider` interface has no creating story — MAJOR

Story 8.2 says the Drive implementation "satisfies the `CloudStorageProvider` interface"; Story 8.3 says OneDrive/Dropbox satisfy "the same interface ... adding no new interface methods". Neither story's AC creates the interface, and Story 1.1 (which does create `Result`/`AppFailure`/`AppLogger`/the three contributor interfaces) does not include it. The Additional Requirements list it as a "cross-cutting foundation that must precede feature work" (AD-13). Implicit ownership by 8.2 is the only reading, which contradicts "no provider type name appears outside its own file and the registry" — the registry also has no creating story.

### A-2 — `HeadlessScope` is ORPHANED; three stories depend on it — BLOCKER

No story's AC creates `HeadlessScope`. It is consumed by:
- Story 2.4: "the handler runs through `HeadlessScope`, the only path permitted to reach repositories outside the widget tree"
- Story 2.3: boot receiver recomputing the pending queue (a non-widget entry point)
- Story 8.5: "or by the background task" (WorkManager — a non-widget entry point)

The Additional Requirements name it explicitly (AD-16) as a precondition. Story 1.1 was the natural owner and does not claim it.

### A-3 — The reference test fixture and the NFR-P benchmark CI gate are ORPHANED — BLOCKER

The Additional Requirements list two AD-27 items as mandatory preconditions: the "Generated reference-dataset test fixture" and the "NFR-P benchmark suite against the committed reference fixture" CI gate. No story creates either. Story 1.1 creates only three of the five mandated CI gates (cipher assertion, migration tests, logging grep); Story 1.2 creates the fourth (l10n parity); the fifth is unclaimed.

The fixture is consumed by the AC of at least eight stories: 1.11 (3s cold start), 2.6 (10,000 logs / 2s), 3.7 (60fps calendar), 4.4 (10,000 measurements / 2s), 5.2 (5,000 documents / 1s), 5.3 (60fps timeline), 7.4 (backup without ANR), 9.1 (PDF within 10s). The first consumer, Story 1.11, is unbuildable as written.

### A-4 — Typed `go_router` route layer (AD-28) has no creating story — MAJOR

Story 1.11 AC: "the app navigates to that feature via a typed route." Stories 3.7 and 5.3 both require navigation "via its declared typed route." No story establishes the router, the typed route definitions, or the declared deep links that AD-28 requires "for every externally-reachable surface." Story 6.4's locked-device entry point is exactly such a surface and is the one most dependent on a deep link.

### A-5 — Contributor interfaces exist from 1.1, but no producing story registers an implementation — MAJOR

Story 1.1 creates `TimelineContributor`, `CalendarContributor` and `SummaryContributor` as interfaces. No story in Epics 1, 2, 4 or 6 has an AC requiring its feature to implement them. The obligation lands entirely on the consuming stories:
- Story 3.7 must retrofit `CalendarContributor` onto medications (built in Epic 2, no such AC there).
- Story 5.3 must retrofit `TimelineContributor` onto measurements, lab reports, documents and reminders.
- Story 9.1 must retrofit `SummaryContributor` onto roughly eight features across five earlier epics.

Each consuming story therefore reaches back and edits multiple earlier epics' feature code. This is a real sequencing cost even though it is not strictly a forward dependency.

---

## B. Table creation ownership

| Table | Created by | Status |
| --- | --- | --- |
| family | Story 1.6 (implicit — "the user can enter a family name") | implicit, no explicit persistence AC |
| members | Story 1.7 (explicit: UUIDv7 + standard identity columns) | OK |
| conditions | Story 1.8 | OK |
| allergies | Story 1.8 | OK |
| medical_history | Story 1.9 | OK |
| doctors | Story 1.10 | OK |
| hospitals | Story 1.10 | OK |
| medications | Story 2.1 | OK |
| medication_schedules | Story 2.2 | OK |
| medication_logs | Story 2.4 (explicit: "When the table is created") | OK |
| prescriptions | Story 2.7 | OK |
| attachments | Story 2.7 (explicit: "attachment rows carry relative path, mime, size, checksum, `entity_type`, `entity_id`") | OK but too late — see C-1, C-2 |
| appointments | Story 3.1 | OK |
| vaccinations | Story 3.4 | OK |
| reminders | Story 3.6 | implicit only — no persistence AC, only field list |
| measurements | Story 4.1 | OK |
| lab_reports | Story 4.5 | OK |
| lab_results | Story 4.5 | OK |
| emergency_contacts | Story 6.1 | OK |
| emergency projection store | Story 6.4 (separate encrypted store, own key) | OK |

### B-1 — Story 1.1 defines "the Drift schema at version 1" without saying what is in it — MINOR

Every subsequent table-creating story implicitly bumps the schema version and must regenerate migrations. That is consistent with the `make-migrations` gate, but no story states the v1 table set, so "version 1" is undefined and the migration ladder has no declared starting point.

### B-2 — No story creates a search index — MINOR

Story 5.2 requires "results return within 1 second" against 5,000 documents matching on "document title, notes and linked entity fields" (NFR-P5). No story creates an FTS table or index. The work is implicit inside 5.2 but the schema change is unclaimed.

---

## C. Forward dependencies

### C-2 — Story 1.7 stores a profile photo before `AttachmentStore` exists — BLOCKER

Story 1.7 AC: "they can record ... profile photo" and requests the photo-library permission. AD-12 makes `AttachmentStore` "the sole owner of attachment paths and file deletion", and Story 2.7 creates it. Story 1.7 therefore either writes an image file outside `AttachmentStore` (violating AD-12) or cannot be completed. Story 7.7's permanent-erasure AC ("`AttachmentStore` performs all file removal") will then miss profile photos written by the Epic 1 path.

### C-3 — Story 1.12 requires a connected cloud provider, built in Epic 8 — BLOCKER

Story 1.12 AC: "the user can copy it, save it as a file to the device, **or save it to a connected cloud provider** ... choosing the same cloud that holds their backups shows an explicit warning". Cloud provider connection (OAuth, `CloudStorageProvider`) is built in Stories 8.2 and 8.3, seven epics later, and is behind the Private Backup IAP established in 8.1. Epic 1 cannot satisfy this clause.

### C-4 — Story 1.5 gates an AdMob SDK that no Epic 1 story integrates — MAJOR

Story 1.5 AC: "the AdMob consent screen appears **before the AdMob SDK initialises**" and the choice "persists and is changeable in Settings". No story in Epic 1 integrates the AdMob SDK or renders any ad surface; ad placement, the excluded-screen constant and ad removal all live in Story 8.1. The consent gate has nothing to gate until Epic 8, and 8.1's ad work has no earlier ads module to build on.

### C-5 — Story 1.4 verifies accessibility on screens that do not exist yet — MAJOR

Story 1.4 AC: "the component library **and the screens built so far** ... tested on a physical Android device with TalkBack and a physical iPhone with VoiceOver in Bangla". At 1.4 the only preceding stories are 1.1 (database), 1.2 (l10n) and 1.3 (theme) — no feature screen exists. The verification is real work with nothing to verify; the screens it is meant to cover (1.5–1.12) all come after. Either 1.4 should move after 1.11, or the device-verification AC should split into a separate end-of-epic story.

### C-6 — Stories 4.2 and 4.3 render trend charts before Story 4.4 builds `TrendChart` — BLOCKER

- Story 4.2 AC: "**When** the chart renders / **Then** systolic and diastolic appear as two distinct lines on one chart."
- Story 4.3 AC: "**When** the trend chart renders / **Then** the user can filter to one measurement type."

`TrendChart` is created in Story 4.4 ("**When** it is built / **Then** it exists once in `shared/` as `TrendChart`"). Both 4.2 and 4.3 either build a throwaway chart (which 4.4 and UX-DR10 forbid — "one implementation ... not a second implementation") or cannot meet their AC. The chart-behaviour clauses belong in 4.4, or 4.4 must move ahead of 4.2.

### C-7 — Epic 7 depends on `EntitlementService`, cloud upload, OAuth tokens and the Backup & Sync screen — all Epic 8 — BLOCKER

Four separate Epic 7 ACs reach forward into Epic 8:
- Story 7.5: "**Given** entitlement state is unknown / **When** the user restores from a local file / **Then** it proceeds" — `EntitlementService` and its tri-state contract are created in Story 8.1.
- Story 7.6: "**Given** an upload that did not complete / **When** the backup list is shown / **Then** no partial file is listed as restorable" — uploads exist only from Story 8.2 onward. This AC is pure Epic 8 content.
- Story 7.7: "the encryption key, **OAuth tokens**, PIN and ad-consent choice are cleared from secure storage" — OAuth tokens are first stored in Story 8.2.
- Story 7.7: "the confirmation states plainly that [cloud backups] are not affected, **with a route to Backup & Sync**" — the Backup & Sync screen is created across Stories 8.1–8.6.

Epic 7's own AD list includes AD-19 and AD-30 (entitlement), which confirms the leak is intentional at epic level rather than an oversight — but it still breaks the document's own stated rule: "each epic builds only on epics before it."

### C-8 — Story 3.6 and Story 6.2 assert outcomes visible only in later stories — MINOR

- Story 3.6: "it is logged so **the timeline** reflects what was acted on" — the timeline is Story 5.3.
- Story 6.2: "the same treatment appears on the member profile and **the exported PDF**" — the PDF is Story 9.1.

Both are verifiable only after the later story lands. Not blocking (the underlying data work is local), but the AC as written cannot be demonstrated at story close.

### C-9 — Epic 2 claims UX-DR10 (partial) but `TrendChart` is Epic 4 — MINOR

Epic 2's header lists "UX-DR10 *(partial)*". No Epic 2 story builds or uses `TrendChart` — Story 2.6 uses a month calendar and an aggregate percentage. Either the epic-level mapping is wrong, or Story 2.6 was meant to chart adherence, in which case it forward-depends on Story 4.4.

---

## D. FR coverage at story level

All 62 FRs have at least one owning story. Story-level mapping (abbreviated to the FRs with problems; the rest map cleanly):

| FR | Owning story | Status |
| --- | --- | --- |
| FR-5 Device permission requests | 1.7 (photo), 2.3 (notification/exact-alarm/battery), 2.7 (camera) | split across three stories, no story owns the rationale pattern itself |
| FR-9 Medical History incl. "linked documents" | 1.9 | **partial** — see D-1 |
| FR-24 Vaccination records | 3.4 | complete for FR-24, but see D-2 |
| FR-33 Document vault | 5.1, 5.2 | **partial** — see D-1, D-2 |
| FR-34 Health Timeline "all events" | 5.3 | **partial** — see D-3 |
| FR-29 Measurement trend charts | 4.4 | complete, but 4.2/4.3 pre-empt it — see C-6 |

### D-1 — FR-9 / FR-33: nothing lets a user attach a document to a medical-history entry — MAJOR

Story 1.9's only document clause is a deletion rule: "**Given** a history entry has linked documents / **When** the entry is deleted / **Then** ... the linked documents are not deleted." No AC anywhere provides the attach action for medical history. Story 5.1 nonetheless opens with "**Given** attachments have been added from prescriptions, appointments, lab reports, **medical history** and vaccinations", so the vault's precondition is never established. FR-9's "linked documents" clause is not genuinely implemented.

### D-2 — FR-24 / FR-33: nothing lets a user attach a document to a vaccination record — MAJOR

Story 3.4's field list is "vaccine name, dose number, date administered, provider, batch number and notes" — no attachment. Story 5.1 lists **Vaccination** as one of the six vault categories and names vaccinations as an attachment source. The category will always be empty. Same defect shape as D-1.

Attachment sources that *are* genuinely implemented: prescriptions (2.7), appointments (3.3), lab reports (4.5), direct-to-vault (5.1). Missing: medical history, vaccinations. The Imaging and Hospital Record categories in 5.1 also have no producing story — only the direct-to-vault path in 5.1 itself can fill them.

### D-3 — FR-34: the timeline's source list omits Epic 1's clinical records — MAJOR

FR-34 is "Health Timeline feed — **all events**, all members, filterable". Story 5.3 enumerates its sources as "medications, appointments, measurements, lab reports, vaccinations, documents and reminders". Medical history entries (FR-9 — illnesses, surgeries, hospitalisations, injuries, each with a date) are absent, as are condition diagnoses (FR-10, which carry a diagnosed date). These are precisely the events that answer the story's own premise, "when did this start?" As written, the AC does not implement FR-34 in full.

### D-4 — NFR-P3 through NFR-P8 are asserted but the measuring apparatus is unowned — MAJOR

Every performance NFR is written into some story's AC as a "Given the reference test fixture" clause, but the fixture and the benchmark CI gate have no creating story (A-3). The FR coverage map claims completeness at epic level; at story level the performance obligations are unexecutable.

---

## E. Story sizing

Stories whose AC spans several unrelated subsystems and will not fit one focused session:

### E-1 — Story 1.1 spans seven unrelated subsystems — MAJOR

Project scaffold and pinned dependency set; `sqlite3` + SQLite3MultipleCiphers via Dart hooks; runtime cipher-pragma assertion; a release-build CI integration test; Drift schema v1 + `make-migrations` + a migration test suite in CI; a logging grep CI gate; the `Result`/`AppFailure` error model; `AppLogger`; and three aggregator contributor interfaces. Build configuration, encryption, migrations, CI, error modelling, logging and aggregation contracts are seven separate concerns. Natural split: (a) scaffold + encrypted DB + cipher assertion, (b) Drift schema v1 + migration tooling + gate, (c) cross-cutting kernel (`Result`/`AppFailure`/`AppLogger`/contributor interfaces) + logging gate.

### E-2 — Story 2.3 spans permission choreography, scheduling algebra and OS lifecycle — MAJOR

Four sequential OS permission requests plus a battery-optimisation exemption; `ReminderScheduler` with a horizon derived from dose density and per-platform budget (64 iOS / 500 Samsung); budget partitioning across four classes with a reserved coverage anchor; over-horizon user warning; `NotificationContentBuilder` with compile-time content restriction; full queue recomputation on reboot, timezone change and clock change; and a revoked-permission banner with a settings route. This is the highest-risk story in the document and the largest.

### E-3 — Story 2.7 mixes core infrastructure with a feature — MAJOR

Creates `AttachmentStore` (a cross-cutting AD-12 foundation), the attachments table, the camera permission flow, the prescriptions entity and its CRUD, the many-to-one prescription↔medication link with order-independent creation, and prescription delete/unlink semantics. The `AttachmentStore` half belongs in Epic 1 (see C-1, C-2); what remains is a reasonable single story.

### E-4 — Story 6.4 spans two platforms' crypto and lock-screen surfaces — MAJOR

Per-member opt-in setting; `EmergencyProjectionService`; a separate encrypted store with its own key; iOS App Group keychain plus an Android dedicated Keystore alias; write-through on every source-data change; synchronous deletion inside three different transactions; a locked-device entry surface reachable in three actions; and a per-platform graceful-degradation path with Settings copy. This is at least three stories (projection service + store; iOS surface; Android surface).

### E-5 — Story 1.12 mixes key management with a UI flow and a manifest change — MINOR

Double-wrapped DEK generation and persistence; recovery-phrase derivation; numbered-word display; copy / save-to-file / save-to-cloud (the last is C-3); a persistent non-dismissible reminder; the keystore-loss recovery path; and the Android auto-backup manifest exclusion.

### E-6 — Story 8.1 mixes IAP, entitlement and the entire ads policy — MINOR

Purchase screen and flow; `EntitlementService` tri-state semantics including the no-op contract; entitlement refresh unlocking cloud features; ad removal on purchase; the excluded-screen constant owned by the ads module; and the no-health-data-as-targeting-signal guarantee.

### E-7 — Story 7.7 spans deletion, erasure, scheduling, projection and secure storage — MINOR

Member delete with per-type counts; delete-all with typed/held confirmation; permanent erasure of rows *and* soft-deleted predecessors *and* attachment files; `ReminderScheduler.cancelFor` in-transaction; emergency projection deletion in-transaction; secure-storage wipe of key, OAuth tokens, PIN and ad consent; reset to first-launch state; cloud-backup disclaimer with a route; and a pre-deletion backup offer.

### E-8 — Story 9.1 must retrofit `SummaryContributor` across five epics — MINOR

The PDF layout itself is one story; "it gathers each section ... through `SummaryContributor` implementations" requires implementing contributors in roughly eight features that never had an AC to provide one (A-5).

### E-9 — Story 1.4 bundles nine components with a physical-device verification protocol — MINOR

Nine shared components, a compile-time semantic-label constraint, dynamic-type widget tests, and a two-platform physical-device TalkBack/VoiceOver protocol that must also be written down for later epics. The device-verification half is a distinct piece of work and is also mis-sequenced (C-5).

---

## Summary

| Severity | Count |
| --- | --- |
| BLOCKER | 7 |
| MAJOR | 13 |
| MINOR | 9 |
| **Total** | **29** |

**BLOCKERs:** A-2 (`HeadlessScope` orphaned), A-3 (reference fixture + benchmark gate orphaned), C-1 (1.9 → 2.7), C-2 (1.7 → 2.7), C-3 (1.12 → 8.2/8.3), C-6 (4.2/4.3 → 4.4), C-7 (7.5/7.6/7.7 → Epic 8).

**Root cause pattern:** Story 1.1 is the document's designated foundation story, but the Additional Requirements section lists thirteen cross-cutting foundations and Story 1.1 claims only five of them (`Result`/`AppFailure`, `AppLogger`, and the three contributor interfaces) plus the encrypted DB. The eight it does not claim — `AttachmentStore`, `ReminderScheduler`, `HeadlessScope`, `EmergencyProjectionService`, `EntitlementService`, `CloudStorageProvider`, typed routes, the reference fixture — are either pushed into the first feature story that needs them (creating the C-1/C-2/C-6 forward dependencies) or claimed by nobody (A-1 through A-4).

**Recommended remediation order:**
1. Split Story 1.1 (E-1) into three, and add a fourth Epic 1 story owning `AttachmentStore`, `HeadlessScope`, the typed route layer, the reference fixture and the benchmark CI gate. This clears A-2, A-3, A-4, C-1, C-2 in one move.
2. Move the chart-rendering clauses out of 4.2/4.3 into 4.4, or reorder 4.4 ahead of 4.2 (C-6).
3. Move Story 7.6's partial-upload AC and Story 7.7's OAuth/Backup-&-Sync clauses into Epic 8; introduce the no-op `EntitlementService` in Epic 1 so 7.5's `unknown` path is testable (C-7).
4. Delete the "save to a connected cloud provider" clause from 1.12 and add it to Story 8.2 (C-3).
5. Add attach-document ACs to Stories 1.9 and 3.4 (D-1, D-2), and add medical history plus condition diagnoses to Story 5.3's source list (D-3).
6. Add an explicit `CloudStorageProvider` interface + registry creation AC to Story 8.2 (A-1).
