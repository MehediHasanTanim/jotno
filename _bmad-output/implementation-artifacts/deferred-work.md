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
  evidence: Not fixable within this story's design, but Story 1.13 (recovery phrase and double-wrapped DEK) needs this recorded as a constraint before it chooses how to hold key material, rather than discovering it afterwards.

- source_spec: `spec-1-1-encrypted-database.md`
  summary: `AppDatabase` declares no `MigrationStrategy`, so an unexpected `user_version` hits drift's default handler.
  evidence: A downgrade, or a file written by a future schema version, would fail opaquely rather than with a named error. Belongs with the migration work once a v2 exists.
