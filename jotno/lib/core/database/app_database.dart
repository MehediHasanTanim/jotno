import 'package:drift/drift.dart';

import '../l10n/locale_controller.dart';
import '../result/app_failure.dart';
import 'app_database.steps.dart';
import 'connection.dart';
import 'database_key.dart';

part 'app_database.g.dart';

/// The single schema-v1 table.
///
/// It exists to give the encrypted database something to prove itself against
/// and to fix the identity columns every future table must carry:
///
/// - `id` — client-generated UUIDv7, TEXT, never autoincrement
/// - `created_at` / `updated_at` / `deleted_at` — UTC, ISO-8601 text
/// - `device_id` — which device wrote the row
///
/// Application code never hard-deletes; `deleted_at` carries the tombstone.
@DataClassName('SmokeRecord')
class SmokeRecords extends Table {
  /// Client-generated UUIDv7.
  TextColumn get id => text()();

  /// When the row was first written (UTC).
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  /// When the row was last modified (UTC).
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  /// Tombstone. Non-null means the row is soft-deleted.
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  /// Identifier of the device that wrote the row.
  TextColumn get deviceId => text().named('device_id')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Application settings, as one row per setting.
///
/// Deliberately *not* a new preferences package. AD-1 makes the local database
/// the only source of truth, and `shared_preferences` would put a
/// user-visible choice outside the encrypted file while adding a dependency
/// the architecture has not pinned.
///
/// Key/value rather than a column per setting, because the alternative is a
/// schema migration for every future toggle — the disclaimer acknowledgement,
/// the ad-consent choice, the app-lock timeout — and generated migrations are
/// the only kind permitted here.
///
/// No identity columns and no `deleted_at`. These are not records: a setting
/// is overwritten, never tombstoned, and there is exactly one row per key on
/// exactly one device. The soft-delete rule in AD-4 is about health data,
/// which this table must never hold — see [settingLanguage] for the only key
/// it currently has.
@DataClassName('AppSetting')
class AppSettings extends Table {
  /// Which setting this row is. See [settingLanguage].
  TextColumn get name => text().named('name')();

  /// The stored value, as text.
  ///
  /// Text and not a typed column because the table is generic; each setting
  /// owns the parsing of its own value, and an unparseable value is treated
  /// as "not set" rather than as an error.
  TextColumn get value => text().named('value')();

  /// When the row was last written (UTC).
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

/// The [AppSettings] row holding the user's language choice.
///
/// A literal constant, like every localisation key in this codebase: renaming
/// the Dart identifier must not change which row is read.
const String settingLanguage = 'language';

/// The Jotno database.
///
/// Every connection handed to this class must already be configured by
/// [configureEncryptedDatabase] — see [openAppDatabase].
@DriftDatabase(tables: [SmokeRecords, AppSettings])
class AppDatabase extends _$AppDatabase {
  /// Creates a database over an already-configured [executor].
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  /// Hand-written migrations are not permitted (AD-26).
  ///
  /// [stepByStep] and the `Schema2` shape it hands each step come from
  /// `app_database.steps.dart`, which `dart run drift_dev make-migrations`
  /// generates from the snapshots under `drift_schemas/`. The step body below
  /// names a table on that generated shape rather than on this file's own
  /// `appSettings`, so it keeps describing the v1→v2 transition unchanged
  /// however the table is edited afterwards — which is the whole reason the
  /// tool exists. CI regenerates and fails if the committed result differs.
  ///
  /// `test/migration/app_database/migration_test.dart`, also generated, runs
  /// this against a real v1 database for every version pair.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (migrator, schema) => migrator.createTable(schema.appSettings),
    ),
  );

  /// Reads the value of setting [name], or null if it has never been written.
  Future<String?> readSetting(String name) async {
    final row = await (select(
      appSettings,
    )..where((setting) => setting.name.equals(name))).getSingleOrNull();
    return row?.value;
  }

  /// Writes [value] for setting [name], replacing whatever was there.
  ///
  /// `await`ed rather than returned, so the row id drift hands back is
  /// discarded here rather than travelling out inside a `Future<void>` that
  /// still carries it at runtime.
  Future<void> writeSetting(String name, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        name: name,
        value: value,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }
}

/// The [LanguageStore] Jotno actually ships: the encrypted database.
///
/// The chicken-and-egg this creates is deliberate and is named in the story.
/// The startup error surface renders precisely when the database will not
/// open, so it cannot have one of these and resolves from the device locale
/// instead. That surface has six fixed strings, and a user who chose English
/// and sees the Bangla error once on a broken build has lost very little —
/// less than they would lose from one user-visible setting living outside the
/// encrypted file.
final class DatabaseLanguageStore implements LanguageStore {
  /// Creates a store over an open [database].
  const DatabaseLanguageStore(this.database);

  /// The open, encrypted database.
  final AppDatabase database;

  @override
  FutureResult<AppLanguage?> read() => guardSettingAccess(() async {
    // An unrecognised value is "no choice recorded", not an error: a row a
    // future version wrote, or one that got corrupted, must resolve from the
    // device rather than take the app down.
    return AppLanguage.forCode(await database.readSetting(settingLanguage));
  });

  @override
  FutureResult<void> write(AppLanguage language) => guardSettingAccess(
    () => database.writeSetting(settingLanguage, language.languageCode),
  );
}

/// Opens the encrypted Jotno database.
///
/// The cipher and the key are proven eagerly, in awaited code, before this
/// returns — see [verifyEncryptedDatabaseFile]. A failure therefore reaches the
/// caller's `catch` as itself, rather than depending on drift to surface an
/// error raised inside a lazily-invoked opener.
Future<AppDatabase> openAppDatabase({
  DatabaseKeyProvider keyProvider = const DevelopmentKeyProvider(),
  Future<Object> Function()? databaseDirectory,
  Future<Object> Function()? temporaryDirectory,
  RawDatabaseOpener openRaw = openRawDatabase,
}) async {
  final executor = await openEncryptedDatabase(
    keyProvider: keyProvider,
    databaseDirectory: databaseDirectory,
    temporaryDirectory: temporaryDirectory,
    openRaw: openRaw,
  );
  return AppDatabase(executor);
}
