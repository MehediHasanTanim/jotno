import 'package:drift/drift.dart';

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

/// The Jotno database.
///
/// Every connection handed to this class must already be configured by
/// [configureEncryptedDatabase] — see [openAppDatabase].
@DriftDatabase(tables: [SmokeRecords])
class AppDatabase extends _$AppDatabase {
  /// Creates a database over an already-configured [executor].
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
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
