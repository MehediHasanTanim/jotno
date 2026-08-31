# Review: Structure & Prose — Jotno PRD

Target: `_bmad-output/planning-artifacts/prds/prd-bmad-test-2026-08-29/prd.md` (952 lines)
Lenses: STRUCTURE, PROSE. Findings ranked within each lens, most reader-blocking first.

---

## STRUCTURE

### S-1 (blocking) — Eight broken FR cross-references

The document is heavily cross-referenced, so a wrong number sends the reader to the wrong requirement. Every one of these points at a real FR that is not the one meant:

| Location | Text | Points at | Should be |
|---|---|---|---|
| FR-19 consequence | "linked to the Appointment it came from (FR-21)" | Appointment *reminders* | FR-20 (Appointment management) |
| FR-23 consequence | "appear on the Family Health Calendar (FR-38)" | Rapid emergency access | FR-39 |
| FR-23 consequence | "and the Health Timeline (FR-33)" | Document attachment/vault | FR-34 |
| FR-29 consequence | "included in the PDF health summary (FR-36)" | Emergency Health Card content | FR-53 |
| FR-47 consequence | "does not count toward the app-lock cooldown (FR-40)" | Encrypted local database | FR-41 (PIN lock) |
| FR-48 consequence | "Automatic backup (FR-53) that fails on authentication" | PDF health summary export | FR-52 |
| §7 IA | "Emergency access is reachable from the Home tab in one tap (FR-36)" | Card *content* | FR-37 (card access) |
| §10.1a | "behind the 'Private Backup' IAP (FR-49, FR-50, FR-51, FR-53)" | PDF export | FR-52 |

Note NFR-P1 gets the same set right ("except FR-49, FR-50, FR-51, FR-52"), which confirms the §10.1a and FR-48 instances are typos rather than intent.

### S-2 (blocking) — Duplicate NFR ID, and §5 is out of order

§5 contains **two requirements numbered NFR-P5**: "NFR-P5 Reminder reliability" (line 768) and "NFR-P5 Search performance" (line 772). Downstream artifacts (architecture, stories, test plans) will cite "NFR-P5" ambiguously.

The list is also ordered P1, **P5**, P2, P3, P4, **P5**, P6, P7, P8, P9, then S1–S4, then A1. Renumber the reminder-reliability item (it reads like a late insertion) and sort. Consider `#### Performance` / `#### Security` / `#### Accessibility` subheads — §5 currently mixes three unrelated concern classes in one flat bullet list.

### S-3 (major) — Three different budgets for the same emergency-access requirement

- FR-37: "in at most **two taps** from the app home screen"
- §7 IA: "reachable from the Home tab in **one tap**"
- FR-38: "in no more than **three interactions**" (from the locked device — a different surface, but the reader has to work that out)

Pick one number per surface and state it once. Also define "interaction" in FR-38 — tap, swipe, and voice invocation are not equivalent, and the requirement is untestable as written.

### S-4 (major) — §9 Non-Goals and §10.2 Out of Scope are near-duplicate lists

Ten of the fourteen §10.2 bullets restate §9 verbatim in substance (multi-device sync, OCR, AI, SMS parsing, refill tracking, insurance, expense tracking, iCloud, family sharing, drug interaction). Only four are new (WebDAV/NAS, region-specific vaccination templates, CGM integration, advanced analytics). §6 "Solo Developer Scope" then states a *third* version of the same exclusions (OCR APIs, AI inference, drug interaction databases).

Fix: keep §9 as the reasoned non-goals with rationale; reduce §10.2 to "See §9, plus:" and the four novel items; delete the §6 bullet's list and cross-reference §9.

### S-5 (major) — "no network call" restated as a per-FR consequence nine times

FR-8, FR-26, FR-29, FR-34, FR-36, FR-39, FR-44, FR-53, FR-54 each carry a "Chart/Card/Calendar loads from local database; no network call" bullet. NFR-P1 already binds this for every FR except the four cloud ones. Nine restatements add no constraint and cost nine lines of maintenance. Delete them; if a specific FR needs the emphasis, cite NFR-P1.

The same pattern applies to "no Jotno server," asserted in §1, §4.12 description, FR-4, FR-49, §6 Privacy, and §9 — six places.

### S-6 (major) — §10.1 In Scope contains no information

> "All features defined in §4 (FR-1 through FR-61) plus the cross-cutting NFRs in §5. See §6 for constraints and §7 for IA."

This is a table of contents wearing a section heading. Cut it and promote §10.1a (the deliberate divergences), which is the only part of §10 that a reader cannot derive from the rest of the document.

### S-7 (major) — Requirements buried in non-requirement sections

- **FR-16 "Out of Scope"** block: "The app surfaces a one-time guidance prompt directing the user to exempt Jotno from battery optimisation" — that is a testable, buildable requirement hidden inside a scope disclaimer, in the *only* FR in the document that has an "Out of Scope" heading. Promote it to a Consequence; move the OEM-limitation caveat to §6 or §9.
- **§6 Store Submission**: "In-app, 'delete all data' wipes the local database and attachments" — a user-facing destructive feature with no FR number, no confirmation flow, and no acceptance criteria, mentioned once in a compliance bullet.
- **NFR-S4** requires that "Hard deletion ... requires a separate explicit user confirmation," but no FR anywhere describes a hard-delete flow. Orphan requirement.

### S-8 (moderate) — Inconsistent depth without a stated reason

- **FR-16 (Medication Engine)**: eight consequences plus a bespoke Out-of-Scope block. **FR-34 (Health Timeline)** and **FR-39 (Family Health Calendar)** each get one FR and three or four bullets — despite both being top-level navigation tabs in §7. A primary tab specified in four lines next to a background service specified in thirty reads as an authoring artifact, not a priority signal.
- **FR-30 (Lab Report entry)** has no Consequences block at all; **FR-31 (Lab Result entry)**, its child, has two. Same for FR-32, FR-37, FR-50, FR-59.
- **FR-27/FR-28** specify Blood Pressure and Blood Glucose field-by-field; the other five MVP Measurement types (Weight, Height, Temperature, Heart Rate, SpO₂) get nothing. §4.6's description says BP and glucose "have dedicated detailed entry forms," which explains the asymmetry — good — but the other five still need a stated default shape (value, unit, date, notes) rather than silence.

### S-9 (moderate) — FR-59 duplicates FR-46 and FR-51

> "FR-59: Backup File import — User can import from a .hfm Backup File (local or from a Cloud Provider) to restore or migrate data. Same flow and same failure handling as FR-46, FR-47, and FR-51."

Every clause of this is already binding via FR-46/47/51. It creates a fourth FR number that stories will be written against for zero new behaviour. Delete it, or reduce it to a pointer note in §4.13's description.

### S-10 (moderate) — Ordering: the Glossary arrives after the text that uses it

§0 states "Vocabulary is defined in §3 Glossary; all FRs, UJs, and SMs use Glossary terms exactly." But §2's four user journeys use Member, Health Profile, Medication Log, Allergy, Emergency Health Card, and Emergency Contact before any of them are defined. Move §3 ahead of §2 (Vision → Glossary → Target User), or at minimum have §2's opening line point forward to it.

Similarly, §7 Information Architecture — the map of the whole product — sits after 650 lines of FRs. A reader who saw the five-tab structure first would understand §4's section boundaries far more easily.

### S-11 (moderate) — Missing connective tissue: monetization is assumed ~700 lines before it is explained

FR-3 tells the reader "Jotno is free and supported by ads" and requires an AdMob consent screen. The free/paid model, the two IAPs, and the ad-placement rules do not appear until §8. Between them, FR-49 through FR-52 are each tagged "(paid IAP)" with no definition of what an IAP is in this product. Either move §8 before §4 or add one sentence to §4.1's description establishing the model.

FR-48 likewise refers to "the Backup & Sync screen" three times before §7 establishes that such a screen exists.

### S-12 (moderate) — "Realizes UJ-n" convention applied inconsistently

§4.1 claims "Realizes UJ-1, UJ-2, UJ-3, UJ-4" — all four, which makes the annotation carry no information. §4.7, §4.10, §4.12, and §4.14 have no Realizes line at all. §4.11 uses the tag for a different purpose entirely: "Realizes cross-cutting NFR-S1 through NFR-S4," which inverts the relationship (a feature does not realize an NFR; the NFR constrains it). Apply the convention consistently or drop it.

### S-13 (moderate) — FR-47's list is mislabelled "Consequences"

FR-47's body ends "The app distinguishes and handles at minimum:" and the list that completes that sentence sits under a **Consequences:** heading. Those six items are the requirement itself, not its consequences. Same structural slip, milder, in FR-19 and FR-45, where the Consequences block carries the substantive rules.

### S-14 (minor) — Implementation detail inside requirements, inconsistently applied

FR-38 explicitly and correctly defers mechanism: "an architecture decision, not a product one." But FR-40 mandates **SQLite**, FR-44 mandates **PBKDF2-SHA256**, FR-49/50 mandate **Microsoft Graph API** and **Dropbox API**, FR-16 mandates the **OS notification scheduler**, and FR-45 assumes **BIP-39**. Two of these are already flagged as assumptions (FR-44, FR-45) and one is an open question (OQ-7) — so the document knows they are architecture calls but states them as product requirements anyway. Pick a stance and apply it.

### S-15 (minor) — Redundancy inside §8 Monetization

The "Free tier" paragraph says ads "do not display on the Emergency Health Card, Medication reminder screens, or any screen requiring focused user attention." Four lines later, "Ad placement guardrails (per §6 Constraints)" says the same thing again, in a section short enough that the reader can see both at once.

### S-16 (minor) — The "addendum" is referenced but never identified

§0: "the technical plan captures the *how* and lives in the addendum." FR-56: "JSON schema is documented in the addendum." No path, filename, or link anywhere — unlike §0's three input documents, which are all given explicit paths. A downstream reader cannot find it.

### S-17 (minor) — "All import operations are transactional" stated three times

§4.13 description, FR-57 consequence, and FR-58 consequence each assert all-or-nothing import. Similarly the Prescription→Medications cardinality is stated in the §3 Glossary, again in FR-19's body, and a third time in FR-19's first consequence.

### S-18 (minor) — Unaddressed tension between FR-35 and FR-45

FR-35 treats the clipboard as a boundary worth naming: "Copying a number to the clipboard is the only path by which contact data leaves the app, and only at explicit user action." FR-45 then offers "copy to clipboard" as one of three destinations for the Recovery Phrase — the credential that decrypts the entire encrypted backup — with no equivalent caution, while carefully warning about the *cloud* storage option. If clipboard export of a phone number merits a sentence, clipboard export of a master decryption key merits at least as much.

### S-19 (minor) — No accessibility requirements beyond Bangla rendering

NFR-A1 is the only A-series NFR and covers font rendering only. FR-11 and FR-36 require "high-contrast" alert styling with no contrast ratio; the Emergency Health Card's whole premise is legibility under stress, possibly by a stranger. No requirement covers dynamic type / font scaling, screen readers, or touch-target size — for an app whose stated users include grandparents.

---

## PROSE

### P-1 (blocking) — §0 asserts a terminology discipline the document does not keep

> "Vocabulary is defined in §3 Glossary; all FRs, UJs, and SMs use Glossary terms exactly."

This is the strongest claim in the document about its own rigour, and it is false in at least six ways. Every instance below is a place where a reader (or a story author) must decide whether a synonym denotes the same thing:

- **"Family Member" / "family member" vs. the defined term `Member`.** §1: "Each **Family Member** has a Health Profile." §2.1: "Never miss a **family member's** medication dose"; "Know every **family member's** blood group and allergies." FR-16 puts it in user-facing copy: "You have N missed doses across M **family members**." FR-34 uses "all **Family Members**." The Glossary term is `Member`, and `Family` is separately defined as the household unit — so "Family Member" reads as a compound of two defined terms that is itself undefined.
- **"Member profile" vs. the defined term `Health Profile`.** UJ-1 entry state: "Father's **Member profile** exists." FR-11: "visible without additional taps on the **Member profile**." FR-7 consequence: "**Member list** is the entry point." §7 Settings: "Rapid emergency access (per Member)." Three surface names, none defined; the Glossary defines `Health Profile` as the data set and says nothing about a profile *screen*.
- **`User` is capitalised throughout §4 as if it were a Glossary term — and is not in the Glossary.** It is also used three different ways, sometimes adjacently: bare ("the first screen **User** sees", FR-1; "**User** can create a Family", FR-6), with an article ("the **User** sets a backup password", FR-45, five times), and lowercase ("a **user**-set backup password", FR-44; "**user**-configurable from 0–7 days", FR-25). Either add `User` to §3 and use one form, or drop the capital.
- **The PDF summary has four names.** "ready health summary" (§2.1), "Export Health Summary" (UJ-3, as a button label), "PDF health summary" (FR-29, FR-53, NFR-P8), "health summary" (FR-53 title, §6). A `Family Health Report` (FR-54) is then introduced as a distinct named artifact. Neither is in the Glossary despite being cited from six sections.
- **Emergency access has five names**: "Rapid emergency access" (FR-38 title, §7 Settings), "rapid-access surface" (FR-36, FR-38, FR-43), "the emergency shortcut" (UJ-4), "A global Emergency shortcut" (FR-37), "Emergency access" (§7 IA). FR-43's consequence — "The rapid emergency access surface (FR-38) operates independently of in-app auto-lock" — uses a sixth variant.
- **Casing drift on defined terms.** "Today's **Medication schedule** across all Members" (§7) and "in the **Medication schedule** view" (FR-14) — `Medication Schedule` is a defined entity, so lowercase-s here is ambiguous between the entity and a screen. Also "**cloud provider** icon" (FR-51) vs. defined `Cloud Provider`; "**emergency contacts**" lowercase in the §3 `Emergency Health Card` entry vs. `Emergency Contact` defined two lines above it.

Given §0's promise, this is the finding most likely to cause downstream damage: epics and stories generated from this PRD will inherit the synonyms as if they were distinct concepts.

### P-2 (major) — The four user journeys share one screenwriting cadence, and it is doing no work

Every UJ ends in the same clipped, empty-parallel register:

- UJ-1: "She is in the daily rhythm. Adherence is tracked, not assumed."
- UJ-2: "He exits. The reading is saved. The trend is visible."
- UJ-3: "No information lost. No time wasted."
- UJ-4: "The card was there when it mattered, and it dialled."

None of these adds a fact the Path bullet did not already state. The **Climax / Resolution** labels are screenplay scaffolding — a PRD journey needs entry state, path, and outcome; "Climax" invites exactly this register. UJ-4's entry state contains "Phone locked, **Karim shaking**," which is melodrama in a structured field, and it is followed immediately by a bracketed assumption tag — two incompatible tones in one line.

Recommend: keep Persona/context, Entry state, Path, Edge case; replace Climax+Resolution with a single "Outcome" stating what the user now has that they did not before.

### P-3 (major) — An unverifiable appeal to authority carries the market claim

§1: "**Academic research confirms this: a 2026 study found** that Bangladeshi users outside Dhaka depend on paper prescriptions and cite data-trust concerns as barriers to digital health adoption."

"A 2026 study" — no author, title, publication, or link, in a document that gives full filesystem paths for its three internal inputs. "Academic research confirms this" is the hollow-authority construction; the sentence would be stronger and more honest as either a cited reference or a plain statement of the team's belief. The next sentence pair — "No app in the current Bangladeshi market handles family health records offline, in Bangla, without a cloud account. **Jotno fills that gap.**" — makes an unsourced competitive claim and then closes with four empty words.

### P-4 (major) — Requirements left undecided by "or"

These read as requirements but cannot be tested, because the document has not chosen:

- **FR-18**: "a **calendar or list** view showing Taken / Skipped / Missed per dose." Which one ships? Both?
- **FR-15 consequence**: "e.g. 8 AM, 2 PM, 8 PM — **three Schedules or one Schedule with three times**." This is a data-model decision punted inside an example, and FR-15's body already says a Schedule has "times of day (**one or more**)", which answers it the other way. The two contradict.
- **FR-44**: "PBKDF2-SHA256 **or equivalent**" — "equivalent" is undefined, which makes the requirement unenforceable in review.
- **NFR-P4**: "scroll **smoothly** at the reference dataset size." Every other NFR-P carries a number (3 seconds, 1 second, 2 seconds, 10 seconds); this one carries an adjective. Give it a frame budget or a dropped-frame threshold.
- **FR-11 / FR-36**: "**high-contrast** visual alert indicator" / "**high-contrast** alert style (bold, distinct background colour)" — no ratio, no token.
- **FR-5**: "a **persistent, dismissible** banner" — persistent and dismissible are in tension; state the re-display rule.

### P-5 (major) — §1 Positioning and §4.11's opening are marketing voice inside a requirements document

- §4.11: "**Security is designed in — not added later.**" Asserts nothing testable and is the kind of line that survives into a spec only because it sounds good. The three sentences after it (encrypted DB, PIN/biometric lock, AdMob is the only outbound flow) already carry the whole meaning.
- §1 Positioning: "Jotno is **not** 'a health tracking app' — that framing **invites comparison with fitness and step-counting apps and undersells what it does**." Positioning is legitimate content, but the register here (bold emphasis, rhetorical negation, a Bengali tagline in a pull-quote) is several notches away from §4–§6 and reads as pitch-deck material spliced into a PRD.
- §7: "an emergency surface buried three levels deep **is not an emergency surface**." Rhetorical flourish; FR-37's tap budget already binds it.
- §10.1a: "the paid tier buys **convenience and off-device durability, not access**" and "it is disclosed to the user before they agree to it **rather than buried**."
- SM-C1: "An **intrusively ad-heavy app will lose the trust that is the product's core differentiator.**" The counter-metric itself is good; the justifying sentence is editorial.
- §4.9 description: "because in an emergency **reading a number is not enough; the user needs to dial it**." FR-35's Call action already states this.
- §4.13 description: "**Jotno supports data portability.** The PDF health summary is the most user-facing export — **it is what a user hands to a doctor.**" Two sentences of framing before the section says anything.

### P-6 (moderate) — Argumentative framing where a definition belongs

FR-19 opens: "A Prescription is a record **in its own right, not merely a file attached to a Medication** — one visit to a doctor typically produces one Prescription listing several Medications."

The reader is being argued with about a point the §3 Glossary already settled ("One Prescription may yield many Medications"), and the first consequence then settles it a third time ("One Prescription links to **many** Medications; one Medication links to at most one Prescription"). Keep the third version — it is the precise one — and cut the rhetorical opener.

Same pattern, milder, in FR-16's bolded "**whether or not Jotno is running, backgrounded, or has been killed by the user or the system**" followed by a consequence that restates it: "A scheduled dose notification fires at its scheduled time even if the app has not been opened for days and is not resident in memory."

### P-7 (moderate) — Sentences that shorten without loss

- §0: "This PRD is the authoritative requirements document for Jotno, addressed to the solo developer and to downstream workflow owners: UX design, architecture, epics, and stories." → "Audience: the solo developer and the UX, architecture, and epic/story workflows."
- FR-1: "On first launch, **the first screen User sees states what Jotno is and its core promise**, in the active language" — "on first launch" and "the first screen" are the same fact twice.
- FR-3: "Following FR-2, and before any AdMob SDK initialisation, User sees a consent screen explaining that Jotno is free and supported by ads, that the ad network (Google AdMob) collects device identifiers for ad serving, and that health records are never shared with it." — one 46-word sentence carrying three separate disclosures; break into a list, as FR-4 already does correctly with its (a)–(g) structure.
- FR-16 consequence: "on every app open, resume, and successful notification delivery, it tops up the OS notification queue so at least the next 7 days of doses are always scheduled" — "always" is doing nothing next to "at least."
- FR-48: "A connected Cloud Provider can become unusable without the user acting — an expired refresh token, a revoked app authorisation, a deleted folder, or a full cloud account. Jotno detects and surfaces these rather than failing silently." The second sentence is the requirement; the first is background that could be halved.
- FR-38 consequence: "The access mechanism is platform-appropriate and is an architecture decision, not a product one — a lock-screen widget, home-screen widget, persistent notification, Siri/Assistant shortcut, or platform equivalent are all acceptable **so long as the requirement below is met**." The trailing clause is redundant with the bolded **Requirement** bullet that immediately follows.
- §2.2: "Users who need multiple people to access the same records on separate devices simultaneously (multi-device sync is post-MVP)" — the parenthetical repeats §9 and §10.2.

### P-8 (moderate) — Tone inconsistency between §2 and §4–§6

§2's journeys use emoji in requirement-adjacent text ("💊 Metformin 500mg — Father"), first names and cities, and dramatic beats. §4 onward is clipped, numbered, and impersonal. §1 is marketing. §12–§13 are administrative. Four registers in one document is survivable, but §2 and §1 are the two that a downstream reader will quote from, and they are the two least aligned with the rest. The journeys are genuinely useful — the fix is register, not deletion.

### P-9 (moderate) — Undefined measurement terms in Success Metrics

- SM-2: "≥40% of **weekly-retained users (Day 7+)**"
- SM-5: "≥30% of **retained users (Day-30 weekly returners)**"

Two different retention definitions, neither defined, both stated parenthetically as if they were self-evident. SM-3 — "Play Store rating ≥4.0 stars by Month 3. **Validates overall usability and trust.**" — is the only SM that does not name the FRs it validates; "overall usability and trust" is not measurable and does not match the pattern the other five establish.

### P-10 (minor) — Inconsistent capitalisation of "Father" as a persona

§2.1 JTBD: "Know at a glance whether **Father** took his evening medicine" — capitalised as a proper noun in a list whose other five bullets are generic ("a family member's", "every family member's"). The capitalised "Father" then recurs as a persona label throughout UJ-1 and UJ-4 ("Father's Member profile", "💊 Metformin 500mg — Father"), where it works. In §2.1 it is a register slip.

### P-11 (minor) — Hollow intensifiers and padding, itemised

- §1: "surfaces critical information **instantly**"
- §4.5: "particularly relevant for children's immunisation courses" (true, but the description's real content is the next sentence)
- FR-5 consequence: "the camera option is **hidden rather than shown broken**" — good instinct, but "shown broken" is not a defined state
- FR-46: "**Restore is atomic.** Existing local data is not touched until the backup has been fully decrypted, verified, and staged. If any stage fails, the device is left exactly as it was before the attempt. **A failed restore never produces a half-populated database.**" Sentences 2–3 define atomic; sentence 4 restates sentences 2–3.
- FR-47 last bullet: "Every failure leaves the existing local data intact" — already established by FR-46's atomicity paragraph.
- §6: "Health-category apps may receive additional store review; **the submission should assume it.**"
- §12 OQ-5: "**RESOLVED. Reviewed.**"

### P-12 (minor) — §12's resolved items restate their FRs at full length

OQ-1 reproduces FR-38's entire requirement, mechanism list, and fallback clause. OQ-3 reproduces FR-45. OQ-4 reproduces FR-60's keyboard consequence. A resolved question needs one line — the decision and the FR that now owns it — not a second copy that can drift from the first.

---

## Counts

- STRUCTURE findings: 19 (S-1 … S-19)
- PROSE findings: 12 (P-1 … P-12)
- Total: 31

## Top priority for a fix pass

1. S-1 — eight broken FR cross-references
2. S-2 — duplicate NFR-P5 ID
3. P-1 — Glossary discipline claimed in §0 but not kept
4. S-3 — one/two/three-tap contradiction on emergency access
5. S-4 / S-5 — the two largest redundancy blocks
6. P-4 — undecided "or" requirements that cannot be tested
7. S-7 — requirements buried in Out-of-Scope and compliance prose
