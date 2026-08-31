# Family Health Manager — Detailed Feature Specification

For this app, I would use the same offline-first, local-data architecture as the Hisab app, but with a stronger emphasis on privacy, family profiles, medical records, medications, appointments, and documents.

**Core principle:** The mobile device is the source of truth. There is no application backend and no mandatory account. Google Drive, OneDrive, Dropbox, etc. are optional storage providers for encrypted backup, restore, import/export, and synchronization.

---

## 1. Product Concept

A private family health-management app that lets a household maintain health information for multiple family members in one place.

**Possible family members:**

- Self
- Spouse
- Children
- Parents
- Grandparents
- Other dependents

The app can maintain:

```
Family
   │
   ├── Member 1
   │     ├── Health Profile
   │     ├── Medical History
   │     ├── Medications
   │     ├── Appointments
   │     ├── Vaccinations
   │     ├── Lab Reports
   │     └── Documents
   │
   ├── Member 2
   │     └── ...
   │
   └── Member 3
         └── ...
```

---

## 2. Privacy Model

Because health information is highly sensitive, the app should be designed around:

```
Local-first
User
 ↓
Flutter App
 ↓
Encrypted Local DB
```

There is no:

```
User → Your Backend → Database
```

**Optional cloud:**

```
Local DB
    ↓
Encrypt
    ↓
Google Drive
OneDrive
Dropbox
```

The cloud provider should only receive encrypted application backups/sync data.

---

## 3. Family Management

### Family Profile

Create a household:

**Family Name:** Hasan Family

**Members**

- Tanim
- Wife
- Son
- Mother
- Father

Add Family Member

**Fields:**

- Name
- Nickname
- Profile photo
- Date of birth
- Gender
- Relationship
- Blood group
- Height
- Weight
- Emergency contact
- Notes

---

## 4. Member Dashboard

Each family member gets an individual health dashboard.

**Example:**

**Tanim**

Age: 38  
Blood Group: B+

**Weight:** 72 kg

**Upcoming**

- Medicine — 8:00 PM
- Doctor appointment — Sep 3

**Recent**

- Blood Test — Aug 20
- Blood Pressure — Aug 22

---

## 5. Health Overview

The member dashboard should provide a quick summary of:

- Current medications
- Active conditions
- Allergies
- Blood group
- Recent measurements
- Upcoming appointments
- Vaccinations
- Recent reports
- Health alerts

---

## 6. Medical History

Users can record previous medical events.

**Examples:**

**Medical History**

| Year | Event | Status |
|------|-------|--------|
| 2025 | Appendicitis | Treatment completed |
| 2024 | Dengue | Recovered |
| 2022 | Fracture | Treatment completed |

Each record can contain:

- Condition
- Diagnosis date
- Doctor
- Hospital/clinic
- Treatment
- Notes
- Status
- Related documents

**Statuses:**

- Active
- Resolved
- Chronic
- Under Treatment
- Unknown

---

## 7. Conditions

Maintain currently active conditions.

**Examples:**

- Diabetes
- Hypertension
- Asthma
- Thyroid condition
- Heart condition
- Allergy
- Migraine

Each condition:

- Condition
- Status
- Diagnosed date
- Doctor
- Notes
- Attachments

**Important:** this is record keeping, not diagnosis.

---

## 8. Allergies

Dedicated allergy management.

**Types:**

- Medication
- Food
- Environmental
- Other

**Example:**

**Allergy**

- Penicillin
- Type: Medication
- Severity: Severe
- Reaction: Rash

**Severity:**

- Mild
- Moderate
- Severe
- Unknown

The allergy information should be highly visible on the member profile.

---

## 9. Medications

One of the major features.

Users can record:

- Medicine
- Dosage
- Frequency
- Route
- Start Date
- End Date
- Prescribed By
- Purpose
- Instructions

**Example:**

**Napa**  
500 mg  
1 tablet  
After meal  
Twice daily

Start: Aug 25  
End: Aug 30

---

## 10. Medication Schedule

Create medication reminders.

**Example:**

| Time | Medicine |
|------|----------|
| 08:00 AM | Napa 500mg |
| 02:00 PM | Medicine B |
| 08:00 PM | Napa 500mg |

**Actions:**

- Taken
- Skipped
- Snooze

---

## 11. Medication History

Track adherence.

**Napa**

**Aug 25**

- ✓ 8 AM
- ✓ 8 PM

**Aug 26**

- ✓ 8 AM
- Skipped 8 PM

**Statistics:**

- Taken: 92%
- Skipped: 8%

---

## 12. Prescription Management

Store prescriptions from doctors.

Users can:

- Take photo
- Upload PDF
- Add prescription manually
- Link prescription to medications
- Link prescription to appointment

**Example:**

**Dr. Rahman**  
Aug 25, 2026

[Prescription Image]

**Medicines:**

- Napa
- Medicine B
- Medicine C

---

## 13. Doctor Management

Create a doctor directory.

**Fields:**

- Doctor name
- Specialty
- Hospital/clinic
- Phone
- Address
- Chamber information
- Notes

**Example:**

**Dr. Ahmed**  
Cardiologist

Popular Diagnostic Center

Phone: 01XXXXXXXXX

---

## 14. Hospital / Clinic Management

Maintain frequently used healthcare providers.

- Hospital
- Clinic
- Diagnostic Center
- Pharmacy

**Store:**

- Name
- Address
- Phone
- Website
- Notes

---

## 15. Appointments

Create appointments for family members.

**Appointment**

- Member: Father
- Doctor: Dr. Ahmed
- Date: Sep 3, 2026
- Time: 5:30 PM
- Location: Popular Diagnostic Center

---

## 16. Appointment Reminders

**Reminder options:**

- 1 day before
- 3 hours before
- 1 hour before
- 30 minutes before

**After appointment:**

- Completed
- Cancelled
- Rescheduled
- Missed

---

## 17. Appointment Notes

After visiting a doctor:

**Doctor Notes**

- Blood pressure improved.
- Continue current medication.
- Follow-up after 1 month.

Attachments can be linked.

---

## 18. Vaccination Management

Especially useful for children.

**Track:**

- Vaccine
- Dose
- Date
- Provider
- Batch number
- Next dose
- Notes

**Example:**

**Child Vaccination**

- BCG — ✓ Completed
- Hepatitis B — ✓ Dose 1, ✓ Dose 2, ○ Dose 3

---

## 19. Vaccination Schedule

The app can provide configurable vaccination schedules.

**Important design decision:**

Do not hard-code medical recommendations into the application without maintaining a medically reviewed source.

Instead, MVP can provide:

- Manual vaccine schedules
- Custom reminders
- User-entered due dates

Later, region-specific schedules can be introduced.

---

## 20. Health Measurements

Track common measurements.

**Vital Signs**

- Blood pressure
- Heart rate
- Temperature
- SpO₂
- Respiratory rate

**Body Measurements**

- Weight
- Height
- BMI
- Waist circumference

**Example:**

**Blood Pressure**

| Date | Reading |
|------|---------|
| Aug 20 | 120 / 80 |
| Aug 23 | 124 / 82 |
| Aug 26 | 118 / 79 |

---

## 21. Measurement Charts

Display trends.

```
Weight

72kg ─────╮
          │
71kg ──╮  │
       │  │
70kg ──╰──╯
```

**Useful views:**

- 7 days
- 30 days
- 3 months
- 6 months
- 1 year

---

## 22. Blood Pressure Tracking

Dedicated interface:

**Blood Pressure**

- Systolic: 120
- Diastolic: 80
- Pulse: 72
- Date: 26 Aug 2026
- Time: 8:30 AM

**Additional fields:**

- Before/after meal
- Before/after medication
- Arm
- Position
- Notes

---

## 23. Blood Glucose Tracking

For users who want diabetes monitoring.

**Fields:**

- Glucose: 5.8 mmol/L
- Measurement: Fasting
- Date
- Time
- Notes

**Measurement types:**

- Fasting
- Before meal
- After meal
- Random
- Bedtime

Use configurable units:

- mmol/L
- mg/dL

---

## 24. Lab Reports

Store laboratory results.

**Example:**

**Blood Test** — Aug 25, 2026

| Test | Result |
|------|--------|
| Hemoglobin | 13.8 g/dL |
| WBC | 7,200 |
| Platelets | 250,000 |

The app should support:

- Manual entry
- PDF
- Image
- Document attachment

---

## 25. Lab Test Catalog

**Common tests:**

- CBC
- Blood glucose
- HbA1c
- Lipid profile
- Creatinine
- Liver function
- Thyroid profile
- Vitamin D
- Urine test

Users can also create custom tests.

---

## 26. Lab Result History

**Example:**

**HbA1c**

| Date | Result |
|------|--------|
| Jan 2026 | 6.2 |
| Apr 2026 | 6.0 |
| Aug 2026 | 5.8 |

Display a trend graph.

The app should distinguish between:

- Displaying recorded results
- Providing medical interpretation

The former should be part of the MVP; automated medical interpretation should be handled cautiously and separately.

---

## 27. Medical Documents

A central document vault.

**Store:**

- Prescriptions
- Lab reports
- X-rays
- CT scans
- MRI reports
- Discharge summaries
- Medical certificates
- Insurance documents
- Vaccination cards

---

## 28. Document Categories

- Prescriptions
- Lab Reports
- Imaging
- Hospital Records
- Insurance
- Vaccination
- Other

---

## 29. Document Search

**Search:**

- CBC
- Dr. Ahmed
- 2026
- Dengue
- Prescription

**Filter by:**

- Member
- Document type
- Date
- Doctor
- Hospital

---

## 30. Health Timeline

One of the best features for the app.

Everything appears chronologically.

| Date | Event |
|------|-------|
| 26 Aug | Medicine taken |
| 25 Aug | Blood test |
| 25 Aug | Doctor appointment |
| 24 Aug | Prescription added |
| 20 Aug | Blood pressure recorded |

The timeline can be filtered by:

- All
- Medication
- Appointments
- Reports
- Measurements
- Vaccinations

---

## 31. Emergency Health Card

This should be accessible quickly.

**Example:**

🚨 **Emergency Health Card**

**Tanim**

- Blood Group: B+
- Allergies: Penicillin
- Conditions: None
- Current Medications: ...
- Emergency Contact: 01XXXXXXXXX
- Doctor: Dr. Ahmed

Potentially allow display even when the app is locked, only if the user explicitly enables this feature.

---

## 32. Emergency Contacts

**Store:**

- Family emergency contact
- Doctor
- Hospital
- Ambulance
- Insurance contact

**Quick actions:**

- Call
- SMS
- Copy

---

## 33. Health Insurance

Optional MVP or Phase 2 feature.

**Store:**

- Insurance provider
- Policy number
- Member ID
- Expiry date
- Coverage
- Contact information
- Policy document

---

## 34. Medical Expenses

Since the app is separate from Hisab, I would keep health expenses relatively simple.

**Record:**

| Category | Amount |
|----------|--------|
| Doctor | ৳1,000 |
| Medicine | ৳850 |
| Lab Test | ৳2,500 |
| Hospital | ৳10,000 |

**Categorize:**

- Doctor
- Medicine
- Diagnostic
- Hospital
- Dental
- Insurance
- Other

---

## 35. Family Health Calendar

A single calendar showing:

| Date | Event |
|------|-------|
| Aug 27 | Medicine |
| Aug 29 | Blood test |
| Sep 3 | Doctor appointment |
| Sep 10 | Vaccination |

Filter by family member.

---

## 36. Reminders

**Reminder types:**

- Medication
- Appointment
- Vaccination
- Lab test
- Health measurement
- Follow-up
- Insurance expiry
- Prescription refill

---

## 37. Prescription Refill Reminder

**Example:**

**Napa**

- 30 tablets
- Remaining: 6
- Refill reminder: 2 days

This can be calculated locally based on medication schedule.

---

## 38. Family Member Permissions

Since there is no backend, permissions are device-level, not server-level.

**Possible local profiles:**

- Owner
- Adult
- Child
- Dependent

However, true multi-user access control across devices requires a more sophisticated synchronization/security system.

**For MVP:**

One app installation = one private family database.

---

## 39. Data Import

**Support:**

- Application backup (`.hfm`)
- CSV — for measurements, medications, appointments, medical history
- JSON — for structured migration

---

## 40. Data Export

Users can export:

- Individual member (e.g. Father → Export Health Record)
- Entire family (Family Health Report)

**Formats:**

- PDF
- CSV
- JSON
- Encrypted backup

---

## 41. Doctor Visit Report

Very useful feature.

Generate:

**Health Summary**

- Patient: Father
- Age: 67
- Blood Group: B+
- Active Conditions: ...
- Current Medications: ...
- Recent Measurements: ...
- Recent Lab Results: ...
- Allergies: ...
- Recent Medical History: ...

Then: **Export PDF**

This can be shown to a doctor during a visit.

---

## 42. Cloud Backup

**Cloud providers:**

- Google Drive
- OneDrive
- Dropbox

**Architecture:**

```
Local DB
   ↓
Backup Engine
   ↓
Encrypt
   ↓
Cloud Provider
```

The app itself has no cloud database.

---

## 43. Backup UI

**Backup & Sync**

Google Drive — Connected ✓

Last Backup — Today 10:30 AM

**[Backup Now]**

Automatic Backup — ON

Frequency — Daily

---

## 44. Restore

**Available Backups**

| Date | Size |
|------|------|
| 26 Aug 2026 | 15.2 MB |
| 25 Aug 2026 | 14.8 MB |
| 24 Aug 2026 | 14.2 MB |

**[Restore]**

Before restore:

> Your existing local data may be replaced or merged. Create a backup before continuing.

---

## 45. Sync

For MVP, I recommend:

**Backup/Restore first**

```
Phone
 ↓
Cloud

and:

Cloud
 ↓
Phone
```

**Advanced**

True multi-device sync:

```
Phone A
   ↕
Google Drive
   ↕
Phone B
```

This should be Phase 2 because health data conflicts can be dangerous.

---

## 46. Sync Conflict Handling

**Example:**

**Blood Pressure**

- Device A: 120/80
- Device B: 125/82

Never silently overwrite.

Show:

**Conflict Detected**

- Device A — 120/80
- Device B — 125/82

**[Keep A]** **[Keep B]** **[Keep Both]**

---

## 47. Local Database

**Recommended:** Drift + SQLite

**Core tables:**

- `family_members`
- `medical_conditions`
- `allergies`
- `medications`
- `medication_schedules`
- `medication_logs`
- `doctors`
- `hospitals`
- `appointments`
- `vaccinations`
- `measurements`
- `lab_reports`
- `lab_results`
- `medical_documents`
- `medical_history`
- `emergency_contacts`
- `insurance_policies`
- `health_expenses`
- `reminders`
- `attachments`
- `settings`
- `sync_metadata`

---

## 48. Suggested Data Relationships

```
FamilyMember
     │
     ├── Conditions
     ├── Allergies
     ├── Medications
     │      └── Medication Logs
     ├── Appointments
     ├── Vaccinations
     ├── Measurements
     ├── Lab Reports
     │      └── Lab Results
     ├── Medical History
     ├── Documents
     └── Health Expenses
```

---

## 49. Security

This application should have stronger security than a normal productivity app.

**MVP**

- Encrypted local database
- Secure key storage
- Encrypted cloud backups
- PIN
- Biometrics
- Automatic app lock
- Secure deletion

**Advanced**

- Per-member access control
- Encrypted attachments
- Backup password
- Encryption key rotation
- Audit trail

---

## 50. No Backend Means No Account

**First launch:**

Welcome to Family Health

Your health information stays on this device.

**[Create Family]**

No:

- Email
- Password
- OTP
- Registration

unless the user voluntarily connects a cloud provider.

---

## 51. Cloud Authentication

For Google Drive:

```
App
 ↓
Google OAuth
 ↓
User grants permission
 ↓
Encrypted backup
 ↓
Drive
```

Same principle for:

- Microsoft OneDrive
- Dropbox

OAuth credentials/tokens should be stored using platform secure storage.

---

## 52. Recommended Flutter Architecture

```
lib/
│
├── app/
│
├── core/
│   ├── database/
│   ├── encryption/
│   ├── storage/
│   ├── backup/
│   ├── sync/
│   ├── notifications/
│   └── security/
│
├── features/
│   ├── family/
│   ├── health_profile/
│   ├── medical_history/
│   ├── medications/
│   ├── appointments/
│   ├── vaccinations/
│   ├── measurements/
│   ├── lab_reports/
│   ├── documents/
│   ├── timeline/
│   ├── emergency/
│   ├── insurance/
│   ├── health_expenses/
│   ├── backup_sync/
│   └── settings/
│
└── main.dart
```

---

## 53. Recommended Navigation

I would use:

**Home** | **Timeline** | **Medications** | **Calendar** | **More**

**Home**

Family overview.

**Timeline**

All health events.

**Medications**

Medication schedules and adherence.

**Calendar**

Appointments, medicines, vaccinations and reminders.

**More**

- Members
- Medical History
- Measurements
- Lab Reports
- Documents
- Doctors
- Hospitals
- Insurance
- Health Expenses
- Backup & Sync
- Settings

---

## 54. MVP Feature Set

For a realistic first release, I would not build everything above.

**MVP — Essential**

- ✓ Family members
- ✓ Health profiles
- ✓ Medical history
- ✓ Conditions
- ✓ Allergies
- ✓ Medications
- ✓ Medication reminders
- ✓ Medication history
- ✓ Doctors
- ✓ Appointments
- ✓ Appointment reminders
- ✓ Vaccinations
- ✓ Basic measurements
- ✓ Lab reports
- ✓ Medical documents
- ✓ Health timeline
- ✓ Emergency health card
- ✓ Local SQLite database
- ✓ Offline operation
- ✓ Local encryption
- ✓ PIN/Biometric lock
- ✓ PDF export
- ✓ JSON/CSV export
- ✓ Encrypted backup
- ✓ Google Drive backup
- ✓ OneDrive backup
- ✓ Dropbox backup

---

## 55. Advanced Features

**Phase 2**

- ○ Advanced health charts
- ○ Blood glucose tracking
- ○ Detailed BP tracking
- ○ Prescription refill tracking
- ○ Insurance
- ○ Health expenses
- ○ Doctor visit summary
- ○ Advanced document search
- ○ Automatic cloud backup
- ○ Backup versioning
- ○ Multi-device sync

**Phase 3**

- ○ OCR prescription scanning
- ○ OCR medical report scanning
- ○ Smart document classification
- ○ SMS health/payment integration where appropriate
- ○ On-device AI assistant
- ○ Natural-language health record search
- ○ Medication interaction information
- ○ Personalized health insights

For medical AI features, I would keep the initial implementation firmly in the information-management/record-retrieval space rather than diagnosis or treatment recommendations.

---

## 56. Recommended Product Positioning

The strongest positioning isn't:

> "A health tracking app."

It is:

> "Your family's private digital health record."

The core value proposition becomes:

```
All family health information
        ↓
One private app
        ↓
Stored on your phone
        ↓
Available offline
        ↓
Backed up to your own cloud
```

This gives the app a very clear differentiation from cloud-based health platforms.

### Potential Bangladeshi positioning

**Family Health Manager**

পরিবারের সব স্বাস্থ্য তথ্য, এক জায়গায়।

or:

আপনার পরিবারের স্বাস্থ্য তথ্য, আপনার কাছেই।

The second one particularly reinforces the local-first/private-data philosophy.
