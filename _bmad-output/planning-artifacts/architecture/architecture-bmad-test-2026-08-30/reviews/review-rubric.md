# Rubric Review — ARCHITECTURE-SPINE.md (Jotno)

- **Target:** `../ARCHITECTURE-SPINE.md` (314 lines, 20 ADs, status `final`)
- **Driving spec:** `../../../prds/prd-bmad-test-2026-08-29/prd.md` (FR-1..FR-62, NFR-P1..P9, S1..S4, A1..A2)
- **UX spines:** `../../../ux-designs/ux-bmad-test-2026-08-29/{DESIGN.md,EXPERIENCE.md}`
- **Reviewed:** 2026-08-30 · rubric walk, 7 checks
- **Severity key:** BLOCKER (build cannot start from this safely) · MAJOR (will produce divergence) · MINOR (tidy-up)

---

## 1. Mechanical

**PASS — AD id integrity.** AD-1..AD-20 at lines 48–166, contiguous, no duplicates, no gaps. All 20 carry `Binds`, `Prevents` and `Rule` (verified by count: 20/20/20). No TODO/TBD/lorem placeholder text anywhere; the `[ASSUMPTION]` at line 313 is legitimate Open-Question marking.

**PASS — mermaid.** All three blocks parse. Validated with `mermaid@11.parse()` under jsdom:
- lines 34–42 `graph TD` — OK
- lines 235–256 `erDiagram` — OK
- lines 260–272 `graph TD` — OK

### M-1 · MAJOR · Stack — five unpinned versions, plus three soft pins
Line 188 claims "Verified current at 2026-08-30", which is provenance, not a pin. Unpinned rows:
- L197 `go_router | current stable`
- L198 `freezed + json_serializable | current stable`
- L201 `workmanager | current stable`
- L204 `msal_auth | current stable`
- L205 `dropbox_client | current stable`

Soft pins that will drift: L196 `Dart | bundled with Flutter 3.47`, L206 `compileSdk / targetSdk | 35+ / 34+` (a floor, not a target), L208 `AGP | 8.11.1+`. Note `go_router` and `workmanager` are unpinned *and* load-bearing — go_router is the only routing mechanism in the document (see S-3) and workmanager is AD-8 tier 2.

### M-2 · MAJOR · Stack omits packages the ADs mandate
The Stack table (190–208) is missing every dependency required by its own invariants:
- no `timezone` package, yet AD-15 (L136) requires IANA timezone ids
- no `uuid` / UUIDv7 source, yet AD-4 (L70) requires client-generated UUIDv7
- no `intl` / `flutter_localizations`, yet AD-18 (L154) requires ARB files and a Bengali-numeral formatter
- no `drift_dev` / `build_runner`, yet AD-17 (L148) requires `drift_dev make-migrations` in CI
- no `path_provider`, yet AD-12 (L118) requires `AttachmentStore` to construct filesystem paths
- no `local_auth` (FR-42 biometric), no `in_app_purchase` (AD-19 entitlement), no KDF/crypto package (FR-45 requires PBKDF2-SHA256)
- L203 `googleapis + google_sign_in | 7.2.0` — one version for two packages; `googleapis` is unversioned.

### M-3 · MINOR · Inconsistent AD status marker
AD-1 (L48) alone carries `[ADOPTED]`. The other 19 carry no status. Either all ADs have lifecycle state or none do; as it stands a reader reasonably asks what AD-2..AD-20 are, if not adopted.

### M-4 · MINOR · Dangling source reference
Frontmatter L16 lists `../../../../family-health-manager/docs/plan/technical_implementation_plan.md` as a source. That path does not exist on disk (`/Users/tanim/WorkSpace/Personal/VibeCoding/family-health-manager/...` — not found). Provenance for the Stack pins and the discontinued-package claims in AD-2 is therefore unverifiable from the artifact.

### M-5 · MINOR · Structural seed and Capability Map disagree
- Seed L229 declares `features/calendar`; the Capability Map (279–294) has no calendar row (see C-1).
- Map L294 and AD-19 (L160) reference an "ads module"; no ads directory appears anywhere in the seed (215–233). `core/entitlement/` exists, the ads module does not.

### M-6 · MINOR · Dead convention
Conventions L179 `Money | Minor units as int, never double`. Jotno has no money domain — IAP prices come formatted from the store SDK. A convention with no referent invites someone to invent one.

---

## 2. Enforceability of Rules

**PASS — the model cases.** Five ADs name a concrete, runnable gate and are exemplary: AD-10 (L106) "A test asserts the builder's public surface"; AD-11 (L112) "A CI grep gate fails the build on direct logging calls in `features/`"; AD-17 (L148) migration tests for every version pair, mandatory, in CI; AD-2 (L58) "An integration test asserts the same on a release build"; AD-18 (L154) "A CI check fails on a key present in one locale and missing in the other". These are the standard the rest should be held to.

Also cleanly checkable by inspection or grep: AD-4 (column list, no hard delete), AD-5 (one writer per entity), AD-6 (no DAO call outside `data/`), AD-9 (`SCHEDULE_EXACT_ALARM` present, `USE_EXACT_ALARM` absent), AD-12 (no BLOB column), AD-13 (no provider type name outside its impl file), AD-14 (checksum before decrypt), AD-15 (UTC storage, local+tz for schedules), AD-19 (`EntitlementService` is the only reader of purchase state).

### E-1 · MAJOR · AD-3 (L64) — the headline rule is an aspiration, not a check
> "The database encryption key lives in platform secure storage, but **no code may assume it survives**."

A reviewer cannot check code against "assume". There is no grep, no test, no structural signature for an assumption. The two concrete sub-clauses *are* checkable (`FlutterSecureStorage.xml` excluded from Android auto-backup; a restore-from-backup path exists), but they are subordinate clauses inside a rule whose main verb is unenforceable — and the AD's whole Prevents rides on the unenforceable half. See P-1.

### E-2 · MINOR · AD-8 (L94) — "at risk" and "never a daily nag" are undefined
> "The anchor is conditional on coverage being at risk, never a daily nag."

No threshold. Is coverage at risk below 7 days? 3? 24 hours? Two implementers pick two numbers and the feature behaves differently across builds. The anchor's *placement* is precise ("projected exhaustion minus 24h"); its *trigger condition* is not. Also note the AD title — "and the last one is honest" — is rhetoric, not a rule.

### E-3 · MINOR · AD-16 (L142) — "One notifier per screen-level concern"
"Screen-level concern" is undefined and a reviewer cannot adjudicate a disagreement about it. The rest of AD-16 is enforceable (no `riverpod_generator` in pubspec; widgets never call repositories).

### E-4 · MINOR · AD-20 (L166) — "No core path awaits a network call"
"Core path" is undefined. The other half of the rule — "the app must pass its test suite with all four no-ops installed" — is one of the strongest gates in the document, which makes the vague half unnecessary; it should be restated as a lint/grep on `await` against the network-facing interfaces.

### E-5 · MINOR · AD-13 (L124) — a claim dressed as a rule
"Adding a fourth provider touches two files" is a prediction about a future change, not something a reviewer checks against present code. Harmless, but it dilutes the enforceable clause immediately before it.

---

## 3. Does the Rule prevent the stated divergence?

### P-1 · BLOCKER · AD-3 (L60–64) — the Rule does not prevent the loss it names
- **Prevents:** "permanent data loss when Android Keystore drops a key on restore, uninstall or OS update"
- **Rule's remedy:** "the app offers restore-from-backup using the backup password or recovery phrase"

The remedy presupposes a backup exists. PRD FR-45 (local backup) and FR-46 (Recovery Phrase) are both **user-optional**, and nothing in the spine — no AD, no convention — forces either at first-run or at any point. For the user who never made a backup, a dropped Keystore key means total, irreversible loss of every health record in the app, and AD-3's Rule does exactly nothing. The AD names the highest-consequence failure in the product and then answers it with a path the user may never have taken.

The missing invariant is the one that would connect them: *no health record is written until a recovery root exists* — a forced recovery-phrase capture (or equivalent) as a precondition of first write. That is an architectural invariant, not a UX flow, because every feature that writes depends on it.

### P-2 · MAJOR · AD-8 (L90–94) — tier 3 fails in exactly the cases tier 3 exists for
- **Prevents:** "reminders stopping without the user ever knowing"
- **Rule:** the third tier is a "coverage anchor" — *an OS notification*.

The anchor is drawn from the same notification queue whose exhaustion it is announcing, and it is suppressed by the same conditions AD-9 exists to fight: revoked notification permission (FR-16 explicitly contemplates this), and OEM battery-optimisation kill on Xiaomi/Oppo/Vivo/Realme. In the failure modes that actually produce silent reminder loss, the anchor is silent too. The only non-notification channel offered is "Settings shows current projected coverage in days" (L94) — which requires the user to already suspect the problem and go looking.

AD-8 is a good design for queue *exhaustion*. It is not a design for reminders stopping, which is what its Prevents claims.

### P-3 · MAJOR · AD-12 (L114–118) — orphans are prevented only in the rare path
- **Prevents:** "a multi-gigabyte SQLite file **and orphaned files after delete**"
- **Rule:** "Deleting an owning record soft-deletes the row; file removal happens only in the permanent-erasure path"

The BLOB half of the Prevents is fully answered. The orphan half is not. Under AD-4, ordinary record deletion is a soft delete — so in the normal case the file is *never* removed and storage grows monotonically for the life of the install. The permanent-erasure path (FR-44) is user-invoked and rare. Worse, "driven by `AttachmentStore` reconciling against the DB" names no trigger, no schedule and no owner — there is no answer to *when* reconciliation runs, so two implementers will answer differently or not at all. With FR-33's 5,000-document reference dataset this is a real device-storage problem, not a theoretical one.

### P-4 · MINOR · AD-13 (L120–124) — the interface omits the thing that leaks
- **Prevents:** "Drive-specific **auth** or path logic spreading through the codebase"
- **Rule's interface:** `connect · disconnect · upload · download · list · delete · metadata`

Path logic is covered. Auth is not: there is no token-storage, token-refresh, or expiry contract on the interface, yet NFR-S3 requires OAuth tokens in Keystore/Secure Enclave and FR-49 requires disconnect to delete the stored token and requires auth failures to be reported distinctly from quota and network failures. Token handling is precisely the Drive-specific logic that will spread, and the interface that claims to contain it says nothing about it. See S-8.

### P-5 · MINOR · AD-4 (L66–70) — necessary but not sufficient for its Prevents
- **Prevents:** "a schema migration later blocking multi-device sync"

`id / created_at / updated_at / deleted_at / device_id` is the right start, but a sync engine also needs a per-row revision or version vector to detect concurrent edits — and PRD §10.2 (cited at L301) requires that health-record conflicts *never auto-resolve silently*, which is undecidable from timestamps alone across devices with skewed clocks. Adding a revision column later is precisely the migration AD-4 exists to avoid. Cheap to fix now, expensive to fix at that point.

---

## 4. Coverage of the PRD

### C-1 · BLOCKER · The Capability → Architecture Map is off by one for FR-6..FR-39
The map (L279–294) states FR ranges with capability labels. Checked against the PRD's actual FR numbering, the labels drift by one requirement from FR-9 onward and re-converge at FR-40. Numerically the ranges are contiguous, so no FR is *unnumbered* — but four capabilities are filed in the wrong feature directory:

| Map row | Map's claim | PRD's actual FR |
|---|---|---|
| L281 `FR-7..FR-9 family & members` | FR-9 is a member concern | **FR-9 is Medical History records** (→ `medical_records`) |
| L282 `FR-10..FR-14 → medical_records` | FR-14 is a record | **FR-14 is Medication records** (→ `medications`) |
| L283 `FR-15..FR-20 → medications` | FR-20 is a medication | **FR-20 is Appointment management** (→ `appointments`) |
| L284 `FR-21..FR-24 → appointments, reminders` | FR-24 is an appointment | **FR-24 is Vaccination records** (→ `vaccinations`) |
| L285 `FR-25..FR-26 → vaccinations` | FR-26 is a vaccination | **FR-26 is Measurement recording** (→ `measurements`) |
| L286 `FR-27..FR-30 → measurements` | FR-30 is a measurement | **FR-30 is Lab Report entry** (→ `lab_reports`) |
| L287 `FR-31..FR-34 → lab_reports, documents` | FR-34 is a document | **FR-34 is the Health Timeline** (→ `timeline`) |
| L288 `FR-35 timeline` | FR-35 is the timeline | **FR-35 is Emergency Contacts** (→ `emergency`) |
| L289 `FR-36..FR-39 emergency card, contacts, rapid access` | FR-39 is emergency | **FR-39 is the Family Health Calendar** (→ `calendar`) |

**The consequence that matters: the Family Health Calendar has no home.** FR-39 is swallowed by the emergency row, `features/calendar` sits in the structural seed (L229) mapped to nothing, and **NFR-P4 — which names the Calendar explicitly ("The Health Timeline and Family Health Calendar hold 60 fps while scrolling ... loading windowed pages rather than the full event set") — attaches to no capability and no AD.** The Health Timeline is likewise filed under "labs, documents, vault".

FR-40..FR-62 (rows L290–293) are correctly mapped.

### C-2 · MAJOR · AD-18 (L152) binds the wrong FRs entirely
> **Binds:** FR-51, FR-52, NFR-A1, NFR-A2

AD-18 is "Both languages are complete, and no string is hardcoded". PRD **FR-51 is OneDrive/Dropbox cloud backup** and **FR-52 is cloud restore**. The bilingual requirements are **FR-61 (Bangla-default UI)** and **FR-62 (English UI option)** — neither is bound by any AD. The NFR half (A1, A2) is correct; the FR half is bound to two paid cloud features.

### C-3 · MAJOR · AD-19 (L158) gates free features behind the paid tier
> **Binds:** FR-47..FR-50, §8 Monetization

The "Private Backup" IAP covers **FR-50, FR-51, FR-52, FR-53** (PRD §8, L853). **FR-47 (local restore)** and **FR-48 (backup/restore failure handling)** are explicitly *free* — PRD L885 states "Local backup, restore, and full data export (FR-45, FR-47, FR-54–FR-60) remain free, so no user is locked out of their own data." As written, AD-19 instructs an implementer to put local restore behind `EntitlementService.hasPrivateBackup`, which inverts a deliberate product decision. FR-51 and FR-53 are simultaneously *not* bound, so the two providers that most need gating aren't.

### C-4 · MAJOR · Three more mis-bindings in the backup/import cluster
- **AD-13 (L122)** binds FR-47, 48, 49, 50, 52 — omits **FR-51 (OneDrive/Dropbox)** and **FR-53 (automatic cloud backup)**, even though the Rule at L124 explicitly names OneDrive and Dropbox as implementers of the interface. The AD does not bind the requirements it exists to satisfy.
- **AD-14 (L128)** binds FR-59, which is *JSON import*. The `.hfm` Backup File import requirement is **FR-60**. AD-14 is the `.hfm` format AD.
- **AD-6 (L82)** cites "FR-46, FR-49, FR-57, FR-58" as the import/restore/delete-all transactions. FR-46 is the Recovery Phrase, FR-49 is cloud connection lifecycle, FR-57 is JSON *export* (not import). The actual imports are FR-58/FR-59/FR-60, and **the delete-all path (FR-44) — the third case the Rule names in prose — is not cited at all.**

Taken with C-1, C-2 and C-3: **the FR references throughout this document cannot be trusted as-is.** Every `Binds` line needs re-derivation against the PRD before anyone builds from it.

### C-5 · MAJOR · AD-9 (L96–100) narrows FR-5's trigger and contradicts FR-16's condition
PRD FR-5 (L171): notification permission is requested "when the user creates their first Medication Schedule **or Appointment reminder**". AD-9's Rule fires only "On first Medication Schedule creation". **A user whose first scheduled thing is an appointment reminder is never asked for notification permission**, and FR-21 appointment reminders silently never fire — the failure EXPERIENCE.md L95 calls "the worst failure in the product".

Two further divergences in the same AD:
- FR-5 (L169) requires that **each** request be preceded by an explanation screen stating why *that* permission is needed and what happens if it is denied. AD-9 collapses three distinct requests (notifications, exact alarms, battery exemption) behind "one explanation screen".
- FR-16 (L~289) makes the battery-optimisation prompt **conditional** — "On these devices the app detects the restriction and shows a one-time, dismissible prompt". AD-9 requests the exemption unconditionally as part of the bundle, on every Android device.

### C-6 · MAJOR · FR-48 and NFR-P9 have no architectural home, and FR-48 partly contradicts AD-14
FR-48 enumerates six failure modes that must each produce a specific, distinguishable outcome (wrong credential, corrupted/truncated file, **missing attachments**, interrupted upload, insufficient storage, newer schema). AD-14 (L130) covers exactly two of them: checksum-before-decrypt and schema-newer refusal.

The missing-attachments case actively conflicts: FR-48 requires that "the restore **completes** and the app reports exactly which records have missing attachments rather than failing wholesale", while AD-14's Rule is "swaps only on full success (AD-6)" and AD-6 (L82) makes restore a single all-or-nothing transaction. Read literally, the spine forbids the behaviour the PRD requires.

**NFR-P9** (backup/restore show accurate progress, are **cancellable**, and **survive the app being backgrounded mid-operation**) is bound by no AD at all. "Survives backgrounding" is a structural requirement — it dictates whether backup runs in an isolate, a foreground service, or a `WorkManager` task — and it is exactly the kind of decision that must be made once, not per-feature.

---

## 5. Deferred safety — can anything under Deferred let two units diverge?

**PASS — safely deferred.** The multi-device sync engine (L300), sync conflict policy (L301), OCR/on-device AI/drug-interaction data (L302), analytics taxonomy beyond the allowlist (L307) and CI provider (L308) are all correctly deferred: AD-4 and AD-11 hold the halves that would be expensive to retrofit, and each remaining decision has exactly one future owner.

### D-1 · MAJOR · "Chart rendering library — a leaf decision" (L304) is not a leaf
The justification is "NFR-P6 sets the budget; any library meeting it is compliant". But the chart is a **shared component with cross-unit behavioural requirements**, and three separate consumers exist:
- PRD FR-32 (L450): lab-result trends reuse "the FR-29 chart component" — reuse is stated as a requirement.
- PRD FR-29 (L425) / FR-54: "Chart is included in the PDF health summary" — a *third* rendering context, in a different output medium.
- EXPERIENCE.md L81 constrains its behaviour: "Draws no threshold line, no zone shading, no colour judgement." DESIGN.md L211 requires **Bengali numerals and tabular figures** on every axis and label. DESIGN.md L31 reserves `chart-secondary: #A9BDB6`.

With no owner named, `features/measurements`, `features/lab_reports` and the PDF path can each pick a renderer, and the same blood-pressure reading looks different in three places — the precise divergence DESIGN.md L247 forbids for the severe-allergy badge ("It appears identically on the member profile, the emergency card, and the exported PDF, so the same fact looks the same in all three places"). The spine applies that principle to allergies and abandons it for charts.

### D-2 · MAJOR · "Test-coverage thresholds **and mocking strategy** — team convention, not a cross-unit invariant" (L306)
Coverage thresholds, yes. Mocking strategy, no — **AD-20 depends on it**. AD-20's gate (L166) is "the app must pass its test suite with all four no-ops installed", which is a shared test-fixture contract: someone must define where the no-op `CloudStorageProvider`, ads, analytics and IAP implementations live and how they are substituted. With the strategy deferred, each feature builds its own incompatible fakes and AD-20's gate cannot be run uniformly across the codebase — the one AD whose enforcement is a whole-app test is the one whose enforcement mechanism is deferred.

### D-3 · MAJOR · "iOS rapid-emergency mechanism (widget vs. Live Activity vs. Shortcut)" (L303) defers two things, one of which is an invariant
The *mechanism* is genuinely a leaf and correctly deferred. But bundled inside it is a question that is not: **how does a process outside the app read Emergency Health Card data from a locked device?** That question has cross-cutting answers with opposite privacy properties (a shared keychain group vs. a plaintext app-group mirror vs. an encrypted sidecar), it must be answered identically on both platforms, and it collides head-on with AD-1, AD-2 and AD-3. Deferring both together licenses Android and iOS to diverge on where unlocked health data lives. See X-1 — this is the same hole seen from the UX side.

### D-4 · MINOR · "PDF generation library" (L305)
Same shape as D-1 at lower stakes: FR-54 (single member) and FR-55 (whole family) both render, the chart embeds inside both (FR-29), and NFR-P8 requires the Family report to show progress without blocking the UI. Two rendering paths and a shared embedded component is not a leaf decision either — though here both consumers do at least live in `features/import_export`.

---

## 6. Silent dimensions

Checked: testing, error handling, offline/conflict, performance budgets, accessibility, build/release, DI/wiring, navigation/routing, operational envelope.

**PASS — properly addressed.** *Offline* is the strongest dimension in the document (AD-1 local-DB-only reads, AD-20 no-op subsystems, "No core path awaits a network call"). *Conflict* is correctly deferred with the sync engine. *Build/release and the operational envelope* are covered in prose at L274 — no servers, store binary as the deployable, named CI gates, named release channels, OS-level-only crash reporting tied back to AD-11. *Testing* is partially covered: the three mandatory gates are named and non-negotiable (AD-2 cipher assertion on release build, AD-11 CI grep, AD-17 migration tests) — see D-2 for what is missing.

### S-1 · BLOCKER · Performance budgets — entirely silent
**Not one AD binds any NFR-P.** The frontmatter (L11) claims `NFR-P1..P9`; only NFR-P1 and NFR-P2 are actually bound (AD-20, AD-7/AD-8). The Capability Map name-drops `NFR-P4`, `NFR-P5`, `NFR-P6` in a column headed **"Governed by"** (L286, L287, L288) — where every other cell names an AD — implying governance that does not exist. Unowned:

- **NFR-P4** — "loading **windowed pages** rather than the full event set" for Timeline and Calendar. This is a *structural* rule, not a budget: it dictates that list repositories expose a paged/windowed read API rather than `Stream<List<T>>` over a whole table. Two features will answer it differently, and Drift's ergonomics push toward the wrong answer.
- **NFR-P7** — adherence over 10,000 Medication Logs in 2s. Forces a derived-vs-stored decision nothing makes (see S-4).
- **NFR-P8** — Family Health Report shows progress and does not block the UI (isolate boundary).
- **NFR-P9** — cancellable, survives backgrounding (see C-6).
- **NFR-P3** — 3s cold start on 2GB Android 10, which constrains what may happen before first frame — and AD-2 puts a synchronous cipher assertion *and* a fail-closed check on exactly that path.
- **The reference dataset itself.** PRD L774 defines a specific fixture (10 members, 20 years, 10k measurements, 10k logs, 5k documents, 500 appointments) as the meaning of "at reference size" for all nine NFR-Ps. No AD requires the fixture to exist, so none of the budgets are measurable.

### S-2 · MAJOR · Accessibility — entirely silent
AD-18 covers strings and numerals. Nothing covers layout or assistive technology, though both spines treat these as correctness requirements, not polish:
- NFR-A1 (PRD L797): Bangla renders "without layout overflow, clipping, or conjunct-glyph corruption ... layouts must accommodate that rather than truncate."
- DESIGN.md L207–209: every container sized to the **Bangla** measure; "a truncated medication name is a safety problem, not a cosmetic one."
- EXPERIENCE.md L110–116: 48px minimum tap target everywhere; **dynamic type honoured to the largest accessibility setting**; colour never the sole carrier; every icon-only control labelled; emergency card reads in a *specified* priority order; focus visible without colour; no timed dismissals on health information.

Every one of those is cross-unit — they constrain shared widget primitives, not individual screens — and none has an architectural owner or a gate. AD-18's ARB-parity CI check shows the author knows how to build such a gate; there is simply no equivalent here.

### S-3 · MAJOR · Navigation / routing — entirely silent
`go_router` appears once, unpinned, in the Stack (L197); `app/` is annotated "entry, router, theme, localisation delegates" (L216). **No AD governs routing.** The cross-feature route contracts that need one:
- FR-16 (L286): tapping a reminder notification must open the app to full dose detail — a deep link from a payload built by `NotificationContentBuilder` (AD-10), which by design carries only member name, item name and time. Nothing says what identifier the route consumes or how it survives AD-10's deliberately narrow payload surface.
- FR-39: "Tapping a calendar event navigates to the relevant record" — a route from one feature into any of five others.
- FR-38 / X-1: a lock-screen surface entry point into the app.
- EXPERIENCE.md L31: five fixed tabs, no drawer, **sheets stack one level, never two** — a global routing invariant stated in the UX spine with no architectural counterpart.
- EXPERIENCE.md L103: Android hardware back and iOS edge swipe both honoured; "a sheet closes before the screen behind it."

Route naming, deep-link parsing, and sheet-depth enforcement are exactly the things every feature touches and no feature owns.

### S-4 · MAJOR · Derived-vs-stored state — silent
FR-17 (L~300): "A dose not actioned before the next scheduled dose time is automatically marked Missed." The refill diagram (L270) shows `Catch-up reconciliation / overdue → Missed` as an app-open step. FR-18 and NFR-P7 need adherence percentages over 10,000 logs in 2 seconds.

Is `Missed` a persisted status transition written on app open, or a status computed at read time from scheduled-time-versus-now? Is adherence a stored rollup or an aggregate query? The answer changes the schema, the transaction boundaries (AD-6), and whether NFR-P7 is reachable — and two features will answer it two ways. Nothing in the ADs or the Conventions table decides. Given AD-4's soft-delete-everything model and a 20-year record horizon, this is the highest-leverage unmade decision after S-1.

### S-5 · MAJOR · OAuth token storage — silent
NFR-S3 (PRD L793) requires that "Encryption keys **and OAuth tokens** are stored exclusively in Android Keystore / iOS Secure Enclave." NFR-S3 is bound only by AD-2 (L56), which is about the *database* key. **No AD binds NFR-S3 for OAuth tokens**, AD-3 speaks only of the database encryption key, and AD-13's interface has no token contract (P-4). FR-49 adds requirements on top — disconnect must delete the stored token, and auth failures must be distinguishable from quota and network failures — with no architectural owner. Three provider implementations will each invent their own token handling.

### S-6 · MINOR · Error handling — convention-only, no AD
Conventions L180–181 are good content: `Result<T, AppFailure>` across layer boundaries, exceptions never cross into `presentation`, sealed `AppFailure` with a localisation key so every failure is presentable in both languages. But it sits in a table, so it has no `Prevents`, no `Rule`, and no gate — and the sealed set is never enumerated against FR-48's six named failure modes or FR-49's distinct auth/quota/network cases. EXPERIENCE.md L59–60 makes specificity a hard requirement ("ফাইলটি নষ্ট — খোলা যাচ্ছে না", never "Error occurred"). A sealed type with no required members permits a single `AppFailure.unknown` that satisfies the convention and violates the product.

### S-7 · MINOR · DI / wiring — partial
AD-16 establishes Riverpod, manual providers, no codegen, and "Riverpod wires it" (L44). Unaddressed: where providers are declared (feature-local vs. a composition root), how they are scoped and overridden, and — critically — **how AD-20's four no-op implementations are substituted**, which is the mechanism AD-20's own gate depends on. See D-2.

---

## 7. UX spine consistency

**PASS — genuinely well-aligned where it counts.** Several ADs match the UX spines clause for clause, and this is the document's strongest section:
- AD-10 (L106) ↔ DESIGN.md L268 ↔ EXPERIENCE.md L122 ↔ NFR-S2 — notification payload restricted to member name, item name, time. The architecture goes further than the UX spine by making the violation *unrepresentable* (dosage is not a parameter, so it cannot be passed) and adding a test on the builder's public surface. Exemplary.
- AD-19 (L160) ↔ DESIGN.md L269 ↔ EXPERIENCE.md L126 — the never-show-an-ad screen list as a constant owned by the ads module rather than a per-screen decision.
- AD-14 (L130) ↔ EXPERIENCE.md L93 ↔ FR-47 — restore stages and swaps only on full success; "a failed restore leaves the device exactly as it was."
- AD-18 (L154) ↔ DESIGN.md L211 — Bengali numerals via a shared formatter, no `toString()` on a number reaching the UI.
- AD-9's timing ↔ EXPERIENCE.md L127/L132 — permissions at first use, never in onboarding (the trigger *scope* is still wrong; see C-5).
- AD-1 ↔ EXPERIENCE.md L23/L89 — offline is not a state; no spinner waiting on a network.

### X-1 · BLOCKER · AD-1 + AD-2 + AD-3 vs. FR-38 / EXPERIENCE.md UJ-4 — a required journey with no architectural path
The three foundational data ADs and the emergency requirement cannot all be true as written.

- **AD-1 (L52):** "Every read that renders UI comes from the local Drift database."
- **AD-2 (L58):** the database is opened through SQLite3MultipleCiphers, and on every app start "before any query, `DatabaseService` asserts the `cipher` pragma responds; if it does not, the app **fails closed**."
- **AD-3 (L64):** the key lives in platform secure storage.
- **EXPERIENCE.md L141 (UJ-4):** "Phone locked, Karim shaking. Emergency shortcut from the locked device → Father's card without a PIN ... B+, penicillin flagged তীব্র at the top, current medications ... The lock-screen surface exposes this card and nothing else; disabling the setting removes it completely."
- **FR-38 / FR-43 (L575):** the rapid emergency surface operates independently of in-app auto-lock, in at most three actions, without Jotno's PIN or biometric.

So a **separate process** (widget extension, complication, persistent notification, Assistant shortcut) must render blood group, severe allergies, active medications and contacts from a locked device. Nothing in the spine says how it obtains that data. The two available answers both break an invariant:
1. Open the encrypted Drift DB from the extension — requires exporting the database key into a shared keychain group readable by a widget process, which is at odds with AD-3's model and materially widens the key's exposure.
2. Mirror the emergency card into a plaintext store (app group / SharedPreferences / a widget timeline entry) — violates AD-1 (a UI read not from Drift), silently defeats AD-2's encryption claim, and puts health data somewhere NFR-S1's guarantee was never extended to.

The spine files this at L303 under Deferred as "an implementation choice best made against a real device" — but only the *mechanism* is a device question. **Where unencrypted emergency data may live is an invariant**, it must be identical on both platforms, and it is the one place in the product where the encryption promise and the emergency promise meet. It needs an AD. (Same hole from the deferral side: D-3.)

### X-2 · MAJOR · Permission-state surfacing has no architectural owner
EXPERIENCE.md L95 is emphatic: "Notification denial shows a persistent banner on Medications — **reminders silently not firing is the worst failure in the product**." PRD FR-5 (L176) and FR-16 (L~292) require the same, plus detection of *revoked* permission on app open and a route into system settings.

The spine has AD-9 for *requesting* permissions and AD-7/AD-8 for *scheduling*, but nothing owns permission **state** — who polls it, where it is held, how the Medications surface and any other affected surface learn about it, and how it interacts with AD-8's coverage anchor (which, per P-2, is itself a notification and therefore dead in exactly this state). Combined with P-2, the product's self-declared worst failure mode has no architectural detection path.

### X-3 · MAJOR · EXPERIENCE.md L88 "Loading ... shows determinate progress, not a spinner" has no home
"Where it exists (PDF generation, backup, restore) it shows **determinate** progress." Determinate progress is not a UI choice — it requires the underlying operation to report unit counts as it goes, which constrains the interfaces in `core/backup` and the PDF path. Combined with NFR-P9 (cancellable, survives backgrounding) and NFR-P8 (non-blocking), this is a three-way structural requirement on long-running operations that no AD states. AD-14 defines the *format*; nothing defines the *execution model*.

### X-4 · MINOR · Font strategy absent, against a stated correctness requirement
DESIGN.md L203 selects Noto Sans Bengali specifically "for complete conjunct coverage (যুক্তাক্ষর render correctly rather than dropping to fallback boxes) and for being present or reliably bundleable on both platforms" — and NFR-A1 makes conjunct-glyph corruption a defect, not a cosmetic issue. The Stack (L190–208) pins no font asset, and the structural seed (L215–233) has no `assets/` or `assets/fonts/` entry. Falling back to a platform default font on an older Android is precisely the failure NFR-A1 forbids, and nothing in the spine prevents it.

### X-5 · MINOR · Corrupted-backup listing has no interface support
EXPERIENCE.md L125: "A corrupted backup is shown as corrupted, greyed and labelled in the restore list. Never silently omitted — a backup that vanishes is worse than one that admits it is broken." FR-48 agrees and adds "offers the next most recent one."

AD-14 (L130) only defines what happens when restore is *attempted* ("refuses a schema version newer than the running app"). Listing corruption requires reading and validating manifests for every candidate **without decrypting**, and AD-13's `list` / `metadata` operations (L124) carry no such contract. The two ADs that own this behaviour between them leave the required state unrepresentable.

---

## Summary

| Severity | Count | Findings |
|---|---|---|
| **BLOCKER** | 4 | P-1, C-1, S-1, X-1 |
| **MAJOR** | 19 | M-1, M-2, E-1, P-2, P-3, C-2, C-3, C-4, C-5, C-6, D-1, D-2, D-3, S-2, S-3, S-4, S-5, X-2, X-3 |
| **MINOR** | 15 | M-3, M-4, M-5, M-6, E-2, E-3, E-4, E-5, P-4, P-5, D-4, S-6, S-7, X-4, X-5 |
| **Total** | **38** | |

**Clean passes:** AD id integrity (20/20 complete, no duplicates or gaps) · all three mermaid diagrams parse under mermaid 11 · no placeholder text · five model-grade enforcement gates (AD-2, AD-10, AD-11, AD-17, AD-18) · offline dimension · operational envelope · five safe deferrals · privacy and monetisation alignment with both UX spines.

### The shape of it

This is a strong document with a well-chosen paradigm, an unusually high proportion of genuinely checkable rules, and real intellectual work in AD-7/AD-8 (budget-aware scheduling) and AD-10 (making a privacy violation unrepresentable rather than merely forbidden). Its failures cluster in three places:

1. **The FR reference layer is systematically wrong** (C-1 through C-4). The map drifts by one from FR-9 to FR-39, and five ADs bind requirements they have nothing to do with. Every `Binds` line needs re-derivation before anyone builds from this.
2. **Three dimensions the feature altitude owns are silent** — performance budgets (S-1), accessibility (S-2), routing (S-3) — plus derived-vs-stored state (S-4), which nothing in the PRD names but which two features will answer two ways.
3. **The emergency-card-on-a-locked-device path does not exist** (X-1). It is the intersection of the product's two loudest promises — encryption and emergency access — and it is currently filed under Deferred as a mechanism choice.

The four BLOCKERs are independent and individually fixable; none requires rethinking the paradigm.
