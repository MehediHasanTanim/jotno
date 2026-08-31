---
title: Adversarial Review — ARCHITECTURE-SPINE.md (Jotno)
target: ../ARCHITECTURE-SPINE.md
context: ../../../prds/prd-bmad-test-2026-08-29/prd.md
lens: adversarial / divergence-pair construction
reviewer: adversarial reviewer
date: 2026-08-30
status: complete
---

# Adversarial Review — Jotno Architecture Spine

## Method

The spine claims to be "a lean spine of invariants that keeps everything built from it
consistent." The test applied here is the only one that matters for that claim: **can two
teams, each obeying every AD to the letter, build one level down and produce work that does
not fit together?**

Each finding below is a *divergence pair*. For each: two real features from the spine's
Structural Seed, exactly what each builds (with the AD compliance argument spelled out), the
concrete incompatibility, and the AD that would have to exist or be tightened to close it.

A finding is only counted if **both halves are fully AD-compliant**. Anything that a
straightforward reading of an existing AD already forbids is not listed as a divergence.

**Verdict up front: 20 divergence pairs. The spine's ADs are individually well-formed and
several are genuinely strong (AD-2, AD-8, AD-10, AD-14, AD-17). But the spine governs the
*vertical* axis — layers within a feature — almost completely, and the *horizontal* axis —
what one feature may assume about another — almost not at all. Every finding below lives on
that horizontal axis.**

---

## Structural defects (not pairs, but they enable several of the pairs)

### S-1 — Two FR numbering systems inside one document

The ADs use PRD numbering correctly (AD-7 binds FR-16/21/25/23 = Medication Engine,
Appointment reminders, Vaccination reminders, Standalone reminders — all correct). The
**Capability → Architecture Map does not.** It is shifted by one from FR-6 onward:

| Spine map says | PRD actually says |
| --- | --- |
| FR-1..FR-6 onboarding, consent, policy, permissions | FR-6 is *Family creation* |
| FR-7..FR-9 family & members | FR-9 is *Medical History records* |
| FR-10..FR-14 history, conditions, allergies, directories | FR-14 is *Medication records* |
| FR-25..FR-26 vaccinations | FR-26 is *Measurement recording* |
| FR-35 timeline | FR-34 is Timeline; FR-35 is *Emergency Contacts* |
| FR-36..FR-39 emergency | FR-39 is *Family Health Calendar* |

The map is contiguous 1..62 with no gaps, which is exactly how the error hides: it looks
complete. A story author reading "FR-25..FR-26 vaccinations → `features/vaccinations`" will
build Measurement recording into the vaccinations feature.

### S-2 — `features/calendar` is ungoverned

The Structural Seed lists `features/calendar`. It appears in **no** Capability Map row, is
bound by **no** AD, and — because of S-1 — its FR (PRD FR-39, Family Health Calendar) was
absorbed into the "emergency" row. The Calendar is the app's *second* cross-feature
aggregator: it unions Appointments, Medication times and Vaccination due dates across all
Members, and NFR-P4 puts a 60fps scroll budget on it alongside the Timeline. The spine gives
the Timeline a map row and an NFR and gives the Calendar nothing. Every Timeline divergence
below (D-4) reproduces in the Calendar with no governance at all.

### S-3 — There is no rule governing feature → feature dependency

The layer table governs one direction only: `presentation → domain`, `data → domain`,
`presentation ✗→ data|core`. It is silent on whether `features/a/presentation` may import
`features/b/presentation`, or `features/a/domain` may import `features/b/domain`. AD-5 covers
exactly one horizontal case (entity access, via the owning repository's interface) and nothing
else — not shared widgets, not shared value objects, not shared enums, not derived-state
predicates. D-5, D-13 and D-14 all fall straight through this hole.

### S-4 — AD-4 mandates soft delete and never mandates the read-side filter

AD-4: "No hard delete from application code — `deleted_at` is set instead." NFR-S4 agrees.
Nowhere does the spine say that reads must filter `deleted_at IS NULL`. That is a write-side
invariant with no read-side counterpart, so it is enforceable in exactly zero of the places
that matter. See D-12.

### S-5 — There is no notification-id model

AD-7 makes `ReminderScheduler` the single writer to the OS queue. AD-4 makes every entity id a
UUIDv7 `TEXT`. OS notification ids are platform integers. **Nothing in the spine says how a
UUID becomes an OS notification id, where that mapping is stored, or who is allowed to cancel
by entity.** D-8, D-9 and D-10 are all consequences of this single omission.

---

## Part 1 — Two owners of one entity

### D-1 — Prescription is written by `features/medications` and `features/appointments`

**AD-5 says "each entity has exactly one repository that owns writes to it." It never says
which.** For an entity that appears on two ER edges, both features can read AD-5, conclude
they are the owner, and both be locally correct.

**`features/medications`** owns FR-19 per the Capability Map ("FR-15..FR-20 medications,
schedules, engine, logs, prescriptions → `features/medications`"). It builds
`PrescriptionRepository` in `medications/domain`, `PrescriptionRepositoryImpl` in
`medications/data`, one `prescriptions` Drift table with AD-4 identity columns, and a
`CreatePrescriptionWithMedications` use case (multi-repository, so a use case is correct per
the paradigm). Its schema: `doctor_id TEXT NULL`, `doctor_free_text TEXT NULL`, `date NOT
NULL`, `notes`, and — because the feature's whole framing is "a prescription yields
medications" (the ER edge `PRESCRIPTION ||--o{ MEDICATION`) — a domain invariant that a
Prescription must resolve at least one Medication before it can be marked complete. AD-5
obeyed, AD-6 obeyed, AD-4 obeyed.

**`features/appointments`** owns FR-22 (post-visit notes and attachments). The user
photographs the slip in the clinic. PRD FR-19 is explicit: *"User can create a Prescription
first (photograph the slip at the clinic) and add its Medications later… Neither order is
forced."* The appointments feature needs to write a Prescription **with zero Medications**,
with `appointment_id` set, and with the Doctor and Hospital inherited from the Appointment
rather than entered. Built in parallel, it declares `AppointmentPrescriptionRepository` in
`appointments/domain`, implements it in `appointments/data` over its own
`prescriptions` table with `appointment_id NOT NULL` and `doctor_id NOT NULL` (it always has
one). AD-5 obeyed — from its own vantage point, exactly one repository owns the entity it
believes it owns.

**Incompatibility.** Two `prescriptions` tables (or one table with two mutually incompatible
NOT NULL sets — merged at integration, one of them must be dropped, and whichever is dropped
silently deletes a required-field guarantee the other feature's use cases depend on). Two
different answers to "may a Prescription exist with no Medications" (medications: no;
appointments: yes, that is the primary flow). Two different answers to "may `doctor_id` be
null" (medications: yes, free text allowed; appointments: no). A Prescription created from the
appointment screen fails the medications feature's domain invariant and cannot be edited
there; a Prescription created from the medications screen has no `appointment_id` and is
invisible to FR-19's requirement that the attachment be "viewable… from the linked
Appointment."

**AD needed.** AD-5 must carry an **explicit entity → owning-feature registry** as a table in
the spine, covering at minimum every entity appearing on more than one edge of the ER diagram
(Prescription, Attachment, Reminder, Doctor, Hospital, EmergencyContact). Plus a rule: *an
entity whose ER diagram shows edges into two features MUST appear in that table; a new entity
may not be introduced without a registry row.* Without the registry, AD-5 is unenforceable
precisely where it is needed.

---

### D-2 — Attachment rows are written by `features/lab_reports` and `features/documents`

AD-12 is a **file-system** invariant: "`AttachmentStore` is the only code that constructs
attachment paths and the only code that deletes files." It says nothing about who owns the
**row**. AD-5 says one repository owns Attachment; the spine never names it. FR-33 attaches to
five record types; the ER diagram makes Attachment polymorphic by `entity_type` +
`entity_id` — i.e. structurally shared by design.

**`features/lab_reports`** implements FR-30/31 and lets the user attach the scanned report.
It calls `AttachmentStore.write(bytes)` (AD-12 obeyed — it does not construct the path
itself), gets back a relative path, and writes an `attachments` row through its own
`LabReportRepository.attach()` inside one transaction with the LabReport (AD-6 obeyed):
`entity_type='lab_report'`, `entity_id`, `path`, `mime`, `size`, `checksum`. It sets no
`title` and no `category` — nothing in the spine tells it those exist, and its own screen has
no field for them.

**`features/documents`** implements FR-33, the Document Vault. Per FR-33 the vault is
*"browsable by category (Prescription / Lab Report / Imaging / Hospital Record / Vaccination /
Other) and filterable by date range, Doctor, Hospital, and keyword"*, and *"document search
covers document titles, notes, and linked entity fields"* under a 1-second NFR-P5 budget. So
`DocumentRepository` writes `attachments` with `category TEXT NOT NULL`, `title TEXT NOT
NULL`, `notes`, plus an FTS index over title+notes. It also uses `AttachmentStore` for paths.
AD-12 obeyed, AD-6 obeyed, AD-5 obeyed as far as it can tell.

**Incompatibility.** Either (a) `title`/`category` are NOT NULL, and every attachment created
from the lab_reports screen — the majority of them — throws a constraint failure at runtime,
discovered only at integration; or (b) they are made nullable to accommodate lab_reports, and
then **every attachment created outside the Documents feature is permanently invisible to
vault browse-by-category and to vault keyword search.** The Vault is the app's promise that
"all attachments are accessible from the Member's Document Vault" (FR-33) and it silently
holds a fraction of them. NFR-P5's 1-second search budget is met — over the wrong corpus.

The same pair replays with `features/medical_records` (FR-9 linked Documents),
`features/vaccinations`, `features/appointments` (FR-22) and `features/medications` (FR-19) —
six writers, six field-set opinions, one table.

**AD needed.** An AD naming `features/documents` as the sole owner of Attachment rows, and
stating that **the only way to attach a file is `DocumentRepository.attach(entityType,
entityId, file, category, title)` — with vault-required metadata as required parameters of
that single call**, so no attaching feature can omit them by construction. This is the same
technique AD-10 already uses successfully for notification content ("Dosage… are not
parameters, so they cannot be passed"). The spine invented the right pattern and applied it in
one place only.

---

### D-3 — One file, two Attachment rows: `features/medications` and `features/appointments`

Distinct from D-2. AD-12 fixes *who constructs paths*; it does not fix the **cardinality**
between a physical file and an Attachment row.

FR-19: *"Attachments land in the Document Vault under the Prescription category and are
viewable from the Prescription, from any linked Medication, and from the linked Appointment."*
One photograph, three surfaces.

**`features/medications`** attaches the slip to the Prescription:
`AttachmentStore.write(bytes)` → one file, one row with `entity_type='prescription'`.

**`features/appointments`** implements FR-22 — the user, on the appointment screen, attaches
"prescription scan, referral letter, lab order." It calls `AttachmentStore.write(bytes)` →
**a second file on disk, a second row** with `entity_type='appointment'`. AD-12 obeyed by
both: neither constructed a path, neither deleted a file.

**Incompatibility.** The same photograph exists twice in the filesystem with two checksums
that happen to match and two rows nothing relates. Consequences that all land at once: the
Document Vault shows the slip twice (FR-33); the .hfm backup carries it twice (AD-14 counts
and checksums it in `manifest.json`, so backup size doubles for the app's most common
attachment); deleting the Appointment soft-deletes one row while the Prescription view still
renders the other; and FR-44's permanent-erasure path, driven by "`AttachmentStore`
reconciling against the DB," reconciles correctly for one row and leaves the other file
orphaned or deletes a file the surviving row still points at — depending purely on whether the
two features happened to dedupe by checksum. One of them will; one of them won't.

**AD needed.** AD-12 must state the cardinality explicitly: **one physical file ↔ one
`attachments` row (deduplicated by checksum inside `AttachmentStore`), with a separate
`attachment_links(attachment_id, entity_type, entity_id)` table carrying the N
relationships.** Erasure then means "delete the file when the last link is gone," which is
what FR-44 actually requires and what the current AD-12 wording cannot express.

---

### D-4 — Reminder rows: `features/appointments` derives them, `features/reminders` stores them

The ER diagram has a single `MEMBER ||--o{ REMINDER` entity. The Capability Map puts
"FR-21..FR-24 appointments, reminders" into **two** features in one row. AD-7 makes
`ReminderScheduler` the single writer to the *OS queue* and says nothing about who owns the
*rows*. Three features produce reminders with three disjoint field shapes:

| Source | Fields (from PRD) |
| --- | --- |
| FR-21 appointment reminders | parent appointment + up to 4 offsets (1d / 3h / 1h / 30m), no title, no repeat |
| FR-23 standalone reminders | title, member, date+time, repeat (none/daily/weekly/monthly), notes, optional linked Appointment |
| FR-25 vaccination reminders | parent vaccination + lead time (0/1/3/7 days), no repeat |

**`features/appointments`** models reminders as **derived**: no rows at all. It stores four
booleans on the Appointment row and, at refill time, the scheduler asks
`AppointmentRepository.pendingReminderOccurrences(from, to)` which computes them from
`appointment.dateTime` minus each enabled offset. This is clean, satisfies FR-21's "when
rescheduled, existing reminders are cancelled and new ones scheduled automatically" for free
(the derivation just changes), obeys AD-5 (it writes only Appointment), AD-6, and AD-15.

**`features/reminders`** models FR-23 as **rows** in a `reminders` table with AD-4 identity
columns — it must, because FR-23 reminders have no parent record to derive from, and because
*"completing or dismissing a reminder is logged so the Timeline reflects what was actually
acted on"* requires a durable row to log against. AD-5 obeyed: it owns Reminder.

**Incompatibility.** The scheduler now has **two registration protocols** and no declared
contract for either. Worse, AD-7's budget computation — "computes how far ahead it can
schedule from actual dose density and the platform budget" — can only see what it is handed.
Derived occurrences are invisible until something asks for them over a date range, and the
range it asks over is the thing it is trying to compute. The scheduler either (a) asks each
source for a bounded window, in which case density is measured over a window rather than
computed, and AD-8's "projected exhaustion" anchor is placed against a number that excludes
every derived reminder beyond the window; or (b) forces appointments to materialize rows,
which contradicts the derivation design and re-opens D-1-style ownership on the `reminders`
table (appointments needs `appointment_id NOT NULL`, reminders needs `title NOT NULL`).

**AD needed.** This is the highest-leverage missing AD in the document. A single **scheduling
contract**: every reminder-producing feature supplies the scheduler with a uniform
`ScheduledOccurrence(entityType, entityId, occurrenceLocalWallClock, ianaTz, priorityClass,
payloadRef)` through one interface declared in `core/notifications/domain`; the scheduler
never queries feature repositories directly; the budget is computed over the union of all
supplied occurrences. This one AD also closes D-7 and D-8 below.

---

## Part 2 — Shared-data shape clashes

### D-5 — Timeline event shape: `features/timeline` pulls, `features/medications` pushes

FR-34 aggregates ten event kinds. NFR-P4 requires 60fps windowed scrolling — "loading windowed
pages rather than the full event set" — over a reference dataset of 10,000 Medication Logs,
10,000 Measurements, 5,000 Documents and 500 Appointments. AD-5 forbids the timeline from
touching another feature's DAO. **Nothing fixes the shape of a timeline event or where it
comes from.** Two designs are both fully legal:

**`features/timeline` + `features/measurements` build the pull model.** Timeline declares
`TimelineEvent` and a `TimelineSource` interface in `timeline/domain`; each feature implements
it via its own repository (AD-5 obeyed exactly — dependency on the interface through
`domain`). `MeasurementRepository.timelineEventsBetween(from, to)` returns events keyed on
`recorded_at`, with a one-line summary carrying value + unit.

**`features/medications` builds the push model.** It reads NFR-P4, correctly concludes that
merging ten independently-paged sources in Dart cannot hold 60fps at reference size, and — in
the same transaction as every dose log, per AD-6 — appends a denormalized row to a
`timeline_events` projection table. AD-6 obeyed (one transaction). AD-5 obeyed, on its
reading: `timeline_events` is a projection of *its own* entity, written by the repository that
owns MedicationLog.

**Incompatibility.** The Timeline renders half its events from a live union query and half
from a projection table, and the two disagree on three axes simultaneously:

1. **Soft-delete visibility.** Deleting a MedicationLog sets `deleted_at` on the log; the
   projection row is a separate row nothing cascades to. Deleted medication events persist on
   the Timeline forever. Measurement events vanish correctly. Same feed, two delete semantics.
2. **Ordering key.** AD-15 stores all timestamps UTC but persists schedules as *local
   wall-clock + IANA tz*. A dose event's natural sort key is its local wall-clock 8:00; a
   Measurement's is a UTC instant. After the user travels, the two interleave wrong, and there
   is no AD saying which key the Timeline sorts on.
3. **Summary shape.** The projection row bakes its one-line summary at write time — in the
   language active *then*. AD-18 requires both languages complete and forbids hardcoded
   strings; a baked Bangla summary rendered after the user switches to English violates AD-18
   without any feature having hardcoded anything.

Deduplication is impossible: the pull-model source and the projection have no shared key.

**AD needed.** An AD that **fixes the Timeline read model**, choosing one and forbidding the
other. Either: *"Timeline and Calendar read exclusively from a `timeline_events` projection;
every entity-owning repository appends to it inside the same transaction as the source write
(AD-6); projection rows carry a localisation key and typed arguments, never rendered text; the
projection's sort key is the event's UTC instant and its display key is local wall-clock."*
Or: *"there is no projection; `core/database` owns a `timeline_view` SQL UNION and the
Timeline pages over it."* The spine picks neither, and both features' choices are defensible.

**Note:** by S-2 this entire finding replays in `features/calendar` with no map row and no
governing AD at all.

---

### D-6 — "Active Medication" means two different things: `features/emergency` vs `features/import_export`

This is the most clinically dangerous finding in the review, and neither half breaks a single
AD.

FR-14 gives a Medication both a `status` (Active / Completed / **Paused**) *and* an optional
`end_date`. Two features must answer "what is this member currently taking":

**`features/emergency`** builds the Emergency Health Card (FR-36: *"current active
Medications (name and dosage)"*). It calls `MedicationRepository.forMember(id)` and filters
`status == Active` — the field is literally named for the question. AD-5 obeyed (it went
through the owning repository's interface), AD-1 obeyed (local DB read), AD-16 obeyed.

**`features/import_export`** builds the PDF health summary (FR-54: *"current Medications with
dosages"*). It calls the same `MedicationRepository.forMember(id)` and filters `end_date ==
null || end_date > now` — a date-range reading of "current" that is equally natural, and is
the reading that matches how the same feature must filter Appointments and Vaccinations for
the rest of the document. AD-5 obeyed identically.

**Incompatibility.** A Paused medication with no end date appears on the PDF and not on the
card. A medication whose `end_date` passed but whose status the user never changed appears on
the card and not on the PDF. **A paramedic reading the Emergency Health Card and a doctor
reading the PDF summary see different drug lists for the same member at the same moment.**
Neither list is marked as partial. Both features passed review.

The same divergence replays across every derived clinical state in the app:

- **"Upcoming Appointment."** `features/members` dashboard (FR-8) filters `date BETWEEN now
  AND now+7d AND status == Scheduled`. `features/import_export` (FR-54, "upcoming
  Appointments," unbounded) filters `date > now` only. FR-20 states the app **never
  auto-transitions Appointment status** — so a Cancelled future appointment prints on the PDF
  the user hands to a doctor, and a Scheduled appointment from 2024 is still "upcoming."
- **"Active Condition."** FR-10 has status Active / Resolved / **Chronic**. FR-10's own
  consequence says *"Active and Chronic Conditions appear on the Member dashboard and
  Emergency Health Card"* — but FR-54 says the PDF carries "active Conditions." A feature that
  filters `status == Active` drops every chronic condition from the doctor-facing PDF.
  Diabetes is Chronic.
- **"Severe Allergy ordering."** FR-36 requires Severe allergies to sort above all others on
  the card; FR-11 requires the high-contrast indicator on dashboard, card, PDF and profile
  header — four features, four independent implementations of one clinical sort.

**AD needed.** An AD stating that **derived clinical states are domain predicates defined once
by the owning repository, never re-implemented by a caller.** `MedicationRepository` exposes
`activeNow(memberId)` and no caller filters `status` or `end_date` itself;
`AppointmentRepository` exposes `upcoming(memberId, window)`; `ConditionRepository` exposes
`currentlyRelevant(memberId)`; `AllergyRepository` returns pre-sorted with severity as a
comparable domain type. Paired with a CI gate in the spirit of AD-11's grep gate: *no `where
status ==` or `where endDate` outside the owning feature's `data/` layer.* Right now the
spine's only cross-feature rule is "go through the interface" — which both halves did.

---

### D-7 — PDF assembly has no contract: `features/import_export` vs nine sources

FR-54's PDF draws from members, medical_records (allergies, conditions), medications,
appointments, vaccinations, measurements, lab_reports and emergency. FR-55 does it for every
Member at once with a family summary page, under NFR-P8 (10s single-member, progress-reported
and non-blocking for the family report). Under AD-5, `features/import_export` must call nine
repository interfaces. **Nothing fixes what those interfaces hand it.** D-6 covers the
predicate divergence; this is the shape divergence beneath it.

**`features/measurements`** exposes `recentForMember(id)` returning domain `Measurement`
entities with `value: double`, `unit: String`, and — per PRD §4.6 FR-28 — the *stored* unit,
since "blood glucose unit conversion is display-layer only; stored value retains original
unit." The feature's own chart converts at render time in `presentation`. AD-5 and the layer
table both obeyed.

**`features/import_export`** consumes that entity and writes it to the PDF. The PDF is
generated "in the app's active language" (FR-54) — so it is a render surface — but
`import_export` has no access to `measurements/presentation` (S-3: no rule permits or forbids
it, and the layer table's only stated prohibition is presentation→data/core). So it prints
`value` and `unit` raw.

**Incompatibility.** The user's screen shows 5.6 mmol/L because their display preference is
mmol/L. The PDF they hand the doctor shows 101 mg/dL — the stored value. Or the reverse. An
18× numeric relationship between the two renderings of the same reading, with no indication on
either that a conversion happened. The same class of defect hits blood pressure (FR-27's
detailed entry vs the PDF's "recent Measurements with trend values" — what is a "trend value"
for a two-component reading?) and every custom Measurement type (PRD §4.6 FR-26: "a name and
single numeric value field with a **user-defined unit string**").

**AD needed.** An AD declaring that **unit conversion and value formatting are a shared
domain-layer concern, not a presentation concern** — one `MeasurementFormatter` in a shared
location, applied identically by charts, dashboards, the emergency card and the PDF — plus the
missing S-3 rule saying where cross-feature render helpers live. The spine already recognised
this shape of problem for numerals (AD-18's "shared formatter") and stopped at numerals.

---

### D-8 — AD-18's shared formatter poisons machine-readable output: `features/import_export` vs `core/backup`

AD-18: *"Numeric display uses Bengali numerals in the Bangla locale via a shared formatter; no
`toString()` on a number reaches the UI."* The scope word is "the UI" — and the spine never
says where the UI ends.

**`features/import_export`** builds CSV export (FR-56). FR-56's own consequence is *"CSV uses
UTF-8 with BOM so Bangla text opens correctly in Excel"* — an explicit instruction that the
CSV is a Bangla-carrying artifact. An AD-18-obedient developer applies the shared formatter to
every number in it, because AD-18 says no `toString()` on a number is acceptable and offers no
exemption. Result: `১২০` in the systolic column.

**`core/backup`** writes `manifest.json` (AD-14: format version, schema version, device id,
**counts**, checksum) and the JSON export (FR-57: *"complete enough to be re-imported by FR-59
without loss"*). It uses ASCII digits, because a checksum in Bengali numerals is not a
checksum.

**Incompatibility.** Three failures compound. (1) The CSV's numeric columns are text in Excel
— FR-56's stated purpose, "data migration and analysis," fails silently. (2) FR-58's CSV
import cannot parse the app's own CSV export, breaking the round trip the PRD builds the
Import & Export section around. (3) Worse, the failure is **locale-dependent**: the CSV
round-trips fine in an English build and fails only in Bangla, which is the *default* locale
(FR-61). The CI check AD-18 mandates ("fails on a key present in one locale and missing in the
other") tests ARB parity and cannot see this.

**AD needed.** AD-18 must state its boundary: **the shared formatter applies to rendered UI and
to the PDF exports only; all machine-readable serialization — CSV, JSON, `manifest.json`, log
fields, notification payloads — uses ASCII digits and ISO-8601 regardless of active locale.**
One sentence, and it is currently absent.

---

## Part 3 — Conflicting state-mutation paths

### D-9 — MedicationLog has three writers, no natural key, and AD-4 guarantees they can't collide-detect

The spine's own flow diagram shows two of the three writers and the PRD adds the third:

1. **`core/notifications`** — the notification action handler. SM-2 measures "dose actioned
   from notification" as the app's headline engagement metric; FR-17 allows Taken/Skipped/
   Snoozed *from the notification*. This runs when the app may be killed.
2. **`features/medications`** — the medications screen, including FR-17's explicit
   *"retroactive logging (marking a past dose Taken or Skipped) is allowed."*
3. **Catch-up reconciliation** — the spine's diagram: `REC["Catch-up reconciliation / overdue
   → Missed"]`, per FR-16: *"doses whose scheduled time has passed with no logged action are
   marked Missed."*

**Do all three agree? No, and two ADs actively prevent them from agreeing.**

**AD-16 excludes writer 1 by construction.** "State mutates only in notifiers. Widgets read
state and call notifier methods." The notification action handler is not a notifier, has no
widget, and runs in a background isolate where the Riverpod container the app builds at
startup does not exist. An AD-16-obedient developer either routes the handler through a
notifier that cannot be constructed headlessly (so the log is written only when the app next
foregrounds — losing the action if the user never opens the app, which is the exact scenario
FR-16 was designed for) or writes directly to the repository and violates AD-16. There is no
compliant third option and the spine does not acknowledge the case.

**AD-4 prevents writers 1 and 3 from detecting each other.** AD-4 mandates "`id TEXT`
(client-generated UUIDv7, never autoincrement)" and the Conventions table repeats it. It
specifies **no natural key** for any entity. So when the handler writes `{id: <uuid-A>,
schedule_id, scheduled_time, status: Taken}` while the app is killed, and reconciliation on
next open recomputes the slot grid and finds — by its own query, which looks for *its own*
notion of an unactioned slot — writes `{id: <uuid-B>, schedule_id, scheduled_time, status:
Missed}`, the two rows have different primary keys by design and **no unique constraint exists
that could catch it.**

**Incompatibility.** FR-18: *"Adherence % = (Taken doses ÷ Total scheduled doses in period) ×
100."* With duplicate rows per slot, the denominator ("total scheduled") is computed either
from the schedule grid (correct) or by counting logs (now inflated) — and different features
will choose differently, because the spine does not say. The user sees adherence above 100%,
or sees a dose they took from the notification reported as Missed in the FR-18 month calendar.
NFR-P7's 2-second budget over 10,000 logs is computed over a corpus that grows with every
reconciliation pass. And the divergence is worst for the most engaged users — exactly the
cohort SM-2 measures.

**AD needed.** Two. (1) **A natural-key AD:** entities with a canonical real-world identity
declare one — `MedicationLog UNIQUE(schedule_id, scheduled_time_utc) WHERE deleted_at IS
NULL` — and all log writes are idempotent upserts, not inserts. AD-4's UUIDv7 rule gives every
entity a *sync* identity and the spine mistook that for *semantic* identity. (2) **A
background-mutation AD:** notification action handlers and background tasks mutate state
through the owning repository via a documented headless container, explicitly exempted from
AD-16, with the exemption named so it does not become a general escape hatch.

---

### D-10 — Import mints new ids, restore preserves them: `features/import_export` vs `core/backup`

Same root cause as D-9 — no natural keys — with a different blast radius.

**`core/backup`** RestoreService (FR-47) unpacks the .hfm and lands rows **with their original
UUIDv7 ids**, because AD-14 restores a database and AD-4 makes ids client-generated and
portable. Correct and necessary.

**`features/import_export`** implements FR-59 JSON import, whose stated modes are *"merge into
the existing Family or replace it."* For merge, it has no identity to merge on — AD-4 gives it
UUIDs, but a merge must decide whether the incoming Measurement *is* an existing Measurement.
With no natural key declared, the only defensible choice is to mint fresh UUIDv7 ids for every
imported row (AD-4 obeyed to the letter: "client-generated UUIDv7"). AD-6 obeyed: single
transaction, all-or-nothing.

**Incompatibility.** FR-57 → FR-59 is advertised as a **round trip** ("completing the round
trip," "without loss"). It is not idempotent: importing a member's own export duplicates every
record. Then the compounding case — the user imports, then restores a .hfm taken *after* the
import: restore preserves the imported rows' new ids, so the duplicates become permanent and
un-mergeable, and the multi-device sync AD-4 exists to enable now has two rows that are
semantically one with no way to reconcile them. AD-4's entire stated purpose — "prevents a
schema migration later blocking multi-device sync" — is defeated not by a migration but by the
absence of the natural keys sync would need.

**AD needed.** The same natural-key AD as D-9, extended: **merge semantics are defined on
natural keys, and every entity that can arrive via import declares one or is explicitly marked
merge-by-new-id.** Also worth stating: FR-59's "replace" mode and FR-47's restore are the same
operation with different packaging and should share one implementation, which no AD says.

---

## Part 4 — Ordering and lifecycle

### D-11 — Member deleted while reminders sit in the OS queue: `features/members` vs `core/notifications`

**`features/members`** implements deletion. FR-7 soft-deletes; FR-44 permanently erases. AD-4
says set `deleted_at`; AD-6 says one transaction; AD-5 says go through each owning repository.
`DeleteMemberUseCase` opens one Drift transaction, calls every owning repository's soft-delete,
commits. It does **not** call `ReminderScheduler` — nothing tells it to. AD-1 says the DB is
the source of truth, which reads as reassurance: change the DB and the rest follows.

**`core/notifications`** refills from the DB on app open/resume, WorkManager, BGAppRefreshTask,
boot and timezone change (AD-8). It will exclude the deleted member — **on its next run.**

**Incompatibility.** Between the commit and the next refill, the OS queue holds up to 63
notifications naming the deleted member. AD-8's own honest premise is that refill is *not*
guaranteed — tier 2 is "iOS `BGAppRefreshTask` best-effort," and Open Question 1 concedes the
real refill rate is unmeasured. And AD-10 makes it unfixable after the fact: notification
content is **built at schedule time** and the member's name is already baked into the OS
queue's payload. No database change can redact it.

So: a user performs FR-44 permanent erasure of a family member — the deceased-relative case is
the obvious one — and their phone continues surfacing that person's name on the lock screen
for days. FR-44 says erasure "removes the database rows, their soft-deleted predecessors, and
the associated Document files." It does not mention the notification queue, and neither does
any AD. This is a privacy and dignity failure that both features passed review to produce.

The same lifecycle hole applies to: Appointment cancelled (FR-20 status is user-set, no
auto-transition, so nothing triggers a reschedule), Medication completed, Vaccination recorded
as administered (its reminder still fires), and Family deleted.

**AD needed.** An AD stating that **any transaction that changes whether a reminder should
exist must invoke `ReminderScheduler.reconcile(entityType, entityId)` as part of that
operation, synchronously, not at next refill** — and that FR-44's erasure path cancels the
entire OS queue before committing. This requires the missing S-5 id-mapping table: the
scheduler cannot cancel by member id today because nothing records which OS integer id
belongs to which entity.

---

### D-12 — Medication paused mid-schedule: `features/medications` vs `core/notifications` reconciliation

FR-14: *"Completed or Paused Medications remain in history and do not generate reminders.
Paused Medications can be resumed; this re-activates their Schedules."*

**`features/medications`** pauses by setting `Medication.status = 'Paused'` — one row, one
repository, AD-4/AD-5/AD-6 all clean. The domain reading is obviously correct.

**`core/notifications`** excludes paused medications at the next refill (AD-8), and separately
runs catch-up reconciliation on app open, marking every unactioned past slot **Missed** (FR-16).

**Incompatibility — three failures in sequence.**

1. Already-queued doses keep firing. The user paused the drug because a doctor told them to
   stop taking it; up to 63 slots deep, the phone keeps telling them to take it. On iOS,
   until the app is next opened.
2. Reconciliation then marks those unactioned slots **Missed** — because it computes the slot
   grid from the Schedule, and pausing set a flag on the *Medication*, not on the Schedule's
   effective interval. Status is a point-in-time flag with no history: **there is no data
   recording that the medication was paused from Tuesday to Friday.**
3. FR-18 adherence therefore reports a fabricated adherence collapse for a drug the user was
   correctly not taking. On resume, nothing removes the Missed rows — FR-14 says resume
   "re-activates their Schedules" and says nothing about the log. The false record is
   permanent, and it is in the record the user shows a doctor via FR-54.

**AD needed.** Pause/complete/cancel must **synchronously cancel affected pending
notifications** (the D-11 AD covers this), and — separately — **reconciliation must be bounded
by each Schedule's effective active intervals, which must be stored as intervals rather than
inferred from a current-value status flag.** That is a modelling invariant, exactly the
altitude the spine operates at, and it is absent. AD-4 mandates `updated_at` but a
current-value column plus an update timestamp cannot reconstruct an interval.

---

### D-13 — Restore swaps the DB while the OS queue references pre-restore rows: `core/backup` vs `core/notifications`

**`core/backup`** RestoreService: AD-14 stages to temp and swaps only on full success; AD-6
makes it whole-or-nothing. It does **not** touch the OS notification queue — and under AD-7 it
is actually *forbidden* to ("the scheduler is the single writer to the OS notification queue;
no feature schedules directly"). Fully compliant.

**`core/notifications`** ReminderScheduler owns the queue and refills from the DB on the next
resume (AD-8). Fully compliant.

**Incompatibility.** Neither is permitted to clear the queue across the swap, so the queue
survives the restore holding notifications whose OS integer ids were derived from pre-restore
rows. Per S-5 the derivation is unspecified, and every plausible choice fails differently:

- **Hash of the entity UUID + occurrence.** After restoring a backup from a *different device*
  (the migration case FR-60 exists for), ids may collide with live queue entries the scheduler
  believes are free; cancelling one cancels another.
- **Counter stored in the DB.** The counter was just replaced by the backup's counter. The
  scheduler reissues ids that are already live in the OS queue, silently overwriting pending
  notifications for unrelated members.
- **Counter in secure storage.** AD-3 explicitly says no code may assume secure storage
  survives.

Then the D-9 handler fires on a stale notification: it writes a MedicationLog against a
`schedule_id` from the payload that either no longer resolves (silent no-op, dose lost) or —
in the id-reuse case — **resolves to a different member's schedule.** A dose logged against the
wrong family member's record, in the app's most safety-critical dataset.

**AD needed.** (1) A `scheduled_notifications` table owned by `core/notifications` mapping OS
integer id → entity type → entity id → occurrence UTC, which is the single source of truth for
what is in the queue. (2) An explicit **ordering invariant**: *restore, JSON import in replace
mode, and delete-all cancel the entire OS queue and truncate the mapping table before the swap,
and trigger a full scheduler refill immediately after.* AD-14's "swap only on full success" is
about the DB file and stops there; the queue is the second piece of mutable device state the
restore touches, and the spine treats it as if it were not there.

---

## Part 5 — The 64-slot budget

### D-14 — Chronological fill silently and permanently drops sparse reminders: `features/medications` vs `features/appointments`

AD-7 is one of the better ADs in the document and it is specified precisely enough to be
provably wrong. It says the scheduler "reserves **one slot** for the coverage anchor (AD-8) and
**fills the rest chronologically**." **The task asked who arbitrates when the budget is
exhausted. The spine does answer: chronology. That answer is the bug.**

**`features/medications`** registers its Schedules. Open Question 2 estimates ~12 doses/day
typical, ~30/day heavy. At 30/day, chronological fill consumes all 63 usable iOS slots in
**roughly two days**.

**`features/appointments`** registers FR-21 reminders for an appointment three weeks out — say
the 1-day-before reminder. Chronological fill never reaches it: every slot ahead of it is a
dose. Fully compliant on both sides; neither feature schedules directly (AD-7), neither
oversteps.

**Incompatibility — and the part that makes this severe.** A dropped *dose* reminder is
recoverable: doses recur, refill runs, the next one fires, and AD-8's anchor exists precisely
to tell the user that coverage is at risk. A dropped **appointment** reminder is not. It is a
single, date-fixed, non-recurring event. The user opens the app on the morning of the
appointment, refill runs, and the 1-day-before slot is already in the past. The reminder is
**permanently lost, not deferred**, and nothing ever tells the user — AD-8's anchor message is
"the app must be opened to keep reminders coming," which is a medication-coverage message and
is *already true and already dismissed* in this scenario. The user misses a specialist
appointment booked six weeks ahead. Vaccination reminders (FR-25, 0/1/3/7-day lead) fail
identically, and a missed childhood immunisation window is worse.

NFR-P2 states flatly that appointment and vaccination reminders "are delivered by the OS at
their scheduled time… subject only to OS-level restrictions outside the app's control." Budget
exhaustion is inside the app's control. Chronological fill violates NFR-P2 while obeying AD-7.

**AD needed.** AD-7 must partition the budget by **priority class, not chronology**:
non-recurring date-fixed reminders (appointments, vaccinations, standalone one-shots) are
allocated slots *first*, up to a reserved ceiling, and recurring doses fill chronologically
from what remains. Plus the missing honesty rule that AD-8 applies so well to coverage and not
at all here: **if a reminder cannot be scheduled, the user is told at creation time, on that
screen, not silently.** Right now AD-7 guarantees a single writer and guarantees nothing about
what that writer drops.

---

### D-15 — Two slot-accounting models break the anchor math: `features/reminders` vs `features/medications`

**`features/reminders`** implements FR-23 standalone reminders with `repeat = daily`. The
obvious implementation is a **single OS repeating notification** — one slot, fires forever,
survives without refill, no budget pressure. AD-7 obeyed (registered via the scheduler), AD-15
obeyed (local wall-clock + tz), AD-10 obeyed.

**`features/medications`** cannot do this. Each dose needs a distinct payload so the D-9 action
handler can log against the right occurrence, and FR-17's snooze reschedules a *specific* dose
by 15 minutes. So doses are **N one-shot slots**, N ≈ doses/day × horizon.

**Incompatibility.** AD-8 places the coverage anchor at "projected exhaustion minus 24h," and
AD-7 computes the horizon "from actual dose density and the platform budget." Both formulas
assume every occupied slot expires. A repeating slot never expires, so it permanently reduces
the budget while contributing nothing to the projected-exhaustion calculation. With a handful
of daily standalone reminders across a family, the scheduler computes a coverage projection
over a budget it does not actually have: the anchor is placed later than it should be, the
queue exhausts before the anchor fires, and **AD-8's entire honesty mechanism — the one thing
standing between the user and silent reminder loss — fails silently.** Which is precisely the
failure AD-8 exists to prevent.

Worse, the two models cannot be compared: the scheduler has no way to know whether a
registered occurrence consumes one slot forever or one slot until it fires, because the
registration protocol is undefined (D-4).

**AD needed.** The D-4 scheduling contract, with slot semantics made explicit: **every reminder
occupies exactly one non-repeating slot; OS repeating notifications are not used**, because a
uniform accounting model is worth more than the slots a repeat would save. Then AD-7's density
computation and AD-8's projection are both well-defined. If repeats *are* allowed, AD-8's
projection formula must subtract them from the budget as a fixed cost, and the spine must say
so.

---

## Part 6 — Cross-cutting reads

### D-16 — Doctor promoted to Emergency Contact: copy or reference? `features/medical_records` vs `features/emergency`

FR-35: *"Doctors already in the Doctor directory (FR-12) and Hospitals in the Hospital
directory (FR-13) can be promoted to Emergency Contacts without re-entering their details."*

**`features/medical_records`** owns Doctor and Hospital (both are Family-shared per FR-12/13).
**`features/emergency`** owns EmergencyContact. AD-5 says each writes only its own entity —
and both do. "Promote" has two implementations and the spine endorses neither:

- **Copy** the fields into a new `emergency_contacts` row. AD-5 obeyed perfectly: emergency
  writes only its own table. **Consequence:** the user updates their cardiologist's phone
  number in the Doctor directory. The Emergency Health Card — and the FR-38 rapid-access
  surface reachable from a locked phone — still dials the old number. In an emergency. There
  is no indication anywhere that the card's copy is stale.
- **Reference** via `source_doctor_id`. Also AD-5 obeyed. **Consequence:** deleting the Doctor
  sets `deleted_at` per AD-4, and by **S-4 there is no rule that readers filter it**. The
  emergency card resolves a soft-deleted Doctor and renders it as a live contact — or renders
  a blank row, depending on whether that particular reader remembered to filter.

**Incompatibility.** Both choices are compliant and they are not interchangeable: one
guarantees staleness, the other guarantees dangling references. And the decision is made
independently again for Hospital, again for Appointment→Doctor, again for Medication
"prescribed by," again for Medical History→Doctor/Hospital — five relationships, five
opportunities to choose differently within one codebase.

**AD needed.** Two. (1) **The missing read-side counterpart to AD-4:** *every query filters
`deleted_at IS NULL` unless it is an explicit history or erasure path; enforced by a generated
Drift view per entity that the DAO layer must query, so the filter cannot be forgotten.* (2)
**A copy-vs-reference rule**, decided per relationship in the spine rather than per feature —
with the general form stated: *denormalized copies of another feature's entity are forbidden;
where a snapshot is genuinely required (PDF, backup manifest), it is marked as a snapshot with
its capture timestamp.*

---

### D-17 — Emergency card assembly drifts across five sources: `features/emergency` vs `features/members`

FR-36's card is assembled from five features: name/age/blood group (`members`), Allergies and
Conditions (`medical_records`), active Medications (`medications`), Emergency Contacts
(`emergency`). D-6 covers the predicate divergence; this is the **derivation** divergence.

**`features/members`** owns Member and, per FR-7, *"date of birth (age auto-calculated and
displayed)."* Age is computed in `members/presentation` at render time, correctly handling the
birthday-this-year case.

**`features/emergency`** must print age on the card (FR-36) but cannot import
`members/presentation` (S-3 leaves this undefined, and the layer table's spirit discourages
it). So it recomputes age from `member.dateOfBirth`. `features/import_export` recomputes it a
third time for the PDF (FR-54: "name, age, blood group"). Three implementations of one
calculation.

**Incompatibility.** For an infant — the demographic FR-24's multi-dose immunisation tracking
is built around — "age" is 4 months, not 0 years, and the three implementations will not agree
on that. For a card read by a stranger under stress, "0" and "4 months" are materially
different pieces of clinical information. Blood group has the same shape: FR-7 makes it an
optional Member field, and three features independently decide what to render when it is
absent — blank, "—", or "Not recorded". On an emergency card, **blank reads as a claim**, which
FR-36 itself recognises for allergies (*"an empty section reads as 'none' to a stranger, which
is a different and dangerous claim"*) and does not generalise.

**AD needed.** The S-3 rule, specialised: **derived display values on a shared entity (age from
DOB, "no known allergies", absent-value rendering on safety surfaces) are computed once in the
owning feature's `domain` layer and exposed on the entity, never recomputed by a consumer.**
FR-36's own insight about empty sections should be an AD, not a consequence buried in one FR.

---

### D-18 — FR-38 rapid access is required to carry data AD-10 makes structurally impossible

The spine defers the FR-38 mechanism ("iOS rapid-emergency mechanism — widget vs. Live Activity
vs. Shortcut… Open question, not an architecture invariant") while keeping AD-10 absolute.
**The deferral hides a contradiction rather than postponing a choice.**

**`features/emergency`** implements FR-38. The PRD explicitly lists the acceptable mechanisms:
*"a lock-screen widget, home-screen widget, **persistent notification**, Siri/Assistant
shortcut, or platform equivalent are all acceptable."* On Android, a persistent notification is
the most reliable of these and the likeliest choice. Whatever mechanism is chosen must expose
**Emergency Health Card data** (FR-36): allergies, active conditions, current medications with
dosages.

**`core/notifications`** owns AD-10: *"All notification content is produced by
`NotificationContentBuilder`. It accepts member name, item name and time — nothing else.
Dosage, condition, lab values and document names are not parameters, so they cannot be passed.
A test asserts the builder's public surface."*

**Incompatibility.** If FR-38 ships as a persistent notification, `features/emergency` must put
allergies, conditions and dosages into a notification — and AD-10's builder **cannot accept
them by construction**, with a test enforcing it. The feature is simultaneously required by the
PRD and impossible under the spine. The developer's only compliant move is to bypass
`NotificationContentBuilder` entirely, which is not compliant, or to abandon the most reliable
Android mechanism without the spine ever saying so.

The privacy reasoning also differs and the spine never separates the two cases: AD-10's
rationale is that lock-screen previews are visible to bystanders. FR-38's rationale is that a
bystander **should** see this data — that is the entire point of an emergency card, it is
default-OFF, and it requires explicit per-member activation.

**AD needed.** AD-10 must carry a **named, narrow exception**: an emergency channel with its own
builder, its own asserted surface, gated on the per-member FR-38 opt-in, justified by the
inverted threat model. Or the deferred FR-38 decision must be **constrained in the spine** to
non-notification mechanisms. Either is fine; leaving AD-10 absolute *and* deferring FR-38
guarantees the conflict is discovered by whoever implements FR-38, at which point they will
quietly weaken AD-10 — the app's best privacy invariant — under schedule pressure.

---

## Part 7 — Entitlement and optional subsystems

### D-19 — Entitlement fails closed and locks the user out of their own backup: `features/backup_sync` vs `core/backup`

**`features/backup_sync`** implements FR-52 cloud restore. AD-19: *"Cloud backup features ask
`EntitlementService`; they never read purchase state directly."* So it gates the cloud restore
list on `hasPrivateBackup`. Correct and exactly as instructed.

**`core/entitlement`** implements `EntitlementService`. AD-20: IAP is an optional subsystem
"behind an interface with a no-op implementation," and "**no core path awaits a network
call**." A no-op or not-yet-restored entitlement returns `false` — the safe default for a
gate.

**Incompatibility.** The scenario is the one cloud backup exists for: the user's phone is lost.
They install Jotno on a new phone. Restoring an IAP purchase is a store network call, which
AD-20 forbids core paths from awaiting and which the no-op cannot make. `hasPrivateBackup`
returns `false`. **The user is refused access to their own encrypted backup, sitting in their
own Google Drive, in a folder they own, encrypted with a password they know.** Both features
obeyed their AD precisely.

This directly contradicts the PRD's stated monetization principle: *"Local backup, restore, and
full data export remain free, so **no user is locked out of their own data** — the paid tier
buys convenience and off-device durability, not access."* The architecture inverts that
sentence on the single path where it matters most.

**AD needed.** AD-19 must distinguish **direction of gating**: entitlement gates *new cloud
writes* (upload, auto-backup configuration) and **never gates read or restore access to data
the user already owns**. Stated as an invariant: *no entitlement check may stand between a user
and the recovery of their own health records; restore paths fail open.* This is a one-line
addition to an AD that is otherwise well-scoped, and its absence produces the worst possible
support case for a health app.

---

### D-20 — Ads no-show list is keyed on screens; two features render outside the screen model

**`core/entitlement`** / the ads module owns AD-19's constant: *"The list of screens that must
never show an ad — emergency card, medication reminder, active data entry — is a constant owned
by the ads module, not a per-screen decision."* Sound reasoning, and the constant is keyed on
**screens**.

**`features/import_export`** renders the FR-54 PDF **preview** ("User can preview the PDF
before sharing"), and PRD §8 explicitly places ads on "post-export confirmation." So the
preview and the confirmation are adjacent surfaces with opposite rules, distinguished only by
which route name the ads module's constant happens to list. The preview of a health summary
containing allergies and medications is unambiguously "active data entry"-adjacent in spirit
and is not on the list.

**`features/emergency`** renders the FR-38 rapid-access surface **outside the app's route
graph** — a widget, or a notification (D-18). The ads module's screen-keyed constant cannot see
it. Today that is harmless because no ads render there; it becomes harmful the moment a future
feature reuses the emergency card widget composition inside the app and the constant does not
match the new route name.

**Incompatibility.** A deny-list keyed on route names fails open by construction: a screen that
is not on the list shows ads. Every new screen — and this app has dozens — is ad-eligible by
default until someone remembers to add it. For a health app whose §8 promises ads only in
"lower-traffic screens (Reports, Settings, post-export confirmation)," the default is
backwards.

**AD needed.** Invert it: **ads render only on an explicit allow-list of surfaces, and any
surface not on the list shows none.** Same constant, same owner, opposite default — and it
turns the failure mode from "new health screen accidentally shows an ad" into "new revenue
surface accidentally shows none." AD-19 already got the ownership right and the polarity
wrong.

---

## Summary table

| # | Pair | Divergence | AD to add / tighten |
| --- | --- | --- | --- |
| D-1 | medications ↔ appointments | Prescription: two owners, incompatible NOT NULL sets | AD-5 + entity→owner registry |
| D-2 | lab_reports ↔ documents | Attachment rows without vault metadata are unsearchable | New AD: Documents owns Attachment; required params |
| D-3 | medications ↔ appointments | Same file attached twice, two rows, orphan on erase | AD-12 + cardinality & link table |
| D-4 | appointments ↔ reminders | Reminder derived vs stored; scheduler has no contract | New AD: uniform `ScheduledOccurrence` contract |
| D-5 | timeline ↔ medications | Pull vs push projection; delete/order/i18n all diverge | New AD: fix the Timeline/Calendar read model |
| D-6 | emergency ↔ import_export | "Active Medication" differs — card and PDF disagree | New AD: derived clinical states are domain predicates |
| D-7 | import_export ↔ measurements | Unit conversion display-only; PDF prints raw values | New AD: shared value formatter in domain |
| D-8 | import_export ↔ core/backup | Bengali numerals in CSV break FR-58 re-import | AD-18 + serialization boundary |
| D-9 | core/notifications ↔ medications | 3 log writers, no natural key, duplicate Missed rows | New AD: natural keys + background-mutation exemption |
| D-10 | import_export ↔ core/backup | Import mints ids, restore preserves; round trip not idempotent | Same natural-key AD, extended to merge |
| D-11 | members ↔ core/notifications | Deleted member's name persists on lock screen | New AD: reconcile scheduler in the same operation |
| D-12 | medications ↔ core/notifications | Pause fires queued doses, then fabricates Missed | New AD: schedules carry effective intervals |
| D-13 | core/backup ↔ core/notifications | DB swap vs OS notification ids; cross-member log writes | New AD: id-mapping table + queue ordering invariant |
| D-14 | medications ↔ appointments | Chronological fill permanently drops appointment reminders | AD-7 + priority classes + tell-the-user rule |
| D-15 | reminders ↔ medications | Repeating vs one-shot slots break AD-8 anchor math | AD-7/AD-8 + uniform slot semantics |
| D-16 | medical_records ↔ emergency | Promote-to-contact: stale copy or dangling reference | AD-4 read-side filter + copy-vs-reference rule |
| D-17 | emergency ↔ members | Age/blood-group derived three ways; blank reads as a claim | New AD: derived display values live in owning domain |
| D-18 | emergency ↔ core/notifications | FR-38 needs data AD-10 cannot pass | AD-10 + named emergency-channel exception |
| D-19 | backup_sync ↔ core/entitlement | Entitlement fails closed; user locked out of own backup | AD-19 + restore paths fail open |
| D-20 | import_export ↔ ads module | Screen-keyed deny-list fails open on every new screen | AD-19 + invert to allow-list |

---

## Assessment

**20 divergence pairs.** Every one is a case where two features obey every AD and still cannot
be integrated.

The pattern is consistent and diagnosable. The spine governs the **vertical** axis thoroughly:
layers, dependency direction, transaction boundaries, migration discipline, crypto, logging.
Several ADs are genuinely excellent — AD-2's fail-closed cipher assertion, AD-8's coverage
anchor, AD-10's build-a-parameter-list-that-cannot-express-the-leak technique, AD-14's
verify-before-decrypt, AD-17's generated migrations. These are load-bearing and correct.

It barely governs the **horizontal** axis: what one feature may assume about another. AD-5 is
the only horizontal invariant and it covers exactly one case — entity access through a
repository interface — while leaving unspecified *which* feature owns a shared entity (D-1,
D-2, D-4, D-16), what the interface returns (D-5, D-6, D-7, D-17), whether a feature may
import another's non-domain code at all (S-3), and how the read side honours the write side's
soft-delete rule (S-4).

Three additions would close most of the twenty:

1. **An entity → owning-feature registry** attached to AD-5, mandatory for any entity on more
   than one ER edge. Closes D-1, D-2, D-3, D-4, D-16.
2. **A derived-state AD**: clinical predicates and derived display values are defined once by
   the owning repository and never re-implemented by a caller, with a CI grep gate in the style
   AD-11 already uses. Closes D-6, D-7, D-17, and half of D-5.
3. **A scheduler contract AD**: one uniform `ScheduledOccurrence` registration, one
   `scheduled_notifications` id-mapping table, priority-class budget partitioning, and an
   ordering invariant binding every lifecycle event (delete, pause, cancel, restore, import)
   to a synchronous scheduler reconcile. Closes D-11, D-12, D-13, D-14, D-15 — the entire
   reminder subsystem, which is the app's headline feature (UJ-1, SM-2, NFR-P2).

Plus two one-line fixes with outsized value: **AD-19 restore paths fail open** (D-19 — a user
locked out of their own health records is the worst outcome in the document) and **AD-4 needs
its read-side counterpart** (S-4/D-16).

And two document defects to fix before anyone builds from this: the **Capability Map's FR
numbering is shifted by one** from FR-6 onward while the ADs use correct numbering (S-1), and
**`features/calendar` — the second cross-feature aggregator, carrying an NFR-P4 budget — is
bound to no FR and no AD** (S-2).
