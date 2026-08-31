# Input Reconciliation — Technical Implementation Plan → PRD

**Source:** `family-health-manager/docs/plan/technical_implementation_plan.md`
**Target:** `_bmad-output/planning-artifacts/prds/prd-bmad-test-2026-08-29/prd.md`
**Date:** 2026-08-29

Scope note: this source is a technical implementation plan. Phases, durations, DB schemas, Flutter/Riverpod/Drift choices, project structure, DAO layers, and the sync-engine internals are correctly out of PRD scope and are **not** flagged. What follows are only product-level requirements, user-facing behaviours, quality/performance expectations, security/privacy rules, and compliance obligations that the plan states and the PRD does not carry.

---

## HIGH — product requirement missing

### G1. Device permission requests and rationale copy are entirely absent from the PRD
- **Source says:** iOS release prep requires "Permission descriptions" (§21, iOS block). Android requires the "Data safety declaration" (§21, Android block).
- **PRD has:** No FR anywhere covers requesting, explaining, or handling denial of device permissions. FR-16 has the user *photograph* a prescription (camera + photo library), FR-13 depends on notification permission (it handles *revocation* but never the initial grant), FR-37 uses biometrics, FR-39/FR-40 write files to device storage. §7 Settings lists no permissions screen.
- **Gap:** The permission-request flow is a user-facing product surface with product decisions attached — when each permission is asked for (up-front vs. just-in-time), what the rationale string says (and in which language, given FR-51/FR-52 bilingual UI), and what the app does when a permission is permanently denied (e.g. camera denied → is file-upload still offered?). None of this exists.
- **Severity: HIGH**

### G2. Expired / revoked OAuth token behaviour has no requirement
- **Source says:** §19 Security Testing lists "Expired OAuth token" and "Token revocation" as required test cases. §13 says "Store tokens securely" for Google Drive, OneDrive and Dropbox.
- **PRD has:** FR-42 stores the OAuth token in secure storage (and NFR-S3 mandates the storage location), but nothing states what the user experiences when the token expires or is revoked from the provider side.
- **Gap:** This is a silent-failure product risk on a paid IAP feature: a user's automatic cloud backup (FR-45) can stop working indefinitely with no visible signal. Needs an FR covering re-authentication prompting, surfacing a disconnected-provider state, and whether a token failure counts as a "backup failed" notification under FR-45.
- **Severity: HIGH**

### G3. Interrupted / partial cloud upload has no defined behaviour
- **Source says:** §18 Backup Tests explicitly require testing "Partial upload" and "Interrupted upload".
- **PRD has:** FR-45 says only "User receives an in-app notification if automatic backup fails." Nothing covers manual backup interruption (FR-42/FR-43), resumption, or the state of the half-uploaded file in the user's own Drive/OneDrive/Dropbox.
- **Gap:** A truncated `.hfm` left in the user's cloud folder is user-visible and could be selected for restore (FR-44 lists available Backup Files with date/size/provider — a partial file would appear in that list looking valid). Needs a requirement that incomplete uploads are never presented as restorable, plus resume-or-discard behaviour.
- **Severity: HIGH**

### G4. Corrupted Backup File and wrong-password restore failure behaviour is unspecified
- **Source says:** §18 Backup Tests require "Corrupted backup" and "Wrong password" cases. §13 includes a `checksum` in both the `.hfm` package structure and the Backup history metadata.
- **PRD has:** FR-41 says "The app verifies backup integrity before restoring" and "Restore requires the backup password" — that is the whole of it. FR-39 lists the `.hfm` contents as encrypted database + attachments + `manifest.json`, with no checksum. No failure-path behaviour is defined.
- **Gap:** Missing: what the user sees on a failed integrity check vs. a wrong password (these must be distinguishable — one is recoverable by retyping, the other is not); that a failed restore must leave existing local data untouched; whether wrong-password attempts are rate-limited the way PIN entry is (FR-36); and the checksum element of the backup package.
- **Severity: HIGH**

### G5. Missing / unreadable attachments during restore
- **Source says:** §18 Backup Tests require a "Missing attachment" case. §9 stores attachment `checksum` in metadata precisely so this can be detected.
- **PRD has:** Nothing. FR-29 and FR-41 both assume documents are present and intact.
- **Gap:** Documents live in the filesystem while metadata lives in the DB (FR-29 consequence), so divergence is expected in real use — a partially restored backup, a file removed by the OS, or a cloud sync that dropped a file. The product needs a defined behaviour: does restore fail wholesale, or complete with a report of N unrecoverable documents? What does the Document Vault show for a record whose file is gone?
- **Severity: HIGH**

### G6. Data preservation across app updates and backup-version compatibility
- **Source says:** §18 Migration Tests (v1→v2, v2→v3, v3→v4) with "Never skip migration testing." §3 states "Never modify production schemas without a migration." §13 Backup metadata carries a `version` field.
- **PRD has:** No NFR or FR asserting that upgrading Jotno preserves existing health data, and no requirement covering restoring an *older* Backup File into a *newer* app version — despite the `version` field existing precisely for that.
- **Gap:** For an app whose entire value proposition is being the only copy of a family's 20-year health record, "an app update must never lose or corrupt user data" and "a backup taken by any prior released version must remain restorable" are product guarantees, not implementation details. Neither is stated. Also missing: what happens when a user tries to restore a backup produced by a *newer* version than the installed app.
- **Severity: HIGH**

### G7. Performance targets at realistic scale are largely uncovered by the NFRs
- **Source says:** §20 Performance Testing mandates testing against 10 family members, 20 years of records, 10,000 measurements, 5,000 documents, and 10,000 medication logs, with the app still able to "Open quickly, Search quickly, Scroll smoothly, Generate reports efficiently."
- **PRD has:** NFR-P2 (3s cold start), NFR-P3 (timeline/calendar scroll at up to **2,000** events), NFR-P4 (Document Vault search < 1s at 10 Members / 5,000 Documents). NFR-P4 and the document count line up; the rest do not.
- **Gap, item by item:**
  - **20 years of records** — no NFR bounds the dataset age or total record volume anywhere.
  - **10,000 measurements** — no NFR. This directly stresses FR-25 trend charts (the 1-year range) and FR-28 lab trend rendering, neither of which has a performance bound.
  - **10,000 medication logs** — no NFR. This directly stresses FR-15 adherence-percentage computation over a selectable date range, and FR-13's catch-up reconciliation on app open (which runs *before* the home screen and so sits inside NFR-P2's 3-second budget).
  - **Scroll smoothly** — NFR-P3 caps at 2,000 events, an order of magnitude below the plan's dataset. Either NFR-P3's number is wrong or the plan's target is not being honoured; the discrepancy is unresolved.
  - **Generate reports efficiently** — no NFR at all for FR-46 PDF health summary generation time, despite it being the flagship export (UJ-3) and the plan calling it out.
  - **Search quickly** — NFR-P4 covers only Document Vault search. The plan's "search quickly" is unqualified, and the PRD has search surfaces beyond the vault (FR-9 doctor directory).
- **Severity: HIGH**

### G8. Privacy policy content requirements are not carried into the PRD
- **Source says:** §21 "Privacy Documentation" specifies that *because this application stores health data*, the privacy policy must clearly explain seven named things: (1) data is stored locally, (2) cloud backup is optional, (3) which cloud providers are supported, (4) what data is uploaded, (5) the encryption approach, (6) whether analytics are collected, (7) whether crash reports contain health information.
- **PRD has:** §6 Privacy says AdMob and Firebase Analytics "are declared in the privacy policy and the Play Store Data Safety form," and OQ-5 records that the Data Safety form "must cover both AdMob device identifiers and Firebase Analytics events, and state that health data is stored on-device only." §7 lists a "Privacy Policy" item under Settings. That is the extent of it.
- **Gap:** The PRD covers roughly points 1 and 6 and only in passing. Points 2, 3, 4, 5 and 7 are unstated. There is also no FR requiring the privacy policy be readable in-app (only an IA menu entry), no requirement that it exist in both Bangla and English despite FR-51/FR-52, and no requirement that it be reachable *before* the AdMob consent decision — FR-2 says "A link to the full privacy policy is present," which implies an external link with no offline/bilingual guarantee.
- **Severity: HIGH**

---

## MEDIUM — detail lost

### G9. Clipboard is not covered by the data-leakage constraint
- **Source says:** §19 requires verifying that sensitive health information isn't accidentally written to: Debug logs, Crash reports, Analytics, **Clipboard**, Notification previews. Five surfaces.
- **PRD has:** NFR-S1 covers debug logs, crash reports and analytics. NFR-S2 covers notification previews. **Clipboard is dropped.**
- **Gap:** Notable because the PRD actively introduces a sensitive clipboard flow of its own — FR-40 offers "copy to clipboard" as a Recovery Phrase destination, i.e. the key material that decrypts the entire family health backup, placed on a system clipboard readable by other apps. The plan's clipboard concern is therefore not merely uncarried but actively contradicted, and FR-40 has no accompanying warning or clipboard-clearing requirement. Screenshot/screen-recording suppression is absent from both documents (noted, not flagged as a source gap).
- **Severity: MEDIUM**

### G10. Appointment reminders have no timezone / clock-change requirement
- **Source says:** §18 Appointment Tests list "Timezone" alongside Reminder, Reschedule, Cancel and Past appointment. §18 Medication Tests separately list "Timezone change" and "Device restart."
- **PRD has:** FR-13 handles timezone change, device clock change and device reboot — but its scope is explicitly the **Medication Engine**. FR-18 (Appointment reminders) covers only rescheduling: "existing reminders are cancelled and new ones scheduled automatically." NFR-P5 asserts reminder reliability for both medication and appointments but says nothing about timezone.
- **Gap:** A family that travels — a realistic case for a Bangladeshi diaspora-adjacent user base — gets correct medication reminders and incorrect appointment reminders. Device-reboot re-registration is likewise stated only for medication notifications; appointment notifications scheduled with the OS are subject to the same platform clearing.
- **Severity: MEDIUM**

### G11. Past-appointment handling contradicts the plan's Missed state
- **Source says:** §7 defines an appointment state `MISSED`, and §18 requires a "Past appointment" test case.
- **PRD has:** FR-17 includes Missed in the status enum but states as a consequence: "Status is user-set; the app does not auto-transition Appointment status."
- **Gap:** This is a defensible product decision, but it leaves the behaviour for an appointment whose date has passed undefined — it stays "Scheduled" forever, continues to appear under "upcoming Appointments" on the Member dashboard (FR-5) and in the Family Health Calendar (FR-34), and appears in the PDF health summary's "upcoming Appointments" section (FR-46). The plan's `MISSED` state exists to resolve exactly this. Either the auto-transition should be specified or the dashboard/calendar/PDF filtering rule for past-dated Scheduled appointments should be.
- **Severity: MEDIUM**

### G12. Calendar drops Lab Tests and Follow-ups as scheduled event types
- **Source says:** §7 Phase 5 — the Health Calendar combines Medication, Appointments, Vaccinations, **Lab Tests**, and **Follow-ups**. The worked example shows a "🧪 Blood Test" as a calendar entry on the 5th.
- **PRD has:** FR-34 covers "Appointment dates, Medication times, Vaccination due dates" only. FR-26 Lab Reports are *retrospective* records with a report date — there is no FR for scheduling a *future* lab test, and no "follow-up" concept exists anywhere in the PRD.
- **Gap:** Two calendar-visible product concepts were dropped. A scheduled-but-not-yet-taken lab test is a distinct user need from a completed Lab Report, and "follow-up" (a return visit tied to a prior Appointment or Medical History entry) has no home in the current model. Either they are in scope and need FRs, or they should be listed in §10.2 Out of Scope.
- **Severity: MEDIUM**

### G13. JSON import / application migration is missing
- **Source says:** §12 export formats — "**JSON** — For application migration." The import flow in the same section (Select File → Validate → Preview → Map Fields → Validate Again → Import → Transaction) is presented generically, not restricted to CSV.
- **PRD has:** FR-48 provides JSON **export** only. FR-49 restricts import to CSV, and only for Measurements, Medications and Medical History. FR-50 covers `.hfm` import.
- **Gap:** The plan's stated purpose for JSON — migrating into the app — has no counterpart requirement. As written, a user can export their full Health Profile as JSON (FR-48) and never import it back. Note also that FR-49's CSV import covers three entity types while FR-47's CSV export covers four (Measurements, Medications, Appointments, Lab Results) — Appointments and Lab Results are exportable but not importable, an asymmetry neither document explains.
- **Severity: MEDIUM**

### G14. Crash reporting is referenced but never decided
- **Source says:** §21 requires the privacy policy to state "Whether crash reports contain health information." §19 requires verifying health data does not reach crash reports.
- **PRD has:** NFR-S1 forbids health data in "crash reports," implying a crash reporter ships. But §6 Constraints states flatly: "AdMob and Firebase Analytics are the only two external data flows in the app."
- **Gap:** Internal contradiction plus an undecided product question. If a crash reporter (Crashlytics or equivalent) is present it is a third external data flow that must appear in §6, in the privacy policy, and in the Play Store Data Safety declaration; if it is absent, NFR-S1's mention of crash reports is vestigial and the plan's §21 disclosure point is moot. The PRD should decide.
- **Severity: MEDIUM**

### G15. FR-13 and NFR-S2 contradict each other on notification dose content
- **Source says:** §6 Phase 4 shows the notification as "💊 Time to take Napa 500mg" — i.e. dose in the notification body. §19 separately requires verifying sensitive health information isn't leaked via notification previews.
- **PRD has:** FR-13 consequence: "Notification content: Member name, Medication name, dose, and time." NFR-S2: "Medication reminder notifications display Member name and Medication name only. **No dosage details** ... appear in notification previews."
- **Gap:** Direct contradiction between an FR and an NFR in the same document. The plan's own example includes the dose, so the source favours FR-13; the plan's §19 privacy concern favours NFR-S2. Downstream (UX, stories) cannot implement both. Needs resolution, possibly as a user setting.
- **Severity: MEDIUM**

### G16. Automatic backup time-of-day setting was dropped
- **Source says:** §14 Phase 12 shows the automatic-backup UI as frequency (Manual / Daily / Weekly) **plus** "Backup time: 02:00 AM." It then adds the mobile constraint that the app must not depend on exact-time background execution and should combine a scheduled background opportunity with an app launch/resume check.
- **PRD has:** FR-45 offers Daily or Weekly only, and states "Automatic backup does not rely on OS background execution; it triggers on app open."
- **Gap:** The PRD kept the constraint and discarded the setting. The plan proposes *both* mechanisms (opportunistic background attempt *and* launch/resume catch-up); the PRD keeps only the second. Losing the time-of-day preference means a user cannot steer a potentially large upload (5,000 documents per §20) toward off-peak hours or a period when they expect to be on Wi-Fi — relevant for the target market's data costs. Related and also absent: no requirement about metered/mobile-data behaviour for cloud backup.
- **Severity: MEDIUM**

### G17. Restore has no "Manual" automatic-backup option and no local backup history view
- **Source says:** §14 lists automatic backup options as "Manual / Daily / Weekly" — Manual being an explicit off state. §13 defines a Backup history record holding provider, file_id, created_at, size, checksum and version, stored as *local* metadata.
- **PRD has:** FR-45 lists "Daily or Weekly" with no stated way to turn automatic backup off. FR-44 shows a restore list with date, size and provider icon — cloud only, and only three of the six metadata fields. Local backups (FR-39) have no listing surface at all.
- **Gap:** No off switch for a feature that uploads on app open is a real omission. And a user who has made local `.hfm` backups (FR-39, a free-tier feature) has no in-app view of them — FR-41 implies a file picker. Backup `version` and `checksum` surfacing ties back to G4 and G6.
- **Severity: MEDIUM**

---

## LOW — nuance

### G18. Document category "Insurance" dropped; "Discharge Summary" renamed
- **Source says:** §9 Document Categories — Prescription, Lab Report, Imaging, **Discharge Summary**, **Insurance**, Vaccination, Other.
- **PRD has:** FR-29 — Prescription / Lab Report / Imaging / **Hospital Record** / Vaccination / Other.
- **Gap:** "Insurance" is gone and "Discharge Summary" was generalised to "Hospital Record." The Insurance drop may be deliberate (§9 Non-Goals excludes "insurance management"), but *filing an insurance document in the vault* is not the same as managing insurance — a user photographing their insurance card has nowhere obvious to put it. Worth confirming the drop was intentional rather than collateral.
- **Severity: LOW**

### G19. Supported document file formats and size limits are unstated
- **Source says:** §9 Document Storage — "Support: JPEG, PNG, PDF." §9 Attachment metadata carries `mime_type` and `file_size`.
- **PRD has:** FR-29 says "photos and PDFs" without naming formats. No file-size cap, no total-storage guidance.
- **Gap:** Minor, but a user-visible validation rule (what happens on an unsupported format, e.g. HEIC — the iOS camera default — or a 200 MB PDF) is undefined, and the §20 target of 5,000 documents has real device-storage implications the PRD never bounds.
- **Severity: LOW**

### G20. Medical History missing from the Health Timeline event list
- **Source says:** §9 Health Timeline events — Medication, Appointment, Measurement, Lab Report, Vaccination, **Medical History**, Document. Seven types.
- **PRD has:** FR-30 lists six — Medications Taken/Missed, Appointments, Measurements, Lab Reports, Vaccinations, Documents. Medical History is absent.
- **Gap:** A surgery or hospitalisation (FR-6) is arguably the most timeline-worthy event a Member has, and it does not appear in the unified feed.
- **Severity: LOW**

### G21. Member search and Timeline search dropped
- **Source says:** §4 Phase 2 Family Member Module lists five operations: Create, Edit, Delete, View, **Search Member**. §9 Phase 7 output includes "Search/filter" for the timeline.
- **PRD has:** FR-4 covers add/edit/delete only. FR-30 offers filtering by Member and event type, but no search. FR-9 does provide Doctor directory search, so search is not absent from the PRD generally.
- **Gap:** Low impact for a typical family, but FR-4's own assumption is "Unlimited Members per Family. [no hard cap]", which makes a member-search affordance more than decorative at the upper end.
- **Severity: LOW**

### G22. `PENDING` dose status is not in the PRD's status set
- **Source says:** §6 MedicationLog statuses — `PENDING`, `TAKEN`, `SKIPPED`, `SNOOZED`, `MISSED`. Five.
- **PRD has:** FR-14 — Taken / Skipped / Snoozed / Missed. Four.
- **Gap:** Probably fine, since a not-yet-due dose can be represented by absence of a log row. But FR-15's adherence formula is "(Taken ÷ Total scheduled doses in period) × 100" — whether today's still-pending doses count in the denominator materially changes the number a user sees, and that is undefined without a PENDING concept.
- **Severity: LOW**

### G23. Medication / prescription linkage into Medical History
- **Source says:** §5 Medical Record Linking shows Medical History linking to Doctor, Hospital, **Prescription**, and Documents.
- **PRD has:** FR-6 links Medical History to Doctor, Hospital and Documents. No Medication/prescription link.
- **Gap:** A hospitalisation record cannot reference the Medications prescribed during it, so the PDF summary (FR-46) and the record view lose that association.
- **Severity: LOW**

### G24. Sync-readiness fields are weaker in the PRD than the plan requires
- **Source says:** §15 — every syncable entity should carry `id`, `device_id`, `version`, `updated_at`, `deleted_at`. The plan's closing paragraph calls designing entity IDs for sync from Day 1 "the most important architectural decision," and §3 mandates UUIDs over auto-increment for the same reason.
- **PRD has:** NFR-S4 mandates soft deletion (`deleted_at`) explicitly for future sync. §9 Non-Goals carries a note: "database schema should support it from Day 1."
- **Gap:** Only the `deleted_at` half of the plan's Day-1 requirement is made binding. `device_id`, `version`, and the UUID-vs-autoincrement decision survive only as a non-binding note to the PM. If the intent is a hard constraint on architecture, an NFR should say so rather than a parenthetical.
- **Severity: LOW**

### G25. Month-end / leap-day recurrence edge case is unhandled in both documents
- **Source says:** §18 Medication Tests list "Multiple doses/day, Start date, End date, Missed dose, Snooze, Timezone change, Device restart." (Note: the plan does **not** list a leap-year case — flagging this as an inherited gap in the source, not a PRD omission.)
- **PRD has:** FR-12 introduces a frequency type the plan never specifies — "**Monthly on a date**" — with no rule for what happens on the 29th–31st in months that lack them.
- **Gap:** The PRD invented a recurrence type richer than the plan's and did not define its boundary behaviour; the plan's test list, being narrower, would not catch it either. Worth an assumption line in §13 (skip vs. clamp to last day of month).
- **Severity: LOW**

---

## Summary

| Severity | Count | IDs |
|---|---|---|
| HIGH | 8 | G1–G8 |
| MEDIUM | 9 | G9–G17 |
| LOW | 8 | G18–G25 |
| **Total** | **25** | |

**Cross-cutting themes:**
1. **Failure paths around backup/restore/cloud are systematically absent** (G2, G3, G4, G5, G6, G17). The PRD specifies happy-path backup thoroughly and unhappy-path behaviour almost not at all — despite the plan devoting a full test section to exactly those cases, and despite backup being the paid IAP.
2. **The plan's §20 performance dataset was not translated into NFRs** (G7). NFR-P3's 2,000-event ceiling is an order of magnitude below the plan's stated target.
3. **Store-submission and compliance obligations were only partially carried** (G1, G8, G14). Permission descriptions and privacy-policy contents are named requirements in §21 with no PRD counterpart.
4. **Two internal PRD contradictions surfaced during reconciliation** (G14 crash reporting vs. §6 "only two external data flows"; G15 FR-13 dose-in-notification vs. NFR-S2 no-dosage). Both should be resolved before architecture.

**Correctly out of scope (verified present in source, deliberately not flagged):** phase durations and MVP timeline tables, Flutter/Dart/Riverpod/GoRouter/Drift/Freezed selections, `lib/` directory layout, coding-standards list, DAO/repository layering, all table and column schemas, UUID mechanics, Drift migration versioning mechanics, `CloudStorageProvider` interface signatures, sync `change_log`/`sync_metadata` internals, conflict-resolution algorithms (post-MVP per §9 Non-Goals), unit/database test enumerations as *test* activities, Android signing/ProGuard/R8, and store-listing marketing assets.

**Already well covered by the PRD (no gap):** app lock PIN/biometric/auto-lock options (§11 → FR-36/37/38, option list matches exactly), database encryption and secure key storage (§11 → FR-35, NFR-S3), transactional all-or-nothing import (§12 → FR-49), medication missed-dose catch-up on resume (§6 → FR-13), device-restart notification re-registration (§18 → FR-13), medication timezone recompute (§18 → FR-13), notification actions Taken/Snooze/Skip (§6 → FR-14), appointment reminder offsets 1 day/3 hours/1 hour/30 min (§7 → FR-18, exact match), measurement type list and glucose measurement types (§8 → FR-22/FR-24, exact match), chart ranges 7d/30d/3m/6m/1y (§8 → FR-25, exact match), emergency card contents and opt-in lock-screen access (§10 → FR-31/FR-33), documents-on-filesystem-not-in-SQLite (§9 → FR-29), `.hfm` package concept (§13 → FR-39), automatic backup not depending on exact-time background execution (§14 → FR-45), and health data excluded from logs/crash reports/analytics (§19 → NFR-S1).
