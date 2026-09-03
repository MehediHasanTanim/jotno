# Deferred Work

- source_spec: `spec-1-1-encrypted-database.md`
  summary: CI never executes `integration_test/`, so the one check aimed at the shipped device artifact is never run by the pipeline.
  evidence: The workflow has no emulator or simulator job. A device build that linked upstream SQLite while the host toolchain resolved sqlite3mc would pass every CI step. Classified defer rather than bad_spec because the fix is additive and needs an infrastructure decision — which runner hosts an Android emulator, and whether iOS simulator jobs are worth the macOS runner minutes — not a re-derivation of the code.

- source_spec: `spec-1-1-encrypted-database.md`
  summary: The cipher scheme and KDF iteration count are left at SQLite3MultipleCiphers defaults rather than pinned explicitly.
  evidence: A future `sqlite3` upgrade that changes those defaults would render every existing user database unreadable, presenting identically to a wrong key — with no migration path and no distinguishing signal. For a no-backend app where the device holds the only copy, that is unrecoverable data loss. Belongs in the architecture spine as an invariant (`PRAGMA cipher`, `PRAGMA kdf_iter` pinned, with a fixture database proving a pinned-settings file still opens).

- source_spec: `spec-1-1-encrypted-database.md`
  summary: No `foreign_keys`, `journal_mode`/WAL, or `busy_timeout` pragma is set after `PRAGMA key`.
  evidence: `configureEncryptedDatabase` documents where such pragmas belong but sets none. SQLite does not enforce foreign keys by default, which is a correctness trap for every table added from Story 1.2 onward. WAL also interacts with the background isolate read pool.

- source_spec: `spec-1-1-encrypted-database.md`
  summary: The AD-4 identity-column contract is prose in a doc comment, not a shared mixin the compiler enforces.
  evidence: `SmokeRecords` documents `id`/`created_at`/`updated_at`/`deleted_at`/`device_id` as columns every future table must carry, but there is no base class, no `clientDefault` for timestamps, no UUIDv7 validation, and no index on `deleted_at`. Story 1.2 owns the shared foundations and should turn this into a mixin.

- source_spec: `spec-1-1-encrypted-database.md`
  summary: User-facing strings in `main.dart` are hardcoded English with no localisation wiring.
  evidence: `flutter_localizations` is absent, there is no `l10n.yaml`, and `lib/l10n/` holds only a `.gitkeep`. Story 1.3 ("The app speaks Bangla first") owns this; the strings need extracting then. AD-18 requires both locales complete, so this cannot be left past that story.

- source_spec: `spec-1-1-encrypted-database.md`
  summary: `SmokeRecords` is baked into schema v1 with no retirement plan.
  evidence: It exists only to give the encrypted database something to prove itself against, but it is in the v1 snapshot, and hand-written migrations are forbidden — so removing it later is a generated-migration event nobody has scoped.

- source_spec: `spec-1-1-encrypted-database.md`
  summary: Key material lives in immutable Dart Strings that cannot be zeroed and are copied to a background isolate.
  evidence: Not fixable within this story's design, but Story 1.15 (recovery phrase and double-wrapped DEK) needs this recorded as a constraint before it chooses how to hold key material, rather than discovering it afterwards.

- source_spec: `spec-1-1-encrypted-database.md`
  summary: `AppDatabase` declares no `MigrationStrategy`, so an unexpected `user_version` hits drift's default handler.
  evidence: A downgrade, or a file written by a future schema version, would fail opaquely rather than with a named error. Belongs with the migration work once a v2 exists.

- source_spec: `spec-1-1-encrypted-database.md`
  summary: On Android, a build that ships upstream SQLite instead of SQLite3MultipleCiphers hangs on a black screen rather than rendering the cipher error.
  evidence: Reproduced on a Motorola edge 50 fusion (Android 16) in debug, profile and release. Three facts locate it below Dart. The 30-second startup watchdog never fires, so the isolate's event loop is blocked — a Dart timer cannot run. `/proc/<pid>/maps` shows no SQLite library mapped at all, so the code asset never loaded (this refutes the soname-collision hypothesis: it is not that the wrong SQLite loaded, it is that none did). And the eager-verification refactor, which removed drift and LazyDatabase from the fail-closed path entirely, did not change the symptom. iOS renders the error correctly, so it is Android-specific. Data safety is unaffected — no database opens and nothing is written in plaintext. What is lost is the explanation: the user sees a black screen instead of being told the build is broken. The shipping configuration is verified working on-device, and the CI encryption-switch gate blocks the broken configuration before it can ship, so this is a defence-in-depth gap rather than an exposure. Fixing it needs investigation at the `package:sqlite3` code-asset loading layer, likely with an upstream issue.

- source_spec: none
  owner: Story 1.4 (epics.md, Epic 1)
  summary: `HeadlessScope` — a container that non-widget entry points (notification action handler, boot receiver, WorkManager callback) use to reach repositories.
  evidence: Split from Story 1.2, which bundled six independently shippable foundations. AD-16 makes this the only permitted path for reaching repositories outside the widget tree; Story 2.4's dose logging is its first consumer, so it must land before Epic 2.

- source_spec: none
  owner: Story 1.4 (epics.md, Epic 1)
  summary: `AttachmentStore` — sole owner of attachment paths and the only code permitted to delete attachment files.
  evidence: Split from Story 1.2. AD-12 forbids storing binary content in database columns and makes this the single writer. Story 1.12 (medical history documents) and 1.10 (member photo) are its first consumers, so it must land before them.

- source_spec: none
  owner: Story 1.4 (epics.md, Epic 1)
  summary: The three aggregator contributor interfaces — `TimelineContributor`, `CalendarContributor`, `SummaryContributor`.
  evidence: Split from Story 1.2. AD-23 requires each aggregator to declare a contract that source features implement, so the aggregator never imports a feature. Pure interfaces, but they must exist before any feature that contributes to a timeline, calendar or PDF is built.

- source_spec: none
  owner: Story 1.5 (epics.md, Epic 1)
  summary: The reference dataset fixture and the NFR-P benchmark harness.
  evidence: Split from Story 1.2. AD-27 requires the fixture (10 members, 20 years, 10,000 measurements, 10,000 medication logs, 5,000 documents, 500 appointments) to exist as a committed test artifact with benchmarks running against it in CI, otherwise the nine performance budgets are unmeasurable. Needed before any story whose acceptance criteria cite reference-size performance — Story 1.14 is the first.

- source_spec: `spec-1-2-error-model-and-logging.md`
  summary: Drift's generated data classes and companions print every column in `toString()`, which conflicts with the rule that a health entity renders type and id only.
  evidence: There is no drift build option for this — the full `DriftOptions` list in drift_dev 2.34.5 has ~30 flags and none touches `toString()`; the nearest, `override_hash_and_equals_in_result_sets`, covers `==`/`hashCode`. `@UseRowClass` closes only half the door, because companions are always generated and a companion's `toString()` prints the values being written, which on an insert is the health data itself. The enforceable rule is architectural and already implied by the epic: no drift-generated type may leave `lib/**/data/`, which is a CI gate in the same family as the logging gate rather than a build option or a lint. Exposure today is nil — the only table is the schema-v1 smoke table, and every route by which a `toString()` could reach a device log is closed (AppLogger cannot take a string; print, debugPrint, stdout, stderr and dart:developer imports are all gated under lib/; Result.toString omits the success value). Do this in Story 1.10, where the first health table lands: add the gate and give the hand-written domain entity a type-and-id toString. Do not adopt `@UseRowClass` — it misses companions and blurs the data/domain boundary the epic draws.
