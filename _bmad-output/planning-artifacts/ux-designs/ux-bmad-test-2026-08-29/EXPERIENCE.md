---
name: Jotno
status: final
created: 2026-08-29
updated: 2026-08-30
sources:
  - ../../prds/prd-bmad-test-2026-08-29/prd.md
  - ./DESIGN.md
---

# Jotno — Experience Spine

Owns how Jotno behaves. `DESIGN.md` owns how it looks; tokens are referenced here as `{colors.critical}`. Where a mock disagrees with either spine, the spine wins.

Composition reference: the published canvas — 37 screens plus two app-icon boards. Working sources in `.working/`.

## Foundation

Single-surface mobile, Android and iOS at parity. No UI system named; platform conventions govern navigation gestures, keyboard, share sheet, and dynamic type.

Three constraints shape every decision below, and each comes from the PRD rather than from taste:

- **Offline is the normal case, not the fallback.** Every surface except the four cloud operations renders from the local database. There is no loading spinner waiting on a network, because there is no network to wait on.
- **The device is the only copy.** No account, no server. That makes destructive actions genuinely destructive and backup a first-class feature rather than a settings afterthought.
- **Jotno records; it does not interpret.** The app never evaluates a measurement, flags a lab value, or recommends a schedule. This is a product boundary with a UI consequence on nearly every records screen.

Bangla is the default language; English is a setting. Both are complete — no screen falls back.

## Information Architecture

Five fixed tabs. No drawer. Sheets stack one level, never two.

| Surface | Reached from | Purpose |
|---|---|---|
| Home | App open | The **family**, not a person — member cards with today's summary |
| Timeline | Tab | Every health event across every member, reverse-chronological |
| Medications | Tab | Today's doses across the whole family, grouped by time |
| Calendar | Tab | Month view of doses, appointments, vaccinations |
| More | Tab | Everything else, grouped: records · contacts · data |
| Member | Home card tap | One person's dashboard, entry to their records |
| Emergency card | Home, one tap · locked device | Critical facts, readable by a stranger |

**Home opens on the family.** Every other health app opens on an individual; Jotno's user is managing three or four people and needs the whole household at a glance.

**Emergency lives on Home, not in More.** An emergency surface three levels deep is not an emergency surface.

**More** groups into: *health records* (members, history, measurements, labs, prescriptions, documents, vaccinations) · *contacts* (doctors & hospitals, emergency contacts) · *data & settings* (backup & sync, import/export, settings).

## Voice and Tone

Microcopy. Brand voice lives in `DESIGN.md.Brand & Style`.

The register is a competent relative explaining something clearly — not a nurse, not a chatbot, never cheerful about health.

| Do | Don't |
|---|---|
| "গতকালের ১টি ডোজ মিস হয়েছে" | "ওহো! আপনি একটি ডোজ মিস করেছেন 😟" |
| "জত্ন একটি রেকর্ড রাখার অ্যাপ" | "আপনার ব্যক্তিগত স্বাস্থ্য সহকারী" |
| "ফাইলটি নষ্ট — খোলা যাচ্ছে না" | "কিছু একটা ভুল হয়েছে" |
| Name the specific thing that failed and what to do. | "Error occurred. Please try again." |
| State a limit plainly: "পাসওয়ার্ড হারালে ব্যাকআপ আর খোলা যাবে না।" | Soften a real risk into reassurance. |
| Plain Bangla; keep the English medical term where that is what people say (ব্লাড প্রেশার, রিপোর্ট). | Sanskritised Bangla nobody uses aloud. |

No exclamation marks. No streaks, congratulation, or encouragement — adherence is not a game. No emoji in product copy.

**Never** phrase anything as clinical judgement: not "আপনার সুগার বেশি", only "৭.৮ mmol/L · খালি পেটে".

## Component Patterns

Behavioural. Visual specs in `DESIGN.md.Components`.

| Component | Use | Behavioural rules |
|---|---|---|
| Member card | Home | Shows the single most urgent fact for that person — a severe allergy, a due vaccination, the next dose. Never a generic summary. |
| Dose card | Medications | Three actions: taken, snooze, skip. Settles into a labelled state on action; the card stays visible so the day's record reads back. |
| Filter chip row | Timeline, records | Single-select, first chip is the broadest option. Selection persists within a session, resets on cold start. |
| Section card | Everywhere | Rows divide with `{colors.border-hairline-soft}`; the card keeps one hairline border. |
| Bottom sheet | Data entry, confirmation | One level. Dismissable by drag or backdrop unless it is a destructive confirmation. |
| Severe-allergy badge | Member, emergency, PDF | Identical treatment in all three places. Sorts above other allergies. Never collapsed behind "see more". |
| Empty section | Records | States the absence in words. **"No known allergies recorded"** — never a blank area, which a stranger reads as "none". |
| Trend chart | Measurements, labs | Plots recorded values with axis and range. Draws no threshold line, no zone shading, no colour judgement. |

## State Patterns

| State | Behaviour |
|---|---|
| Empty | Says what goes here and offers the one action that fills it. Never an illustration with a slogan. |
| Loading | Rare by design — local reads are synchronous. Where it exists (PDF generation, backup, restore) it shows determinate progress, not a spinner. |
| Offline | **Not a state.** No banner, no degraded mode. Only the four cloud operations acknowledge the network, and only when invoked. |
| Missed dose | Amber, in place, retroactively actionable. Never scolds. Bulk review offered when several accumulate. |
| Cloud auth expired | Provider marked disconnected with a Reconnect action; a persistent notice plus one notification. Never silent, never an infinite retry. |
| Backup failure | Names the specific failure — wrong password, corrupted file, missing attachments, interrupted upload, insufficient space, newer schema — and what to do. Existing data always intact. |
| Restore in progress | Atomic. Local data untouched until the backup is decrypted and verified. A failed restore leaves the device exactly as it was. |
| Destructive confirmation | States what will be destroyed **by count**, requires typed or held confirmation, offers a backup first, and says plainly that cloud backups are not affected. |
| Permission denied | Feature degrades visibly with a route to system settings. Notification denial shows a persistent banner on Medications — reminders silently not firing is the worst failure in the product. |

## Interaction Primitives

- **Tap** — primary. Everything is reachable by tap alone.
- **Swipe** — never the only route to an action. Row actions duplicate into an open detail.
- **Long-press** — optional accelerators only.
- **Pull to refresh** — absent. There is nothing to refresh.
- **Back** — Android hardware back and iOS edge swipe both honoured; a sheet closes before the screen behind it.
- **Tap-to-call** — every phone number in the app dials. A number you can read but not call is half a feature.

## Accessibility Floor

Behavioural. Contrast values live in `DESIGN.md`.

- **48px minimum tap target**, everywhere. Dose controls exceed it.
- **Dynamic type honoured to the largest accessibility setting.** Layouts sized to the Bangla measure already carry slack; nothing may truncate at large sizes.
- **Colour is never the sole carrier.** Every state pairs colour with a word or icon — severe allergies say "তীব্র", missed doses say "মিস".
- **Screen reader**: every icon-only control is labelled. The emergency card reads in priority order — name, blood group, allergies, conditions, medications, contacts — because that is the order it matters in.
- **Bangla screen-reader output verified**, not assumed. Bengali TTS coverage is uneven; medication and condition names must be announced intelligibly.
- **Focus visible without colour** — the input focus ring is a weight change as well as a hue change.
- **No timed dismissals** on anything carrying health information.

## Privacy Behaviour

The privacy claim is only as good as its edge cases.

- **Notification previews carry member name and medication name only.** No dose, condition context, or lab value — a lock-screen preview is visible to anyone nearby.
- **The recovery phrase warns at the point of risk**, on the "save to your cloud" row specifically: storing the key beside the lock means one account compromise yields both. The app recommends elsewhere and still permits it.
- **Deleting locally does not touch cloud backups**, and the confirmation says so with a route to manage them.
- **A corrupted backup is shown as corrupted**, greyed and labelled in the restore list. Never silently omitted — a backup that vanishes is worse than one that admits it is broken.
- **Ads never appear** on the emergency card, a medication reminder, or an active data-entry screen. Health content is never an ad targeting signal.
- **First run leads with the promise**, then the disclaimer, then ad consent. Permissions come later, at first use — never in the onboarding flow.

## Key Flows

**UJ-1 · Sumaiya sets up her father's medications.**
Medications → add → names Metformin, 500mg, twice daily, after meal → sets 8:00 and 20:00 → chooses *ask before logging* → saves. The notification-permission sheet appears **here**, at the moment its purpose is obvious, not during onboarding. At 20:00 the reminder fires — member name and medicine only. She taps নিয়েছি. **Climax:** next morning Father's card reads ✓ both doses, and she knows without calling. Missed doses surface amber and stay retroactively actionable.

**UJ-2 · Rafi records his mother's blood pressure.**
Measurements → Mother → blood pressure sheet → 138/88, pulse 76, before medication, right arm, sitting → save. The 3-month chart plots systolic and diastolic. **Climax:** the decline since June is visible as a shape. The chart draws no "normal" band and colours nothing — the reading is the fact, the judgement is the doctor's.

**UJ-3 · Nadia prepares for a paediatrician visit.**
Aryan's profile → export health summary → preview → share to WhatsApp. **Climax:** one page in Bangla — blood group, penicillin allergy in red at the top, active medications with dosages, vaccination record, recent measurements — carrying the same disclaimer the app does. The consultation starts with the doctor already informed.

**UJ-4 · Karim needs the emergency card in the ER.**
Phone locked, Karim shaking. Emergency shortcut from the locked device → Father's card without a PIN. **Climax:** B+, penicillin flagged তীব্র at the top, current medications — read to the nurse in under ten seconds. Then he taps Dr. Ahmed's number and the phone dials. The lock-screen surface exposes this card and nothing else; disabling the setting removes it completely.

## Open Items

1. **Rapid emergency access on iOS** — the requirement is stated platform-neutrally (card in ≤3 actions from a locked device, no app authentication). Mechanism is an architecture decision; if a platform offers none that qualifies, the feature ships where it can and Settings explains the gap. *(PRD FR-38, OQ-1)*
2. **Bangla screen-reader verification** — TalkBack and VoiceOver Bengali coverage needs testing on real devices before the accessibility floor can be called met.
3. **Battery-optimisation prompt wording** — Xiaomi, Oppo, Vivo and Realme suppress scheduled notifications for non-exempted apps. The prompt exists (PRD FR-16); its copy and timing need testing with real users, since it asks them into a system settings screen most have never opened.
