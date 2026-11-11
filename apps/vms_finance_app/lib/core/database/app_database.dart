import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class LocalFinanceEntries extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  IntColumn get direction => integer()();
  IntColumn get amountInCents => integer()();
  TextColumn get description => text().withLength(min: 1, max: 240)();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncOutbox extends Table {
  TextColumn get operationId => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {operationId};
}

class CachedHouseholds extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get role => text().withLength(min: 1, max: 16)();
  DateTimeColumn get refreshedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class HouseholdPreferences extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get activeHouseholdId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalFinanceEntries,
    SyncOutbox,
    CachedHouseholds,
    HouseholdPreferences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(syncOutbox, syncOutbox.attemptCount);
        await migrator.addColumn(syncOutbox, syncOutbox.nextAttemptAt);
        await migrator.addColumn(syncOutbox, syncOutbox.lastError);
      }
      if (from < 3) {
        await migrator.createTable(cachedHouseholds);
        await migrator.createTable(householdPreferences);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(path.join(directory.path, 'vms_finance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
