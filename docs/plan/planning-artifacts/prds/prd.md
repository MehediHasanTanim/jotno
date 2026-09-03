---
title: Jotno — Family Health Manager
status: final
created: 2026-08-29
updated: 2026-08-29
---

# PRD: Jotno — Family Health Manager

## 0. Document Purpose

This PRD is the authoritative requirements document for Jotno, addressed to the solo developer and to downstream workflow owners: UX design, architecture, epics, and stories. Vocabulary is defined in §3 Glossary; all FRs, UJs, and SMs use Glossary terms exactly. Inline `[ASSUMPTION]` tags mark inferred decisions; they are indexed in §13 and must be confirmed before architecture begins.

Inputs that informed this PRD: the Jotno product brief (`_bmad-output/planning-artifacts/briefs/brief-bmad-test-2026-08-28/brief.md`), the feature specification (`family-health-manager/docs/features/feature_details.md`), and the technical implementation plan (`family-health-manager/docs/plan/technical_implementation_plan.md`). This PRD captures the *what*; the technical plan captures the *how* and lives in the addendum.

No UX document exists yet; this PRD precedes that work.

---

## 1. Vision

Jotno (জত্ন — Bengali for *care*) is a privacy-first, offline-capable mobile app (Android & iOS) that gives Bangladeshi families a single private place to manage the health records of every household member — from grandparents to children.

Today, Bangladeshi families keep health records in plastic folders, photograph prescriptions in WhatsApp groups, and rely on memory for medication schedules. A 2026 qualitative study in *BMC Digital Health* on digital health adoption in Bangladesh found continued reliance on paper prescriptions outside Dhaka, with privacy concerns cited as a barrier to digital alternatives ([Springer](https://link.springer.com/article/10.1186/s44247-026-00243-2)).

The market has not answered this. Bangladesh's health apps are telemedicine (Sebaghar, DocTime, Maya) or pharmacy delivery (Arogga) — all requiring connectivity, most English-first, none keeping a longitudinal record across a household. Nothing available manages family health records offline, in Bangla, without a cloud account. That is the gap Jotno fills.

Each Member has a Health Profile — their conditions, allergies, medications with local reminders, appointments, vaccinations, measurements, lab reports, and a document vault. A unified Health Timeline shows all events across all Members. An Emergency Health Card surfaces critical information instantly. Cloud backup is opt-in, encrypted, and stored in the user's own Google Drive, OneDrive, or Dropbox — Jotno never touches the data, and there is no Jotno server.

**Positioning.** Jotno is not "a health tracking app" — that framing invites comparison with fitness and step-counting apps and undersells what it does. It is **your family's private digital health record**: the folder of prescriptions, reports, and vaccination cards that every household already keeps, made searchable, remembered, and carried in a pocket. Every product decision — the Bangla-first UI, the absence of an account, the local database, the one-tap PDF for the doctor — follows from that. In the user's own words:

> **আপনার পরিবারের স্বাস্থ্য তথ্য, আপনার কাছেই।**
> *Your family's health information, with you — always.*

---

## 2. Target User

### 2.1 Jobs To Be Done

- Keep all family health records in one searchable place instead of plastic folders and WhatsApp photos
- Never miss a family member's medication dose
- Walk into a doctor's appointment with a ready health summary
- Know at a glance whether Father took his evening medicine
- Find a two-year-old lab report in seconds
- Know every family member's blood group and allergies without asking
- Trust that sensitive health records are not stored on anyone else's server

### 2.2 Non-Users (v1)

- Healthcare providers (doctors, nurses) — Jotno is a patient-side tool, not a clinical system
- Users seeking medical advice, diagnosis, or treatment recommendations
- Users who need multiple people to access the same records on separate devices simultaneously (multi-device sync is post-MVP)

### 2.3 Key User Journeys

**UJ-1. Sumaiya sets up her father's medications and gets the first reminder.**
- **Persona + context:** Sumaiya, 34, Dhaka. Manages her diabetic father's daily medications. Currently sends a photographed handwritten schedule to siblings on WhatsApp.
- **Entry state:** First week of use. Family created. Father's Member profile exists. App unlocked.
- **Path:** Opens Medications for Father → Adds "Metformin 500mg, twice daily, after meal" → Sets reminder times (8 AM, 8 PM) → Sets mode to "Confirmation" (ask before logging) → Saves. At 8 PM notification fires: "💊 Metformin 500mg — Father." She taps "Taken." Medication Log updates.
- **Climax:** Next morning she checks Father's Medication History: ✓ both doses yesterday. She knows without calling.
- **Resolution:** The WhatsApp screenshots stop. She stops carrying the schedule in her head.
- **Edge case:** Father misses the 8 PM dose. Next morning she sees it marked "Missed" and can retroactively log Taken or Skipped.

**UJ-2. Rafi records his mother's blood pressure and checks the three-month trend.**
- **Persona + context:** Rafi, 28, Chattogram. Mother has hypertension; they measure BP at home twice weekly.
- **Entry state:** App open, Mother's profile selected.
- **Path:** Taps "+" → Blood Pressure → Enters 138/88, pulse 76, context "before medication", arm "right", position "sitting" → Saves. Taps BP History → Selects 3-month chart → Sees steady decline since new medication began in June.
- **Climax:** Chart shows 138/88 today vs 155/95 three months ago. He screenshots to share with the doctor next week.
- **Resolution:** Three months of readings now say something a single reading could not — the new medication is working.

**UJ-3. Nadia generates a health summary before her son's paediatrician visit.**
- **Persona + context:** Nadia, 31, Sylhet. Son Aryan, 4 years old, has a scheduled appointment. The doctor always asks for vaccination history and current medications.
- **Entry state:** Aryan's profile has vaccinations, two active Medications, known penicillin Allergy. App unlocked via fingerprint.
- **Path:** Opens Aryan's profile → "Export Health Summary" → Preview PDF → Share → Sends to WhatsApp.
- **Climax:** The PDF shows Aryan's blood group, penicillin Allergy (bold alert), active Medications with dosages, and vaccination record — one page, in Bangla.
- **Resolution:** The consultation starts with the doctor already informed, rather than with Nadia reciting from memory.

**UJ-4. Karim needs the Emergency Health Card for his father in the ER.**
- **Persona + context:** Karim, 42, Rajshahi. Father collapsed. Karim is at the hospital and needs to tell the ER doctor his father's blood group, allergies, and medications immediately — and then reach his father's cardiologist.
- **Entry state:** Phone locked, Karim shaking. Rapid emergency access is enabled for Father. [ASSUMPTION: Karim enabled it during setup]
- **Path:** Reaches the emergency shortcut from the locked device → Father's Emergency Health Card opens without a PIN → shows B+, Penicillin allergy flagged SEVERE at the top, active Medications, and Emergency Contacts.
- **Climax:** He reads the allergy and Medications to the ER nurse in under ten seconds, then taps Dr. Ahmed's number on the card and the phone dials.
- **Resolution:** Father receives correct treatment and his cardiologist is on the way. The card was there when it mattered, and it dialled.

---

## 3. Glossary

- **Jotno** — The application. From Bengali জত্ন (care, nurturing).
- **User** — The person operating the app: the household's health coordinator. One User per installation; Jotno has no accounts and does not distinguish between people using the device. Distinct from **Member** — the User is usually also a Member, but manages every Member's records.
- **Family** — The household unit managed in one Jotno installation. One device holds one Family.
- **Member** — An individual person in the Family whose health records are tracked. May be self, spouse, children, parents, grandparents, or any dependent.
- **Health Profile** — The complete set of health data belonging to one Member: conditions, allergies, Medical History, Medications, Appointments, Vaccinations, Measurements, Lab Reports, and Documents.
- **Medical History** — A record of a past medical event (illness, surgery, hospitalization, injury) for a Member.
- **Condition** — An active or chronic health condition of a Member (e.g. Diabetes, Hypertension).
- **Allergy** — A recorded sensitivity or adverse reaction of a Member to a substance (medication, food, or environmental).
- **Medication** — A drug or supplement prescribed to or taken by a Member.
- **Medication Schedule** — The defined timing and dosage at which a Medication is to be taken.
- **Medication Log** — A per-dose record of whether a scheduled Medication was Taken, Skipped, Snoozed, or Missed.
- **Medication Engine** — The local on-device service that evaluates Medication Schedules and generates reminder notifications.
- **Prescription** — A record of one prescribing event: the Doctor, the date, the attached slip or PDF, and the Medications it produced. One Prescription may yield many Medications.
- **Emergency Contact** — A named phone number a Member or the Family may need urgently — family, doctor, hospital, ambulance, or insurer — callable in one tap from the Emergency Health Card.
- **Appointment** — A scheduled visit to a Doctor or healthcare facility for a Member.
- **Vaccination** — A recorded immunisation event for a Member, including dose number, date, provider, and next-due date.
- **Measurement** — A recorded vital sign or body metric for a Member (e.g. Blood Pressure, Weight, Blood Glucose).
- **Lab Report** — A recorded set of laboratory test results for a Member.
- **Lab Result** — A single test result within a Lab Report (e.g. Haemoglobin: 13.8 g/dL).
- **Document** — A file (image or PDF) stored in the Document Vault for a Member.
- **Document Vault** — The per-Member repository of all Documents.
- **Health Timeline** — A unified chronological feed of all health events across all Members.
- **Emergency Health Card** — A condensed, rapidly accessible view of a Member's critical health information: blood group, Allergies, active Conditions, current Medications, and emergency contacts.
- **Doctor** — A healthcare provider record (name, specialty, contact, Hospital).
- **Hospital** — A healthcare facility record (name, address, contact). Includes clinics, diagnostic centres, pharmacies.
- **Backup File (.hfm)** — An encrypted, portable file containing a complete snapshot of the Family's Jotno data (database + attachments). File extension `.hfm`.
- **Cloud Provider** — A user-owned cloud storage service (Google Drive, OneDrive, or Dropbox) to which Backup Files are optionally uploaded.
- **Local-first** — All data is created, stored, and read from the local device database. No network connection is required for any core function.

---

## 4. Features

### 4.1 Family Setup & Member Management

**Description:** On first launch, Jotno shows a medical disclaimer and prompts the user to create their Family — no account, email, or password required. The user names the Family and adds Members. Each Member has a profile with personal and medical baseline fields. Members are the primary navigation unit; all health data hangs off a Member. Realizes UJ-1, UJ-2, UJ-3, UJ-4.

**Functional Requirements:**

#### FR-1: First-launch welcome and privacy promise

On first launch, the first screen User sees states what Jotno is and its core promise, in the active language: *"আপনার পরিবারের স্বাস্থ্য তথ্য, আপনার কাছেই।"* / *"Your family's health information stays on this device."* The screen names the product's defining properties in plain language: no account needed, works without internet, data stored only on this device. No registration field, email field, or OTP is shown anywhere in onboarding.

**Consequences:**
- This screen precedes all legal and consent text. The user learns what Jotno is before being asked to agree to anything.
- No network request is made on this screen.
- Copy is stored in the app bundle; it is not fetched from a server.

#### FR-2: Medical disclaimer

Following FR-1, User sees a plain-language medical disclaimer in the active language: *"Jotno is for health record management only. It does not provide medical advice, diagnosis, or treatment recommendations. Always consult a qualified doctor."*

**Consequences:**
- Onboarding does not proceed until User acknowledges the disclaimer.
- The disclaimer remains accessible from Settings at any time after onboarding.
- Disclaimer text is stored in the app bundle.

#### FR-3: AdMob consent screen

Following FR-2, and before any AdMob SDK initialisation, User sees a consent screen explaining that Jotno is free and supported by ads, that the ad network (Google AdMob) collects device identifiers for ad serving, and that health records are never shared with it. User chooses: personalised ads or non-personalised ads. The full privacy policy (FR-4) is reachable from this screen and readable before the choice is made.

**Consequences:**
- AdMob SDK is not initialised before the user interacts with this screen.
- Consent choice is stored locally and honoured on subsequent launches; it is changeable in Settings.
- Declining personalised ads does not affect any core app functionality.
- Health data is never passed to AdMob as targeting signals.

#### FR-4: In-app privacy policy

Jotno includes a full privacy policy readable in-app, in both Bangla and English, without an internet connection. It is reachable from the AdMob consent screen (FR-3) and from Settings.

The policy states: (a) health data is stored only on the device and never sent to any Jotno server — Jotno operates no server; (b) cloud backup, when enabled, transfers encrypted files directly to the user's own Cloud Provider; (c) Google AdMob receives device identifiers and what that means; (d) Firebase Analytics receives event names and timestamps only, never health data; (e) which device permissions are requested and why; (f) that no health data appears in crash reports or diagnostics; (g) how to disconnect a Cloud Provider and delete backups.

**Consequences:**
- The policy is bundled with the app, not fetched — it is readable offline and cannot change without an app update.
- The same content is published at a public URL for Play Store and App Store listing requirements.

#### FR-5: Device permission requests

Jotno requests device permissions only at the point of first use, never during onboarding. Each request is preceded by an in-app explanation screen in the active language stating why the permission is needed and what happens if it is denied.

Permissions: **Notifications** (requested when the user creates their first Medication Schedule or Appointment reminder), **Camera** (requested when the user first photographs a prescription or document), **Photo library** (requested when the user first attaches an existing image).

**Consequences:**
- Denying notification permission disables reminder delivery. The app shows a persistent, dismissible banner on the Medications screen explaining that reminders cannot fire, with a shortcut to system settings.
- Denying camera permission leaves file-picker attachment available; the camera option is hidden rather than shown broken.
- All permission rationale copy exists in both Bangla and English, and is supplied verbatim to the iOS `Info.plist` usage descriptions.
- No permission is requested that a feature in use does not need. Jotno does not request contacts, location, SMS, or storage-wide access.

#### FR-6: Family creation

User can create a Family with a name (e.g. "Hasan Family"). The Family name appears on the home screen.

**Consequences:**
- Family creation requires no internet connection.
- Family name is editable after creation.

#### FR-7: Member management

User can add, edit, and delete Members. Each Member record holds: full name, nickname, date of birth (age auto-calculated and displayed), gender, relationship to primary user, blood group, height, weight, profile photo (stored locally), emergency contact name and phone, and notes.

**Consequences:**
- Unlimited Members per Family. [ASSUMPTION: no hard cap enforced in MVP]
- Deleting a Member soft-deletes all associated Health Profile data; User is warned with a count of affected records before deletion.
- Member list is the entry point to all health data for that Member.

#### FR-8: Member dashboard

Each Member has a dashboard showing: calculated age, blood group, active Conditions (count + list), active Medications (count + next reminder time), upcoming Appointments (next 7 days), most recent Measurement per type, upcoming Vaccinations due, and count of Documents added in the last 30 days.

**Consequences:**
- Tapping any dashboard section navigates to the relevant feature.

---

### 4.2 Medical Records

**Description:** Each Member maintains structured medical data: past Medical History events, active Conditions, and Allergies. Severe Allergies are prominently surfaced wherever clinically relevant. Doctor and Hospital records are shared across the Family. Realizes UJ-3, UJ-4.

**Functional Requirements:**

#### FR-9: Medical History records

User can create, edit, and delete Medical History entries for a Member. Fields: event type (Illness / Surgery / Hospitalisation / Injury / Other), title, date, linked Doctor (from directory or free text), linked Hospital (from directory or free text), description, status (Active / Resolved / Chronic / Under Treatment / Unknown), notes, and linked Documents.

**Consequences:**
- Medical History entries are sortable by date and filterable by status.
- Linked Documents are viewable inline from the Medical History record.
- Deleting a Medical History entry does not delete linked Documents.

#### FR-10: Condition tracking

User can create, edit, and delete Conditions for a Member. Fields: condition name, status (Active / Resolved / Chronic), diagnosed date, linked Doctor, notes, and linked Documents.

**Consequences:**
- Active and Chronic Conditions appear on the Member dashboard and Emergency Health Card.
- Conditions are user-entered; the app does not infer or auto-suggest conditions.

#### FR-11: Allergy management

User can create, edit, and delete Allergies for a Member. Fields: substance name, type (Medication / Food / Environmental / Other), severity (Mild / Moderate / Severe / Unknown), reaction description, notes.

**Consequences:**
- Allergies with severity "Severe" display a high-contrast visual alert indicator on the Member dashboard, Emergency Health Card, PDF health summary, and Member profile header.
- All Allergies are visible without additional taps on the Member profile.

#### FR-12: Doctor directory

User can create, edit, and delete Doctor records shared across the Family. Fields: name, specialty, linked Hospital or free-text clinic name, phone, address, chamber information, notes.

**Consequences:**
- Doctors are selectable when creating Appointments, Medical History, and Medications.
- Doctor directory is searchable by name and specialty.

#### FR-13: Hospital directory

User can create, edit, and delete Hospital records shared across the Family. Types: Hospital / Clinic / Diagnostic Centre / Pharmacy. Fields: name, address, phone, website, notes.

**Consequences:**
- Hospitals are selectable when creating Appointments and Medical History entries.

---

### 4.3 Medication Management

**Description:** Jotno tracks each Member's Medications, when they are due, and whether they were taken. The Medication Engine runs on app open/resume and generates local notifications per Medication Schedule. Adherence is logged per dose. Prescriptions can be attached as photos or PDFs. Realizes UJ-1.

**Functional Requirements:**

#### FR-14: Medication records

User can create, edit, and delete Medications for a Member. Fields: medicine name, generic name, dosage, unit (mg / ml / tablet / capsule / drop / other), route (Oral / Topical / Injection / Inhaler / Other), purpose, start date, end date (optional), prescribed by (linked Doctor or free text), instructions, status (Active / Completed / Paused).

**Consequences:**
- Active Medications appear on the Member dashboard and in the Medication schedule view.
- Completed or Paused Medications remain in history and do not generate reminders.
- Paused Medications can be resumed; this re-activates their Schedules.

#### FR-15: Medication Schedules

Each Medication can have one or more Medication Schedules. A Schedule defines: frequency (Daily / Specific days of week / Monthly on a date), times of day (one or more), dose per intake, start date, end date (optional), and auto-creation mode (Automatic — log without prompt / Confirmation — notify and ask / Reminder only — notify, no auto-log). [ASSUMPTION: these three frequency types cover MVP; irregular schedules are post-MVP]

**Consequences:**
- One Schedule carries multiple times of day. A Medication taken at 8 AM, 2 PM, and 8 PM is one Schedule with three times, not three Schedules. Multiple Schedules on one Medication exist for genuinely different regimens — a tapering dose, or a different dose on weekends.
- Auto-creation mode is set per Schedule, not per Medication.

#### FR-16: Medication Engine

The Medication Engine pre-schedules local device notifications with the operating system's notification scheduler for every upcoming dose across all active Medication Schedules. Notifications are delivered by the OS at the scheduled time **whether or not Jotno is running, backgrounded, or has been killed by the user or the system**. The engine operates entirely on-device with no network dependency and no dependency on a long-running background process.

**Consequences:**
- A scheduled dose notification fires at its scheduled time even if the app has not been opened for days and is not resident in memory.
- The engine maintains a rolling scheduling horizon: on every app open, resume, and successful notification delivery, it tops up the OS notification queue so at least the next 7 days of doses are always scheduled. [ASSUMPTION: 7-day horizon; both platforms cap the number of concurrently pending local notifications, so an unbounded horizon is not viable]
- On device reboot, the app re-registers all pending notifications via the platform's boot-completed mechanism, since some platforms clear scheduled notifications on restart.
- On timezone change or device clock change, the engine recomputes and re-schedules all pending notifications against the new local time.
- **Catch-up reconciliation:** on app open, the engine reconciles actual elapsed time against the Medication Log. Doses whose scheduled time has passed with no logged action are marked Missed. If missed doses exist, the app surfaces a summary — "You have N missed doses across M family members. Review?" — and allows bulk review (mark all Taken, Skipped, or review individually) before proceeding to the home screen.
- Notification content is governed by NFR-S2: Member name, Medication name, and scheduled time only. Dosage, purpose, and any Condition context are excluded, because notification previews are visible on the lock screen to bystanders. The full dose detail is shown once the user opens the app from the notification.
- If the User has revoked notification permission at the OS level, the app detects this on open and prompts them to re-enable it, explaining that reminders cannot fire without it.
- **Battery-optimisation guidance.** Several Android OEMs common in Bangladesh (Xiaomi, Oppo, Vivo, Realme) suspend scheduled notifications for apps not exempted from battery optimisation. On these devices the app detects the restriction and shows a one-time, dismissible prompt with a direct link to the relevant system settings screen, explaining that reminders may not arrive otherwise. The prompt appears when the User creates their first Medication Schedule, not at onboarding.

**Out of Scope:**
- Guaranteed delivery when the OS or OEM suppresses notifications despite the guidance above. Jotno can detect, explain, and link to the fix; it cannot enforce it.

#### FR-17: Dose logging

User can mark each scheduled dose as Taken, Skipped, or Snoozed from the notification or from within the app.

**Consequences:**
- Each Medication Log entry records: scheduled time, action time, and status (Taken / Skipped / Snoozed / Missed).
- Snooze reschedules the notification by 15 minutes. [ASSUMPTION: snooze duration is fixed at 15 minutes in MVP]
- A dose not actioned before the next scheduled dose time is automatically marked Missed.
- Retroactive logging (marking a past dose Taken or Skipped) is allowed.

#### FR-18: Medication adherence history

User can view adherence history for any Medication as a month calendar, each day showing per-dose status (Taken / Skipped / Missed), with an aggregate adherence percentage over a selectable date range.

**Consequences:**
- Adherence % = (Taken doses ÷ Total scheduled doses in period) × 100.
- History displays per-dose status with timestamps.

#### FR-19: Prescriptions

A Prescription is a record in its own right, not merely a file attached to a Medication — one visit to a doctor typically produces one Prescription listing several Medications. User can create, edit, and delete Prescriptions for a Member. Fields: prescribing Doctor (linked or free text), Hospital (linked or free text), date, notes, and one or more attached images or PDFs.

**Consequences:**
- One Prescription links to **many** Medications; one Medication links to at most one Prescription. Adding three Medications from a single doctor's slip attaches that one scan once, not three times.
- A Prescription can be linked to the Appointment it came from (FR-20), so the visit, its notes, and its prescription stay connected.
- User can create a Prescription first (photograph the slip at the clinic) and add its Medications later, or create a Medication first and link it to a Prescription afterwards. Neither order is forced.
- Attachments land in the Document Vault under the Prescription category and are viewable from the Prescription, from any linked Medication, and from the linked Appointment.
- Deleting a Prescription does not delete the Medications it produced; those Medications simply become unlinked.
- Prescriptions appear on the Health Timeline and are included in Backup Files and Document export.

---

### 4.4 Appointments

**Description:** Jotno tracks upcoming and past Appointments for each Member. Reminders fire via local notifications before the Appointment. Post-visit notes and attachments can be added. Realizes UJ-3.

**Functional Requirements:**

#### FR-20: Appointment management

User can create, edit, and delete Appointments for a Member. Fields: Member, linked Doctor (or free text), linked Hospital (or free text), date, time, reason (free text), status (Scheduled / Completed / Cancelled / Rescheduled / Missed), notes, and linked Documents.

**Consequences:**
- Appointments appear on the Family Health Calendar and Member dashboard.
- Status is user-set; the app does not auto-transition Appointment status.

#### FR-21: Appointment reminders

User can enable up to four local notification reminders per Appointment: 1 day before, 3 hours before, 1 hour before, 30 minutes before (any combination).

**Consequences:**
- When an Appointment is rescheduled to a new date/time, existing reminders are cancelled and new ones scheduled automatically.
- Notification content: Member name, Doctor name, Appointment time, and location.

#### FR-22: Post-visit notes and attachments

After an Appointment, User can add doctor's notes (free text) and attach Documents (prescription scan, referral letter, lab order).

**Consequences:**
- Post-visit notes are stored locally and visible from the Appointment record.
- Attachments land in the Document Vault and are linked to the Appointment.

#### FR-23: Standalone reminders

Beyond the reminders attached to Medications (FR-16), Appointments (FR-21), and Vaccinations (FR-25), User can create a standalone reminder for a Member. Types: **Lab test due**, **Health measurement due** (e.g. "check BP every Monday"), and **Follow-up** (e.g. "see Dr. Ahmed again in 1 month"). Each has: title, Member, date and time, optional repeat (none / daily / weekly / monthly), and optional notes.

**Consequences:**
- Standalone reminders are delivered by the same OS-scheduled notification mechanism as FR-16, with the same reliability characteristics and the same content restriction (NFR-S2).
- Standalone reminders appear on the Family Health Calendar (FR-39) and the Health Timeline (FR-34).
- A Follow-up reminder can carry a link to the Appointment that prompted it; acting on the reminder offers to create the new Appointment prefilled with the same Doctor.
- Completing or dismissing a reminder is logged so the Timeline reflects what was actually acted on.

---

### 4.5 Vaccinations

**Description:** Jotno tracks Vaccination records for all Members — particularly relevant for children's immunisation courses. Users enter Vaccinations manually; no pre-loaded medical schedule is embedded in v1 to avoid including clinically unreviewed content.

**Functional Requirements:**

#### FR-24: Vaccination records

User can create, edit, and delete Vaccination records for a Member. Fields: vaccine name, dose number, date administered, provider (linked Hospital or free text), batch number (optional), next dose due date (optional), notes.

**Consequences:**
- Multi-dose vaccines (e.g. Hepatitis B Dose 1, 2, 3) are tracked as separate records under the same vaccine name.
- Vaccination records display grouped by vaccine name in chronological dose order.

#### FR-25: Vaccination reminders

When a next dose due date is set, a local notification reminder fires on that date and optionally N days before (user-configurable from 0–7 days). [ASSUMPTION: lead-time options: 0, 1, 3, 7 days before]

**Consequences:**
- Reminder fires locally without internet.
- After administering a dose, User can mark the record complete and create the next dose record.

---

### 4.6 Health Measurements

**Description:** Jotno tracks vital signs and body metrics for each Member, with trend charts to visualise change over time. Blood Pressure and Blood Glucose have dedicated detailed entry forms. All Measurement types share a common chart component with configurable time ranges. Realizes UJ-2.

**Functional Requirements:**

#### FR-26: Measurement recording

User can record Measurements for a Member. Supported types in MVP: Blood Pressure, Blood Glucose, Weight, Height, Body Temperature, Heart Rate, SpO₂. Each Measurement records: type, value(s), unit, date, time, and notes. Users can also define custom Measurement types with a name and a single numeric value. [ASSUMPTION: custom Measurement type has one numeric value field and a user-defined unit string]

**Consequences:**
- BMI is calculated and displayed automatically when both current Weight and Height are on record.

#### FR-27: Blood Pressure detailed entry

Blood Pressure Measurement additionally captures: systolic (mmHg, required), diastolic (mmHg, required), pulse (bpm, optional), measurement context (Before Medication / After Medication / Before Meal / After Meal / Other — optional), arm (Left / Right — optional), position (Sitting / Standing / Lying — optional).

**Consequences:**
- Systolic and diastolic values are both required to save a Blood Pressure Measurement.
- Blood Pressure chart displays systolic and diastolic as two separate lines on one chart.

#### FR-28: Blood Glucose detailed entry

Blood Glucose Measurement additionally captures: glucose value (required), unit (mmol/L or mg/dL — global user setting), and measurement type (Fasting / Before Meal / After Meal / Random / Bedtime).

**Consequences:**
- Unit selection is a global app setting; applies to display and entry for all Members.
- Historical readings retain the unit in which they were recorded; display converts if the setting changes. [ASSUMPTION: unit conversion is a display-layer concern only; stored value is always in the original unit]

#### FR-29: Measurement trend charts

User can view a trend chart for any Measurement type for any Member. Available time ranges: 7 days, 30 days, 3 months, 6 months, 1 year.

**Consequences:**
- Chart is included in the PDF health summary (FR-54).
- Tapping a data point on the chart shows the full Measurement record for that entry.

---

### 4.7 Lab Reports & Document Vault

**Description:** Jotno stores Lab Reports (structured results) and Documents (files) locally for each Member. The Document Vault is a searchable, filterable repository of all attached files across all record types.

**Functional Requirements:**

#### FR-30: Lab Report entry

User can create a Lab Report for a Member. Fields: report date, lab/diagnostic centre name, ordering Doctor (linked or free text), notes. Each Lab Report contains one or more Lab Results.

#### FR-31: Lab Result entry

Each Lab Result within a Lab Report has: test name (from a preset list or custom entry), value, unit, reference range (optional), and an out-of-range flag (user-set). [ASSUMPTION: preset test list includes CBC, Blood Glucose, HbA1c, Lipid Profile, Creatinine, Liver Function Tests, Thyroid Profile, Vitamin D, Urine Routine Examination; custom test names are free text]

**Consequences:**
- Lab Results are not auto-interpreted. The app displays values and reference ranges; clinical interpretation is the user's and their doctor's responsibility.
- The out-of-range flag is a user-set marker; the app does not evaluate reference ranges automatically.

#### FR-32: Lab Result history and trend

User can view historical Lab Results for a selected test name across all Lab Reports for a Member, displayed as a trend chart (FR-29 chart component reused) and a list sorted by date.

#### FR-33: Document attachment and vault

User can attach photos and PDFs to any record (Medication, Appointment, Lab Report, Medical History, Vaccination). All attachments are accessible from the Member's Document Vault. The vault is browsable by category (Prescription / Lab Report / Imaging / Hospital Record / Vaccination / Other) and filterable by date range, Doctor, Hospital, and keyword.

**Consequences:**
- Documents are stored in the device filesystem; metadata (path, type, size, linked entity) is in the database.
- Document search covers document titles, notes, and linked entity fields.
- Documents are included in Backup Files (.hfm).

---

### 4.8 Health Timeline

**Description:** The Health Timeline is a unified reverse-chronological feed of all health events across all Members — the user's at-a-glance view of the whole Family's health activity.

**Functional Requirements:**

#### FR-34: Health Timeline feed

User can view a chronological list of all health events across all Members: Medications Taken/Missed, Appointments completed or upcoming, Measurements recorded, Lab Reports added, Vaccinations administered, and Documents added.

**Consequences:**
- Timeline is filterable by Member and by event type.
- Each entry shows: date, Member name, event type icon, and a one-line summary.
- Tapping an entry navigates to the full record.

---

### 4.9 Emergency Health Card & Contacts

**Description:** Each Member has an Emergency Health Card — a condensed, high-contrast view of critical health information designed to be read in seconds under stress, possibly by a stranger. Every number on the card dials in one tap, because in an emergency reading a number out is not enough. Realizes UJ-4.

**Functional Requirements:**

#### FR-35: Emergency Contacts

User can create, edit, delete, and reorder Emergency Contacts. Each contact has: name, phone number, type (Family / Doctor / Hospital / Ambulance / Insurance / Other), and an optional note. A contact is either Family-wide (available to every Member) or assigned to a specific Member.

**Consequences:**
- Each contact row offers three actions: **Call** (opens the dialler with the number), **SMS** (opens the messaging app with the number), and **Copy** (copies the number to the clipboard).
- Contact order is user-controlled; the first contact of each type is the one surfaced on the Emergency Health Card.
- Doctors already in the Doctor directory (FR-12) and Hospitals in the Hospital directory (FR-13) can be promoted to Emergency Contacts without re-entering their details.
- Emergency Contacts are included in Backup Files and in the PDF health summary.
- Copying a number to the clipboard is the only path by which contact data leaves the app, and only at explicit user action.

#### FR-36: Emergency Health Card content

Each Member's Emergency Health Card displays: full name, age, blood group, all Allergies (Severe prominently highlighted), active Conditions, current active Medications (name and dosage), and Emergency Contacts applicable to that Member — the Member's own contacts plus all Family-wide contacts.

**Consequences:**
- Card content is read-only; no record editing from the card view.
- Severe Allergies render in a high-contrast alert style (bold, distinct background colour) and sort above all other Allergies.
- Every phone number on the card is tappable to call (FR-35), including from the rapid-access surface in FR-38.
- If a Member has no Allergies recorded, the card states "No known allergies recorded" rather than showing an empty section — an empty section reads as "none" to a stranger, which is a different and dangerous claim.

#### FR-37: Emergency Health Card access

From the Home tab, User can reach any Member's Emergency Health Card in at most two taps: an always-visible Emergency control on Home, then the Member. When the Family has one Member, it is one tap — the picker is skipped.

#### FR-38: Rapid emergency access without app unlock

User can optionally enable rapid access to a Member's Emergency Health Card that does not require unlocking Jotno. This setting is OFF by default and requires explicit activation per Member.

**Consequences:**
- The access mechanism is platform-appropriate and is an architecture decision, not a product one — a lock-screen widget, home-screen widget, persistent notification, Siri/Assistant shortcut, or platform equivalent are all acceptable so long as the requirement below is met. Android and iOS may use different mechanisms.
- **Requirement:** from the locked device, a user who knows the shortcut can display the Emergency Health Card in at most three actions (a tap, swipe, long-press, or voice command each count as one), without entering Jotno's PIN or biometric.
- Whatever mechanism is chosen exposes only Emergency Health Card data (FR-36). No other Health Profile data is reachable without authentication.
- Disabling this setting immediately and completely removes the rapid-access surface.
- If a platform offers no mechanism meeting the requirement, the feature ships on the platforms that do, and the Settings screen explains its absence on the other. It is not a launch blocker for either platform.

---

### 4.10 Family Health Calendar

**Description:** A unified monthly calendar showing all scheduled health events across the Family: Appointment dates, Medication times, Vaccination due dates.

**Functional Requirements:**

#### FR-39: Family Health Calendar

User can view a monthly calendar with all scheduled health events for all Members. Events are visually distinguished by type. Calendar is filterable by Member.

**Consequences:**
- Tapping a calendar event navigates to the relevant record.

---

### 4.11 Security & Privacy

**Description:** Jotno stores sensitive health data. Security is designed in — not added later. The local database is encrypted. The app is locked by PIN or biometric. AdMob is the only component that communicates outside the device; users consent explicitly (FR-3). Realizes cross-cutting NFR-S1 through NFR-S4.

**Functional Requirements:**

#### FR-40: Encrypted local database

All Family, Member, and Health Profile data is stored in an encrypted local SQLite database. The encryption key is stored in the device's platform secure storage (Android Keystore / iOS Secure Enclave).

**Consequences:**
- The database file is not readable without the decryption key even if extracted from the device.
- The encryption key is never stored in plaintext anywhere on the device or in the backup.

#### FR-41: PIN lock

User can set a numeric PIN (minimum 4 digits) to lock the app. When set, the app requires the PIN on launch and after the auto-lock timeout.

**Consequences:**
- After 5 consecutive incorrect PIN entries, the app locks for a cooldown period. [ASSUMPTION: initial cooldown is 30 seconds, doubling on each subsequent failure group]
- PIN is stored as a salted hash in platform secure storage.

#### FR-42: Biometric authentication

User can enable fingerprint (Android) or Face ID/Touch ID (iOS) as an alternative to PIN, if the device supports it. Biometric is available only when a PIN is also configured.

**Consequences:**
- Biometric failure falls back to PIN entry.
- Biometric is silently unavailable on devices without the required hardware.

#### FR-43: Auto-lock

User can configure the app to lock automatically after inactivity: Immediately / After 1 minute (default) / After 5 minutes / After 15 minutes / Never.

**Consequences:**
- App locks immediately when sent to background if auto-lock is "Immediately."
- The rapid emergency access surface (FR-38) operates independently of in-app auto-lock.

#### FR-44: Data deletion

User can permanently erase data through two paths in Settings: **Delete a Member** (removes that Member and their entire Health Profile) and **Delete all data** (returns the app to its first-launch state).

**Consequences:**
- Both paths state exactly what will be destroyed — for a Member, a count of their records by type; for all data, the Family name and total Member count — and require typed or held confirmation, not a single tap.
- Permanent erasure removes the database rows, their soft-deleted predecessors, and the associated Document files from the filesystem. It is not recoverable from within the app.
- Both paths offer to create a Backup File first.
- Erasure is local only. Backup Files already uploaded to a Cloud Provider are untouched; the confirmation says so plainly and links to the Backup & Sync screen, since a user erasing their data usually means all of it.
- "Delete all data" also clears the encryption key, stored OAuth tokens, PIN, and ad-consent choice from secure storage.
- This satisfies the store requirement for a user-initiated data-deletion path (§6 Store Submission) without Jotno holding an account or server-side record.

---

### 4.12 Backup, Restore & Cloud

**Description:** Jotno's data lives on-device; the device is always authoritative. Users can create encrypted Backup Files (.hfm) locally and optionally upload them to their own Cloud Provider. Cloud backup and restore are paid IAP features. Jotno has no servers; no health data is routed through Jotno infrastructure.

**Functional Requirements:**

#### FR-45: Local backup

User can create a Backup File (.hfm) saved to local device storage. The file contains: the encrypted database, all Document attachments, and a manifest.json.

**Consequences:**
- Backup creation requires no internet connection.
- Backup File is encrypted with a user-set backup password (derived key via KDF). [ASSUMPTION: KDF is PBKDF2-SHA256 or equivalent; minimum password length is 8 characters]
- A clear warning is shown: losing the backup password without a saved Recovery Phrase (FR-46) makes an encrypted Backup File permanently unrecoverable.

#### FR-46: Recovery Phrase

When the User sets a backup password, Jotno generates a Recovery Phrase — a human-readable word sequence that can decrypt Backup Files if the password is forgotten. The User is prompted to save it and offered three destinations: copy to clipboard, save as a file to a connected Cloud Provider, or save as a file to local device storage.

**Consequences:**
- The Recovery Phrase is generated on-device from cryptographically secure randomness. [ASSUMPTION: BIP-39-style wordlist, 12 words; final scheme is an architecture decision]
- Jotno never transmits the Recovery Phrase anywhere the User did not explicitly choose.
- Entering a valid Recovery Phrase during restore decrypts the Backup File without the password and prompts the User to set a new one.
- **Storage warning:** when the User chooses to save the Recovery Phrase to the same Cloud Provider that holds their Backup Files, the app displays an explicit warning: anyone with access to that cloud account then holds both the encrypted backup and the means to decrypt it. The app recommends a different location but does not prevent the choice.
- Losing both the password and the Recovery Phrase still makes a Backup File permanently unrecoverable. This is stated plainly at setup.

#### FR-47: Local restore

User can restore from a .hfm Backup File stored on the device. The app verifies backup integrity before restoring.

**Consequences:**
- Restore requires the backup password or the Recovery Phrase (FR-46).
- User is warned that restoring will replace current local data.
- Before any restore, the app offers to create a fresh local backup of the current data.
- **Restore is atomic.** Existing local data is not touched until the backup has been fully decrypted, verified, and staged. If any stage fails, the device is left exactly as it was before the attempt. A failed restore never produces a half-populated database.

#### FR-48: Backup and restore failure handling

Every backup and restore failure mode produces a specific, actionable message in the active language — never a generic error. The app distinguishes and handles at minimum:

**Consequences:**
- **Wrong password / invalid Recovery Phrase:** the app states the credential is incorrect and offers to retry or use the other credential. It does not reveal whether the file itself is valid, and does not count toward the app-lock cooldown (FR-41).
- **Corrupted or truncated Backup File:** detected via the manifest checksum before decryption is attempted. The app names the file as unreadable and, where a Cloud Provider holds older backups, offers the next most recent one.
- **Missing attachments:** if the database restores but referenced Document files are absent from the package, the restore completes and the app reports exactly which records have missing attachments rather than failing wholesale or silently dropping them.
- **Interrupted or partial upload:** an upload that does not complete leaves no partial file listed as restorable. Incomplete uploads are cleaned up on the next successful connection, and the backup is reported as failed, not succeeded.
- **Insufficient device storage:** checked before a backup or restore begins; the app states how much space is needed and does not start an operation it cannot finish.
- **Schema version newer than the app:** a Backup File written by a newer version of Jotno is refused with a message telling the user to update the app, rather than being partially imported.
- Every failure leaves the existing local data intact.

#### FR-49: Cloud connection lifecycle

A connected Cloud Provider can become unusable without the user acting — an expired refresh token, a revoked app authorisation, a deleted folder, or a full cloud account. Jotno detects and surfaces these rather than failing silently.

**Consequences:**
- On any cloud operation returning an authentication failure, the provider is marked **Disconnected** in Backup & Sync, with a "Reconnect" action that re-runs the OAuth flow.
- Automatic backup (FR-53) that fails on authentication does not retry silently forever. After the first failure the app surfaces a persistent notice on the Backup & Sync screen and a local notification, both stating which provider needs attention and how long since the last successful backup.
- The Backup & Sync screen always shows, per provider, the time of the last **successful** backup — not the last attempt — so a long-broken connection is visible at a glance.
- User can disconnect a provider at any time. Disconnecting deletes the stored OAuth token from secure storage and stops all automatic backups to that provider; it does not delete backups already in the user's cloud.
- Quota-exceeded and network-unavailable failures are reported distinctly from authentication failures, since the remedy differs.

#### FR-50: Cloud backup — Google Drive (paid IAP)

User who has purchased the "Private Backup" IAP can connect a Google Drive account via OAuth and upload Backup Files to a dedicated application folder ("Jotno/backups/") in their own Drive.

**Consequences:**
- OAuth token is stored in platform secure storage.
- Backup Files uploaded are the same encrypted .hfm format as local backups.
- No Jotno server receives or processes the backup data; transfer is device-to-Cloud-Provider directly.
- The app requests the minimum required Drive scope (application-specific folder only, not full Drive access). [ASSUMPTION: `drive.file` scope is sufficient; full `drive` scope is not requested]

#### FR-51: Cloud backup — OneDrive and Dropbox (paid IAP)

Same behaviour as FR-50 for Microsoft OneDrive (via Microsoft Graph API) and Dropbox (via Dropbox API).

#### FR-52: Cloud restore (paid IAP)

User can browse available Backup Files in any connected Cloud Provider and restore from any of them.

**Consequences:**
- Restore list shows: backup date, file size, and cloud provider icon.
- Restore requires the backup password or Recovery Phrase (FR-46).
- Pre-restore local backup is offered before restoring.

#### FR-53: Automatic cloud backup (paid IAP)

User can configure automatic cloud backup frequency: Daily or Weekly. The app checks on app open/resume and triggers a backup if the interval has elapsed.

**Consequences:**
- Automatic backup does not rely on OS background execution; it triggers on app open.
- User receives an in-app notification if automatic backup fails.
- Automatic backup retention: last 7 Backup Files kept per Cloud Provider; older files deleted. [ASSUMPTION: 7-backup retention is fixed in MVP; not user-configurable]

---

### 4.13 Import & Export

**Description:** Jotno supports data portability. The PDF health summary is the most user-facing export — it is what a user hands to a doctor. CSV and JSON exports serve data migration and analysis. All import operations are transactional: all-or-nothing.

**Functional Requirements:**

#### FR-54: PDF health summary export

User can generate a PDF health summary for one Member. The PDF includes: name, age, blood group, Allergies (Severe highlighted), active Conditions, current Medications with dosages, upcoming Appointments, Vaccination record, recent Measurements with trend values, recent Lab Report results, and Emergency Contacts. PDF is generated in the app's active language (Bangla or English). Realizes UJ-3.

**Consequences:**
- PDF is generated locally; no network call.
- PDF is shared via the device share sheet (WhatsApp, email, save to files, etc.).
- PDF is paginated automatically, and each page carries the Member's name and the generation date so loose pages remain identifiable.
- User can preview the PDF before sharing.

#### FR-55: Family Health Report export

User can generate a single PDF covering **all** Members of the Family, with one section per Member in the same shape as FR-54, preceded by a Family summary page. Useful when the whole household attends the same clinic or when handing records to a new family physician.

**Consequences:**
- User can select which Members to include rather than always all.
- Same share-sheet delivery as FR-54.

#### FR-56: CSV export

User can export Measurements, Medications, Medication Logs, Appointments, Vaccinations, Medical History, and Lab Results as CSV. Export scope is selectable: one Member or the whole Family.

**Consequences:**
- CSV uses UTF-8 with BOM so Bangla text opens correctly in Excel.
- When scope is the whole Family, a Member column identifies each row's owner.
- Exported via the device share sheet.

#### FR-57: JSON export

User can export a Member's full Health Profile, or the entire Family's data, as structured JSON.

**Consequences:**
- The JSON export is complete enough to be re-imported by FR-59 without loss — every field the app stores is represented.
- JSON schema is documented in the addendum. [ASSUMPTION: addendum covers schema; it is not reproduced in this PRD]

#### FR-58: CSV import

User can import Measurements, Medications, Appointments, Vaccinations, or Medical History from a CSV file. Flow: file select → column mapping → preview (first 10 rows) → validate → commit.

**Consequences:**
- Import is a single database transaction: all rows commit or none do. Health data is never partially imported.
- Validation errors are reported per row with a description of the problem, before any data is written.
- Column mapping is user-adjustable; the app proposes a mapping from the header row but does not assume it.
- User chooses the target Member for the import, or maps a Member column when the file spans several.

#### FR-59: JSON import

User can import a Jotno JSON export (FR-57), completing the round trip. The app validates the file against the expected schema before importing.

**Consequences:**
- Import is a single database transaction: all-or-nothing.
- User chooses whether to merge into the existing Family or replace it; replace offers a pre-import backup first.
- A JSON file from a newer app version is refused with a message to update, rather than partially imported.

#### FR-60: Backup File import

User can import from a .hfm Backup File (local or from a Cloud Provider) to restore or migrate data. Same flow and same failure handling as FR-47, FR-48, and FR-52.

---

### 4.14 Bilingual UI

**Description:** Bangla is the primary language of Jotno. The UI defaults to Bangla. The user can switch to English at any time. All user-facing strings, notifications, and PDF exports honour the selected language.

**Functional Requirements:**

#### FR-61: Bangla-default UI

All UI strings present in Bangla on first launch unless the device locale is set to English. [ASSUMPTION: device locale is the only signal for initial language selection; user overrides in Settings]

**Consequences:**
- Language preference persists locally across sessions.
- Language switch applies immediately without an app restart.
- Stored health data is language-neutral (user-entered text is not translated).
- Bangla text entry relies on the device's system keyboard. Jotno does not bundle a Bangla input method. If no Bengali keyboard is installed, the app shows a one-time hint pointing the user to their device's language/keyboard settings.

#### FR-62: English UI option

User can switch the app language to English in Settings. All UI strings, notification text, and PDF health summaries switch to English.

---

## 5. Cross-Cutting NFRs

**Reference dataset.** Every performance requirement below is measured against one standard fixture representing a large, long-lived Family: **10 Members, 20 years of records, 10,000 Measurements, 10,000 Medication Logs, 5,000 Documents, 500 Appointments.** "At reference size" throughout means this dataset.

**Availability**
- **NFR-P1 Offline completeness:** Every feature covered by FR-1 through FR-62 (except FR-50, FR-51, FR-52, FR-53 cloud operations) is fully functional with no internet connection.
- **NFR-P2 Reminder reliability:** Scheduled Medication, Appointment, Vaccination, and standalone reminders are delivered by the OS at their scheduled time whether or not the app is running, subject only to OS-level restrictions outside the app's control (revoked notification permission, OEM battery optimisation). No reminder depends on the user opening the app.

**Performance**
- **NFR-P3 App launch:** App fully interactive within 3 seconds at reference size on a mid-range Android device (2 GB RAM, Android 10+). Cold start, no cache warm-up assumed.
- **NFR-P4 Scroll:** The Health Timeline and Family Health Calendar hold 60 fps while scrolling at reference size, loading windowed pages rather than the full event set.
- **NFR-P5 Search:** Document Vault search returns results within 1 second at reference size.
- **NFR-P6 Chart rendering:** A Measurement trend chart renders within 2 seconds for any time range at reference size, including the 1-year view over 10,000 Measurements.
- **NFR-P7 Adherence computation:** Medication adherence percentage over any selected range computes within 2 seconds against 10,000 Medication Logs.
- **NFR-P8 PDF generation:** A single-Member PDF health summary generates within 10 seconds at reference size. The Family Health Report (FR-55) shows progress and does not block the UI.
- **NFR-P9 Backup and restore:** Backup and restore show accurate progress, are cancellable, and survive the app being backgrounded mid-operation. A backup at reference size completes without the OS terminating the app for unresponsiveness.

**Security and privacy**
- **NFR-S1 Data in logs and diagnostics:** Health data — Member names, Medication names, Condition names, Measurement values, lab values, Document contents — must not appear in debug logs, analytics payloads, or any crash/diagnostic report. This binds regardless of which diagnostic channels ship: OS-level crash reporting (Play Console / Xcode Organizer) is always active and outside the app's control, so no health data may be written to stack traces, exception messages, or breadcrumbs. If a crash-reporting SDK is ever added, it counts as a third external data flow and must be declared in §6, FR-4, and the store Data Safety forms.
- **NFR-S2 Notification privacy:** Medication reminder notifications display Member name and Medication name only. No dosage details, condition context, or lab values appear in notification previews (visible on lock screen to bystanders).
- **NFR-S3 Secure key storage:** Encryption keys and OAuth tokens are stored exclusively in Android Keystore / iOS Secure Enclave. Not in SharedPreferences, NSUserDefaults, or any file readable without elevated access.
- **NFR-S4 Soft deletion:** Deleting a record marks it deleted rather than removing it, protecting data integrity and enabling future sync. Permanent erasure happens only through the two explicit paths in FR-44.

**Accessibility and localisation**
- **NFR-A1 Bangla rendering:** Bangla text renders correctly on all supported Android and iOS versions without layout overflow, clipping, or conjunct-glyph corruption. Bangla strings run longer than their English equivalents; layouts must accommodate that rather than truncate.
- **NFR-A2 Language parity:** Every user-facing string exists in both Bangla and English — including error messages, notification text, permission rationale, the medical disclaimer, and the privacy policy. No screen falls back to English when Bangla is active.

---

## 6. Constraints & Guardrails

### Privacy
- Jotno has no backend server. No health data is ever routed to Jotno infrastructure.
- Cloud backup transfers go directly from the device to the user's own Cloud Provider. Jotno never receives or reads the content.
- AdMob receives device identifiers only (per user consent, FR-3). Health record content is never passed to AdMob as targeting signals, keywords, or custom events.
- **Analytics:** Jotno uses Firebase Analytics, strictly limited to event names and timestamps. The permitted event set is a fixed allowlist defined at build time — no free-form event parameters. No Member names, Medication names, Condition names, Measurement values, Document contents, or any other health data are ever included in an analytics payload. Event names themselves must not encode health content (e.g. `dose_actioned` is permitted; `dose_actioned_metformin` is not). A build-time check or code review gate enforces the allowlist.
- AdMob and Firebase Analytics are the only two external data flows in the app. Both are declared in the privacy policy and the Play Store Data Safety form.

### Medical Safety
- Jotno records what users enter. It does not auto-interpret Measurements against reference ranges, flag clinically abnormal values, or suggest diagnoses.
- The medical disclaimer (FR-2) is displayed at onboarding and accessible from Settings at any time.
- The out-of-range flag in Lab Results (FR-31) is a user-set marker. The app never evaluates reference ranges automatically.
- Vaccination schedules are not pre-loaded or recommended by the app; the user enters all due dates manually.

### Solo Developer Scope
- Architecture must be maintainable by one developer. Features requiring sustained third-party integrations (OCR APIs, AI inference services, drug interaction databases) are explicitly out of MVP scope.

### Store Submission
- **Data Safety / Privacy disclosures:** both stores require declaring that Jotno handles health data. The declaration must state that health data is stored on-device and not transmitted, and separately declare AdMob device identifiers and Firebase Analytics events. Health-category apps may receive additional store review; the submission should assume it.
- **Permission usage descriptions:** every requested permission (camera, photo library, notifications) needs a usage string on iOS. These strings must match the in-app rationale copy (FR-5) and exist in both Bangla and English.
- **Public privacy policy:** the FR-4 policy content must also be reachable at a public URL, since both stores require a linkable privacy policy independent of the app.
- **Account deletion:** Google Play requires a data-deletion path for apps with accounts. Jotno has no accounts and no server-side data; the submission must state this explicitly rather than leave the requirement unanswered. In-app, "delete all data" wipes the local database and attachments and is documented in the privacy policy.

---

## 7. Information Architecture

**Primary navigation (bottom bar):**

| Tab | Content |
|-----|---------|
| **Home (হোম)** | Family overview — Member cards with dashboard summaries |
| **Timeline (টাইমলাইন)** | Health Timeline across all Members (FR-34) |
| **Medications (ওষুধ)** | Today's Medication schedule across all Members |
| **Calendar (ক্যালেন্ডার)** | Family Health Calendar (FR-39) |
| **More (আরও)** | All secondary features |

**More menu contents:** Members, Medical History, Measurements, Lab Reports, Prescriptions, Documents, Doctors, Hospitals, Vaccinations, Reminders, Emergency Contacts, Backup & Sync, Import / Export, Settings.

**Settings:** Language, Theme (Light/Dark), Glucose unit, Auto-lock, App Lock (PIN/Biometric), Rapid emergency access (per Member), Ad preferences, Privacy Policy, Medical Disclaimer, About.

**Emergency access** sits on the Home tab, not in the More menu (FR-37) — an emergency surface buried three levels deep is not an emergency surface.

---

## 8. Monetization

**Free tier:** Full access to all features (FR-1 through FR-62) except cloud backup (FR-50, FR-51, FR-52, FR-53). Supported by AdMob ads with explicit user consent (FR-3). Ads display in lower-traffic screens (Reports, Settings, post-export confirmation). Ads do not display on the Emergency Health Card, Medication reminder screens, or any screen requiring focused user attention.

**Paid IAPs (one-time purchase):**
- **Private Backup (প্রাইভেট ব্যাকআপ):** Unlocks Google Drive, OneDrive, and Dropbox cloud backup, restore, and automatic backup (FR-50, FR-51, FR-52, FR-53).
- **Ad-free (বিজ্ঞাপন মুক্ত):** Removes all AdMob ads.

**Pricing:** [ASSUMPTION: pricing is ≤ BDT 300 one-time for each IAP, consistent with Bangladeshi app market expectations; exact pricing is a go-to-market decision not fixed in this PRD]

**Ad placement guardrails (per §6 Constraints):** Health data content is never used as AdMob targeting signals. Ads are never displayed on Emergency Health Card, Medication reminder, or active data-entry screens.

---

## 9. Non-Goals

Two kinds of boundary, kept apart deliberately. **Identity non-goals** are what Jotno will never become, regardless of version. **Deferrals** are wanted but not in v1; they appear in §10.2.

**Identity — not in v1, not in v5:**

- **Not a medical device.** Jotno does not diagnose, recommend treatment, or provide clinical decision support.
- **Not a telemedicine platform.** No doctor consultations, e-prescribing, or remote clinical services.
- **No automatic clinical interpretation.** Jotno stores Measurements and Lab Results and charts them. It does not evaluate them against reference ranges, flag abnormal values, or colour results good or bad. The out-of-range marker in FR-31 is set by the User, never by the app.
- **No Jotno backend.** There is no Jotno server, database, or API. Health data has nowhere central to go, by construction — this is the product, not an implementation stage.

---

## 10. MVP Scope

### 10.1 In Scope

All features defined in §4 (FR-1 through FR-62) plus the cross-cutting NFRs in §5. See §6 for constraints and §7 for IA.

### 10.1a Deliberate divergences from the original feature specification

Two decisions in this PRD depart from the source feature specification. Both come from the product brief and are deliberate; they are recorded here so downstream readers do not treat them as oversights.

- **Cloud backup moved from MVP-essential to a paid feature.** The source spec listed Google Drive, OneDrive, and Dropbox backup among MVP essentials. Here they sit behind the "Private Backup" IAP (FR-50, FR-51, FR-52, FR-53). Local backup, restore, and full data export (FR-45, FR-47, FR-54–FR-60) remain free, so no user is locked out of their own data — the paid tier buys convenience and off-device durability, not access.
- **The app is not entirely free of outbound traffic.** The source spec described a model with no external data flow. This PRD admits exactly two: AdMob (device identifiers, user-consented, FR-3) and Firebase Analytics (event names and timestamps, FR-4 and §6). Health data flows through neither. This is the deliberate cost of a free tier, and it is disclosed to the user before they agree to it rather than buried.

### 10.2 Out of Scope for MVP

Wanted, but not in v1. Distinct from the identity non-goals in §9, which are permanent.

| Deferred | Why not now |
|---|---|
| Multi-device real-time sync | Highest-value deferral and the hardest. Conflicting edits to health records are dangerous to resolve automatically. Backup and restore cover the transfer case in v1. **The schema must carry stable UUIDs, soft deletes, and per-record modification metadata from day one** so this stays buildable without a migration. |
| Family sharing / multi-device access control | Depends on sync. |
| OCR of prescriptions and lab reports | Third-party dependency and accuracy risk on handwritten Bangla prescriptions. |
| On-device AI assistant, natural-language search | Large scope; unproven value before the record-keeping core is used. |
| Medication database, drug interaction checking | Requires a licensed, maintained clinical data source and moves Jotno toward clinical advice. Revisit only with a real data partner. |
| SMS parsing | Broad permission for narrow benefit; poor fit with the privacy story. |
| Prescription refill quantity tracking | Prescriptions are recorded (FR-19); pill counts and refill-due maths are not. |
| Insurance management | Adjacent to health records but a separate domain. |
| Health expense tracking | Belongs with a finance app, not here. |
| Region-specific vaccination schedule templates | Needs a medically reviewed, maintained source per region (see §6 Medical Safety). Manual entry only in v1. |
| iCloud, WebDAV, NAS, self-hosted backup | Three providers are enough to prove demand. The provider abstraction should make a fourth cheap. |
| CGM / wearable device integration | No demand evidence yet. |
| Advanced analytics, personalised health insights | Edges toward interpretation; see §9. |

---

## 11. Success Metrics

**Primary**
- **SM-1:** 10,000+ installs on Play Store within 6 months of launch. Validates FR-1 through FR-62 (acquisition). Measurement: Google Play Console install count.
- **SM-2:** Medication reminder feature actively used (dose actioned from notification) by ≥40% of weekly-retained users (Day 7+). Validates FR-15, FR-16, FR-17. Measurement: Firebase Analytics `dose_actioned` event, per the analytics constraint in §6 — event name and timestamp only.
- **SM-3:** Play Store rating ≥4.0 stars by Month 3. Validates overall usability and trust.

**Secondary**
- **SM-4:** 2–5% of active users convert to "Private Backup" IAP within 6 months. Validates FR-50/FR-51/FR-52. Measurement: Play Console IAP data.
- **SM-5:** ≥30% of retained users (Day-30 weekly returners) have ≥3 Members in their Family. Validates FR-7 (multi-member family use). Measurement: Firebase Analytics `family_size_bucket` event fired once per session with a coarse bucket value (1, 2, 3-5, 6+) — a count, never Member identities.
- **SM-6:** iOS App Store launch within 3 months of Play Store launch.

**Counter-metrics (do not optimise)**
- **SM-C1:** Do not optimise ad frequency or placement to increase ad revenue at the expense of SM-3 (user rating). An intrusively ad-heavy app will lose the trust that is the product's core differentiator.
- **SM-C2:** Do not increase notification frequency beyond Medication Schedule cadence to drive SM-2. Reminders must be schedule-driven, not engagement-driven.

---

## 12. Resolved Decisions & Open Questions

### Resolved during PRD authoring

- **(OQ-1) Rapid emergency access mechanism** — RESOLVED. FR-38 states the requirement platform-neutrally (Emergency Health Card reachable in ≤3 interactions from a locked device, without app authentication). The delivery mechanism per platform — lock-screen widget, home-screen widget, persistent notification, or Assistant shortcut — is an architecture decision. If a platform offers no qualifying mechanism, the feature ships where it can and Settings explains the gap.
- **(OQ-2) Analytics approach** — RESOLVED. Firebase Analytics with health data strictly excluded, governed by a build-time event allowlist (see §6 Privacy). Only event names and timestamps leave the device.
- **(OQ-3) Backup password recovery** — RESOLVED. A Recovery Phrase mechanism is offered (FR-46), saveable to the user's own Cloud Provider, with an explicit warning when stored alongside the backups it can decrypt.
- **(OQ-4) Bangla input** — RESOLVED. Jotno relies on the device's system keyboard; no bundled input method. A one-time hint points users to device keyboard settings when no Bengali keyboard is present (FR-61).
- **(OQ-5) Play Store Data Safety form** — RESOLVED. Reviewed. The declaration must cover both AdMob device identifiers and Firebase Analytics events, and state that health data is stored on-device only.

### Open

1. **(OQ-6) IAP pricing** — Exact BDT price points for "Private Backup" and "Ad-free" are not fixed. *Owner: tanim-jazz. Revisit before store submission. Not a blocker for UX, architecture, or epics.*
2. **(OQ-7) Recovery Phrase scheme** — The specific wordlist and entropy (BIP-39 12-word vs. alternative) is an architecture decision to be confirmed during the architecture phase. *Owner: architecture phase. Not a blocker for UX or epics.*

---

## 13. Assumptions Index

- **§2.3 UJ-4** — Karim had previously enabled rapid emergency access for his father.
- **§4.1 FR-7** — No hard cap on number of Members per Family in MVP.
- **§4.3 FR-15** — MVP Medication Schedule frequency types: Daily, Specific days of week, Monthly on a date. Irregular/as-needed schedules are post-MVP.
- **§4.3 FR-16** — Notification pre-scheduling horizon is 7 days rolling, bounded by platform limits on pending local notifications.
- **§4.3 FR-17** — Snooze duration is fixed at 15 minutes in MVP.
- **§4.4 FR-23** — Standalone reminder repeat options: none, daily, weekly, monthly.
- **§4.5 FR-25** — Vaccination reminder lead-time options: 0, 1, 3, 7 days before the due date.
- **§4.6 FR-26** — Custom Measurement type supports a name and single numeric value field with a user-defined unit string.
- **§4.6 FR-28** — Blood glucose unit conversion is display-layer only; stored value retains original unit.
- **§4.7 FR-31** — Preset lab test list: CBC, Blood Glucose, HbA1c, Lipid Profile, Creatinine, Liver Function Tests, Thyroid Profile, Vitamin D, Urine Routine Examination.
- **§4.11 FR-41** — PIN failure cooldown: 30 seconds after 5 consecutive failures, doubling per subsequent failure group.
- **§4.12 FR-45** — Backup password KDF: PBKDF2-SHA256 or equivalent; minimum 8 characters.
- **§4.12 FR-46** — Recovery Phrase scheme assumed BIP-39-style 12 words; final scheme confirmed during architecture (OQ-7).
- **§4.12 FR-50** — Google Drive `drive.file` scope is sufficient; full `drive` scope is not requested.
- **§4.12 FR-53** — Automatic backup retention: 7 most recent Backup Files kept per provider; not user-configurable in MVP.
- **§4.13 FR-57** — JSON export schema is documented in an addendum artifact, not this PRD.
- **§4.14 FR-61** — Device locale is the only signal for initial language detection; user overrides in Settings.
- **§5 NFR-P3** — The reference dataset (10 Members, 20 years, 10,000 Measurements, 10,000 Medication Logs, 5,000 Documents, 500 Appointments) represents a realistic upper bound for a long-lived Family, drawn from the source technical plan's performance targets.
- **§8** — IAP pricing ≤ BDT 300 per item; exact pricing is a go-to-market decision (OQ-6).
