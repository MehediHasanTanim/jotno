# Input Reconciliation — Feature Spec → PRD

**Source:** `family-health-manager/docs/features/feature_details.md`
**Target:** `_bmad-output/planning-artifacts/prds/prd-bmad-test-2026-08-29/prd.md`
**Date:** 2026-08-29

Scope note: technical implementation detail in the source (§47 table names, §48 relationships, §52 Flutter folder structure, §2/§42/§51 architecture diagrams) is deliberately excluded from the PRD and is **not** flagged below.

---

## HIGH — Product requirement missing or materially contradicted

### H-1. Prescription is not a first-class entity (source §12)

- **Source (§12 Prescription Management):** Prescriptions are their own record type. Users can *take photo*, *upload PDF*, **add a prescription manually**, **link a prescription to medications** (plural), and **link a prescription to an appointment**. The worked example is a prescription record headed by a Doctor + date, containing a list of medicines (Napa, Medicine B, Medicine C).
- **PRD:** FR-16 flattens this into "attach a prescription to a Medication" — a single file attachment hanging off one Medication record, with `[ASSUMPTION: one prescription attachment per Medication record in MVP]`.
- **Gap:**
  - No manual/structured prescription entry (doctor, date, medicine list) — only file upload.
  - No prescription→Appointment link (FR-19 lets you attach a *Document* to an Appointment, which is not the same as linking the prescription entity).
  - The source's natural cardinality is one prescription → many medications; the PRD's is one medication → one prescription file. A real prescription listing three drugs cannot be modelled without duplicating the same image against three Medication records.
- **Severity:** HIGH

### H-2. Emergency Contacts feature has no FR (source §32)

- **Source (§32 Emergency Contacts):** A dedicated store of multiple contacts per family: *family emergency contact, doctor, hospital, ambulance, insurance contact*, with **quick actions: Call / SMS / Copy**.
- **PRD:** FR-4 gives a Member a single `emergency contact name and phone` field. FR-31 renders "primary emergency contact" and "primary Doctor" on the Emergency Health Card. There is no FR for a contact list, no ambulance or insurance contact, and — most significantly — **no tap-to-call, tap-to-SMS, or copy action anywhere in the PRD**.
- **Impact:** UJ-4 (Karim in the ER) reads the card aloud; the source's design intends him to be able to *dial* from it. The quick-action affordance is the whole point of an emergency screen.
- **Not listed** in §9 Non-Goals or §10.2 Out of Scope — this is a silent drop, not a deliberate cut.
- **Severity:** HIGH

### H-3. Three reminder types dropped (source §36)

- **Source (§36 Reminders)** enumerates eight reminder types: Medication, Appointment, Vaccination, **Lab test**, **Health measurement**, **Follow-up**, Insurance expiry, Prescription refill.
- **PRD:** Covers Medication (FR-13), Appointment (FR-18), Vaccination (FR-21). Insurance expiry and Prescription refill are explicitly out of scope in §9/§10.2 — correctly and deliberately.
- **Gap:** **Lab test reminders**, **health measurement reminders**, and **follow-up reminders** appear nowhere — neither as FRs nor in the out-of-scope list. Follow-up in particular is reinforced by the source's own §17 example ("Follow-up after 1 month") and by the Non-Users framing of the app as an adherence tool.
- **Caveat:** the source's own §54 MVP list names only "Medication reminders" and "Appointment reminders", so an argument exists that these three are post-MVP. But the source never says so, and the PRD's §10.2 does not list them — so the disposition is simply missing. At minimum they belong in §10.2 Out of Scope.
- **Severity:** HIGH (three product requirements absent with no disposition)

### H-4. JSON import missing; Appointments CSV import missing (source §39)

- **Source (§39 Data Import):** Support for (a) application backup `.hfm`, (b) **CSV for measurements, medications, appointments, and medical history**, (c) **JSON for structured migration**.
- **PRD:** FR-49 CSV import covers Measurements, Medications, Medical History — **Appointments is dropped**. FR-50 covers `.hfm`. **There is no JSON import FR at all** — the PRD has JSON *export* (FR-48) with no counterpart import, breaking the round-trip the source calls out as the migration path.
- **Severity:** HIGH (JSON import is a named source requirement with no FR and no out-of-scope entry)

### H-5. Family-wide export ("Family Health Report") dropped (source §40)

- **Source (§40 Data Export):** "Users can export: **Individual member** (e.g. Father → Export Health Record) — **Entire family (Family Health Report)**", in PDF / CSV / JSON / encrypted backup.
- **PRD:** FR-46 (PDF), FR-47 (CSV), FR-48 (JSON) are each scoped explicitly to "one Member". No family-level report exists in any form except the `.hfm` backup, which is not a human-readable report.
- **Severity:** HIGH

---

## MEDIUM — Detail lost, enum narrowed, or unexplained contradiction

### M-1. Cloud backup moved from free MVP-essential to paid IAP (source §54 vs PRD §8)

- **Source (§54 MVP — Essential):** lists `✓ Encrypted backup`, `✓ Google Drive backup`, `✓ OneDrive backup`, `✓ Dropbox backup` as core, unqualified MVP features. §55 defers only *automatic* cloud backup and backup versioning to Phase 2.
- **PRD:** §8 Monetization and FR-42/43/44/45 gate all cloud backup, cloud restore, and automatic backup behind a paid "Private Backup" IAP. Free tier gets local `.hfm` backup only.
- **Assessment:** Almost certainly a deliberate decision inherited from the product brief, not an oversight — but it directly inverts the source's MVP classification and nothing in the PRD acknowledges the divergence. Worth an explicit note so downstream readers don't treat the source as still authoritative here.
- **Inverse note:** the PRD *promotes* several source-Phase-2 items into MVP — automatic cloud backup (§55 → FR-45), backup versioning (§55 → FR-45 retention), blood glucose tracking (§55 → FR-24), detailed BP tracking (§55 → FR-23), doctor visit summary (§55 → FR-46). These are scope expansions, not gaps, but they enlarge MVP relative to the source's own recommendation.
- **Severity:** MEDIUM

### M-2. AdMob + Firebase Analytics contradict the source's privacy absolutism (source §2, §50)

- **Source (§2 Privacy Model):** the architecture is `User → Flutter App → Encrypted Local DB`. "There is no: `User → Your Backend → Database`." The only outbound flow contemplated anywhere in the document is encrypted backup to a user-owned cloud provider. §50 reinforces: no email, password, OTP, or registration "unless the user voluntarily connects a cloud provider."
- **PRD:** FR-2 introduces an AdMob consent screen and §6 introduces Firebase Analytics. §6 states these are "the only two external data flows in the app" — meaning the shipped app makes network calls carrying device identifiers on every launch, which the source never contemplates.
- **Assessment:** The PRD handles this carefully (consent gate, event allowlist, no health data in payloads, counter-metric SM-C1). But it is a genuine contradiction of the source's stated model, and it sits in tension with §56's "clear differentiation from cloud-based health platforms" positioning. Flagged so it is a conscious, recorded trade-off rather than an unnoticed drift.
- **Severity:** MEDIUM

### M-3. "Secure deletion" dropped from the MVP security set (source §49)

- **Source (§49 Security → MVP):** Encrypted local database, secure key storage, encrypted cloud backups, PIN, Biometrics, Automatic app lock, **Secure deletion**.
- **PRD:** FR-35 (encrypted DB), FR-36 (PIN), FR-37 (biometric), FR-38 (auto-lock), NFR-S3 (key storage), FR-39 (encrypted backup) cover six of seven. **Secure deletion has no FR.**
- **Contradiction:** NFR-S4 does the opposite — it makes *soft* deletion the default for everything and requires "a separate explicit user confirmation" for hard deletion, which is never specified as a flow. There is no requirement to securely erase a record, a Member's data, or all app data (e.g. before selling a device), and no requirement that deleted attachment files are removed from the filesystem.
- **Severity:** MEDIUM

### M-4. Document category "Insurance" removed (source §28)

- **Source (§28 Document Categories):** Prescriptions, Lab Reports, Imaging, Hospital Records, **Insurance**, Vaccination, Other. §27 explicitly lists "Insurance documents" among what the vault must store.
- **PRD:** FR-29 categories are Prescription / Lab Report / Imaging / Hospital Record / Vaccination / Other — Insurance is dropped.
- **Assessment:** The PRD correctly excludes *insurance management* (§9 Non-Goals) — but storing a policy PDF in the document vault is a different, much cheaper thing, and the source lists it under Documents, not under §33 Insurance. Users will store insurance cards regardless; they now land in "Other."
- **Severity:** MEDIUM

### M-5. Two measurement types dropped from the MVP list (source §20)

- **Source (§20 Health Measurements):** Vital Signs = Blood pressure, Heart rate, Temperature, SpO₂, **Respiratory rate**. Body Measurements = Weight, Height, BMI, **Waist circumference**.
- **PRD:** FR-22 MVP types = Blood Pressure, Blood Glucose, Weight, Height, Body Temperature, Heart Rate, SpO₂. Respiratory rate and waist circumference are absent. BMI is preserved as a derived value.
- **Mitigation:** FR-22 allows user-defined custom measurement types, so these are reachable — but as unnamed custom entries with a user-typed unit, not as first-class typed measurements with proper units and charts.
- **Severity:** MEDIUM

### M-6. Document Vault is per-Member; source describes family-wide search (source §29)

- **Source (§29 Document Search):** search terms span entity types ("CBC", "Dr. Ahmed", "2026", "Dengue", "Prescription") and the **filter list begins with `Member`** — implying one searchable corpus across the whole family, narrowed by member.
- **PRD:** FR-29 defines the vault as "the Member's Document Vault", browsable by category and filterable by date range, Doctor, Hospital, and keyword. There is **no Member filter and no cross-Member document search**. NFR-P4 ("10 Members and 5,000 Documents" in under 1 second) implies a family-wide index, contradicting FR-29's per-Member framing.
- **Severity:** MEDIUM

### M-7. Medical History loses the distinct "Treatment" field (source §6)

- **Source (§6):** each record contains Condition, Diagnosis date, Doctor, Hospital/clinic, **Treatment**, Notes, Status, Related documents.
- **PRD:** FR-6 fields are event type, title, date, Doctor, Hospital, **description**, status, notes, linked Documents. "Treatment" — what was actually done about the event — is collapsed into a generic description field alongside notes. The source's own example table is `Year | Event | Status` with values like "Treatment completed", showing treatment is the substance of the record.
- **Severity:** MEDIUM

### M-8. Condition status enum narrowed and now inconsistent (source §6, §7)

- **Source:** §6 defines the status vocabulary as **Active / Resolved / Chronic / Under Treatment / Unknown** and §7 gives Conditions a "Status" field without redefining it — i.e. one shared status vocabulary.
- **PRD:** FR-6 (Medical History) keeps all five. FR-7 (Conditions) narrows to **Active / Resolved / Chronic** — dropping "Under Treatment" and "Unknown". A condition currently being treated (the common case — the source's §7 examples are diabetes, hypertension, asthma) has no accurate status, and imported/uncertain records have no "Unknown" escape hatch.
- **Severity:** MEDIUM

### M-9. Vaccination records have no completion/pending status (source §18)

- **Source (§18):** the worked example is explicitly stateful — "BCG — ✓ Completed", "Hepatitis B — ✓ Dose 1, ✓ Dose 2, **○ Dose 3**". A pending future dose is a visible, distinct state.
- **PRD:** FR-20 fields are vaccine name, dose number, date administered, provider, batch number, next dose due date, notes. **There is no status field**, and "date administered" is implicitly required — so a *scheduled but not yet given* dose cannot be represented as its own record. FR-21's consequence ("mark the record complete and create the next dose record") references a completion concept that FR-20 never defines.
- **Severity:** MEDIUM

### M-10. Member dashboard omits Allergies, Health Alerts, and recent Lab Reports (source §5)

- **Source (§5 Health Overview):** the dashboard summary must show current medications, active conditions, **allergies**, blood group, recent measurements, upcoming appointments, vaccinations, **recent reports**, and **health alerts**.
- **PRD:** FR-5 lists age, blood group, active Conditions, active Medications, upcoming Appointments, recent Measurements, upcoming Vaccinations, and *count of Documents added in the last 30 days*.
- **Gaps:** (a) **Allergies are not in FR-5's dashboard list** — FR-8's consequence says severe allergies show a visual indicator on the dashboard, but the non-severe allergy list is not surfaced there; (b) "recent Lab Reports" is replaced by a document *count*, which is a weaker, less clinical signal; (c) **"Health alerts"** — the source's catch-all for things needing attention (missed doses, overdue vaccinations, expiring items) has no corresponding concept anywhere in the PRD. FR-13's missed-dose summary is the nearest thing, but it is medication-only and appears on app open rather than on the Member dashboard.
- **Severity:** MEDIUM

### M-11. PDF health summary omits Recent Medical History (source §41)

- **Source (§41 Doctor Visit Report):** the generated Health Summary contains Patient, Age, Blood Group, Active Conditions, Current Medications, Recent Measurements, Recent Lab Results, Allergies, and **Recent Medical History**.
- **PRD:** FR-46 lists name, age, blood group, Allergies, active Conditions, current Medications, upcoming Appointments, Vaccination record, recent Measurements, recent Lab Report results. **Recent Medical History is missing** — the past-events context a doctor is most likely to ask for. (The PRD adds upcoming Appointments and Vaccinations, which the source did not have.)
- **Severity:** MEDIUM

---

## Qualitative intent flattened by the FR structure

### Q-1. The recommended product positioning statement is absent (source §56) — MEDIUM

- **Source (§56 Recommended Product Positioning):** an explicit, deliberate positioning instruction. The positioning is *not* "a health tracking app" — it is **"Your family's private digital health record."** It supplies the value-proposition chain (all family health information → one private app → stored on your phone → available offline → backed up to your own cloud) and states this "gives the app a very clear differentiation from cloud-based health platforms."
- **Source also supplies two candidate Bangla taglines** and *recommends the second*: **আপনার পরিবারের স্বাস্থ্য তথ্য, আপনার কাছেই।** — "because it particularly reinforces the local-first/private-data philosophy."
- **PRD:** §1 Vision paraphrases the substance well (privacy-first, offline, no server, family-wide) and adds strong market evidence, but **there is no positioning statement, no value-proposition line, and no tagline anywhere in the document** — including §8 Monetization and the store-listing-adjacent SM-1/SM-3 metrics. The named, recommended Bangla tagline is lost entirely, despite FR-51 making Bangla the default UI language.
- **Consequence:** downstream UX and store-listing work has no canonical one-line product statement to build from; §1 Vision is a paragraph, not a positioning line.

### Q-2. The first-launch privacy promise is replaced by a legal disclaimer (source §50) — MEDIUM

- **Source (§50):** the welcome screen copy is a *reassurance*: "Welcome to Family Health — **Your health information stays on this device.** [Create Family]". The first thing a user reads is the product's core promise.
- **PRD:** FR-1 makes the first screen a **medical disclaimer** ("Jotno is for health record management only. It does not provide medical advice…") plus a Create Your Family CTA, and FR-2 immediately follows with an **ads consent screen**. The privacy promise — the reason the user chose this app — is nowhere in the first-run sequence.
- **Consequence:** the onboarding sequence now opens on two pieces of legal/compliance text. This inverts the emotional register the source designed for and undercuts §56's differentiation at the exact moment it matters most. FR-1 could carry both the disclaimer *and* the privacy line at negligible cost.

### Q-3. The Health Timeline's status as a hero feature is levelled (source §30) — LOW

- **Source (§30):** "One of the best features for the app." — an explicit signal of where the product's distinctiveness lies.
- **PRD:** §4.8 treats it as one feature among fourteen, with a single FR (FR-30). It does get a primary nav tab (§7), which partly preserves the intent, but no §1 or §11 emphasis — no success metric measures timeline engagement, while SM-2 measures medication reminders.

### Q-4. "Record keeping, not diagnosis" is well preserved — NO GAP

- Source §7 ("this is record keeping, not diagnosis"), §19 ("do not hard-code medical recommendations… without a medically reviewed source"), §26 (distinguish displaying results from interpreting them), and §55 (keep medical AI "firmly in the information-management/record-retrieval space") are all faithfully carried into PRD §6 Medical Safety, FR-27, FR-20/§4.5, and §9 Non-Goals. Noted as a positive; no action.

### Q-5. "Never silently overwrite" principle not carried into restore/import (source §46) — LOW

- **Source (§46 Sync Conflict Handling):** "**Never silently overwrite.**" Conflicts must be surfaced with Keep A / Keep B / Keep Both. The source frames this as a safety principle because "health data conflicts can be dangerous" (§45).
- **PRD:** Multi-device sync is correctly out of scope, so conflict UI is not needed. But the *principle* is not applied to the operations that do ship: FR-41 says restore "will replace current local data" (with a pre-restore backup offered), and FR-49 CSV import is all-or-nothing with no duplicate detection or merge choice. §44 of the source hedges "replaced **or merged**"; the PRD only offers replace.

---

## LOW — Nuance or minor detail

### L-1. Relationship field has no enumerated values (source §1) — LOW

Source §1 enumerates family member relationships: Self, Spouse, Children, Parents, Grandparents, Other dependents. FR-4 has "relationship to primary user" with no stated type — free text vs. picker is left open. Minor, but affects the "Self" special case (whose device is it?) and Bangla localisation of relationship terms.

### L-2. Height/Weight exist both as Member profile fields and as Measurements — LOW

Source §3 puts Height and Weight on the member profile; §20 also tracks them as measurements. The PRD reproduces both (FR-4 and FR-22) without stating which is authoritative or whether the profile value auto-updates from the latest Measurement. FR-22's BMI consequence says "current Weight and Height", which does not resolve the ambiguity.

### L-3. Adherence statistics show only one figure (source §11) — LOW

Source §11 displays both "Taken: 92%" and "Skipped: 8%". FR-15 defines a single adherence % = Taken ÷ Total scheduled. With Missed as a distinct status (FR-14), Taken% alone does not distinguish a deliberately skipped dose from a forgotten one — a clinically meaningful difference the source's two-figure display preserves.

### L-4. Backup screen state details (source §43) — LOW

Source §43 specifies the Backup & Sync screen shows provider connection state ("Google Drive — Connected ✓") and **last backup timestamp** ("Today 10:30 AM"). The PRD's FR-42/45 describe the mechanics but never require surfacing last-backup time — the single most reassuring piece of state on that screen, and the one that tells a user whether their data is actually safe.

### L-5. Automatic backup frequency options differ (source §43 vs FR-45) — LOW

Source §43 shows "Frequency — Daily". FR-45 offers Daily **or Weekly**. A harmless expansion; noted only for completeness.

### L-6. Document types listed in source §27 not mapped to categories — LOW

Source §27 names nine stored document types (prescriptions, lab reports, X-rays, CT scans, MRI reports, **discharge summaries**, **medical certificates**, insurance documents, vaccination cards) against §28's seven categories. The PRD adopts the category list (minus Insurance, see M-4) but never states the mapping — discharge summaries and medical certificates presumably fall under "Hospital Record", which is not obvious to a user.

### L-7. Attachments are not encrypted at rest (source §49) — LOW

Source §49 lists "Encrypted attachments" under **Advanced**, so deferring it is faithful to the source. Flagged only because FR-29's consequence — "Documents are stored in the device filesystem" — means photographed prescriptions and lab PDFs (the most legible health data in the app) sit unencrypted while FR-35 encrypts the comparatively terse database. Worth an explicit acknowledgement in §6 Constraints so the privacy claim in §1 is not overstated.

### L-8. Local device profiles (Owner / Adult / Child / Dependent) not mentioned (source §38) — LOW

Source §38 floats local profile types before concluding "For MVP: one app installation = one private family database." The PRD adopts the conclusion (§9 No family sharing) and drops the profile types. Faithful to the source's own MVP call; noted for completeness only.

### L-9. Insurance and Health Expenses (source §33, §34) — LOW / NO ACTION

Source §33 marks insurance "Optional MVP or Phase 2"; §34 keeps expenses "relatively simple"; §55 places both in Phase 2. The PRD's §9 Non-Goals excludes both from MVP — consistent with the source's Phase 2 classification and clearly deliberate. The only residual is the document-category consequence in **M-4**.

---

## Gap Count

| Severity | Count |
|---|---|
| HIGH | 5 |
| MEDIUM | 13 (11 numbered + Q-1, Q-2) |
| LOW | 11 (9 numbered + Q-3, Q-5) |
| **Total** | **29** |

*(Q-4 is a positive finding, not a gap, and is excluded from the count.)*

---

## Appendix — Source §54 MVP checklist coverage

Every item in the source's §54 "MVP — Essential" list has a corresponding FR in the PRD. No §54 item is entirely absent. The one classification divergence is **M-1** (the four backup items moved behind a paid IAP).

| §54 item | PRD |
|---|---|
| Family members / Health profiles | FR-3, FR-4, FR-5 |
| Medical history / Conditions / Allergies | FR-6, FR-7, FR-8 |
| Medications / reminders / history | FR-11–FR-16 |
| Doctors | FR-9 (+ FR-10 Hospitals, not in §54 — expansion) |
| Appointments / reminders | FR-17, FR-18, FR-19 |
| Vaccinations | FR-20, FR-21 |
| Basic measurements | FR-22–FR-25 |
| Lab reports | FR-26, FR-27, FR-28 |
| Medical documents | FR-29 |
| Health timeline | FR-30 |
| Emergency health card | FR-31, FR-32, FR-33 |
| Local SQLite / offline / local encryption | FR-35, NFR-P1 |
| PIN/Biometric lock | FR-36, FR-37, FR-38 |
| PDF export / JSON+CSV export | FR-46, FR-47, FR-48 |
| Encrypted backup | FR-39 (local, free) |
| Google Drive / OneDrive / Dropbox backup | FR-42, FR-43 — **paid IAP, see M-1** |

---

## Appendix — PRD-internal inconsistency noticed in passing

Not a source gap, but it will confuse downstream consumers: **§10.1 MVP Scope says "All features defined in §4 (FR-1 through FR-51)"**, while §4 defines **FR-52** (English UI option) and §5 NFR-P1 and §8 Monetization both reference "FR-1 through FR-52". FR-52 is therefore excluded from MVP by §10.1 and included everywhere else. Almost certainly a typo in §10.1.
