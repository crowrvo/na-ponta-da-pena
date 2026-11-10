import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../features/entries/domain/finance_entries_repository.dart';
import '../../features/entries/domain/finance_entry.dart';
import 'app_database.dart';

class FinanceRepository implements FinanceEntriesRepository {
  FinanceRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  @override
  Stream<int> watchPendingOperations() {
    final query = _database.select(_database.syncOutbox);
    return query.watch().map((operations) => operations.length);
  }

  @override
  Stream<List<FinanceEntry>> watchEntriesForMonth(DateTime month) {
    final start = DateTime.utc(month.year, month.month);
    final end = DateTime.utc(month.year, month.month + 1);
    final query = _database.select(_database.localFinanceEntries)
      ..where(
        (entry) =>
            entry.occurredAt.isBiggerOrEqualValue(start) &
            entry.occurredAt.isSmallerThanValue(end),
      )
      ..orderBy([(entry) => OrderingTerm.desc(entry.occurredAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => FinanceEntry(
              id: row.id,
              householdId: row.householdId,
              direction: FinanceEntryDirection.fromDatabase(row.direction),
              amountInCents: row.amountInCents,
              description: row.description,
              occurredAt: row.occurredAt,
              syncState: row.syncState,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Stream<MonthlyFinanceSummary> watchSummaryForMonth(DateTime month) {
    return watchEntriesForMonth(month).map((entries) {
      var income = 0;
      var expense = 0;
      for (final entry in entries) {
        if (entry.direction == FinanceEntryDirection.income) {
          income += entry.amountInCents;
        } else {
          expense += entry.amountInCents;
        }
      }
      return MonthlyFinanceSummary(
        incomeInCents: income,
        expenseInCents: expense,
      );
    });
  }

  @override
  Future<void> addEntry({
    required String householdId,
    required FinanceEntryDirection direction,
    required int amountInCents,
    required String description,
    required DateTime occurredAt,
  }) async {
    if (amountInCents <= 0) {
      throw ArgumentError.value(
        amountInCents,
        'amountInCents',
        'must be positive',
      );
    }
    final normalizedDescription = description.trim();
    if (normalizedDescription.isEmpty || normalizedDescription.length > 240) {
      throw ArgumentError.value(
        description,
        'description',
        'must contain 1 to 240 characters',
      );
    }

    final entryId = _uuid.v7();
    final operationId = _uuid.v7();
    final now = DateTime.now().toUtc();
    final normalizedOccurredAt = occurredAt.toUtc();

    await _database.transaction(() async {
      await _database
          .into(_database.localFinanceEntries)
          .insert(
            LocalFinanceEntriesCompanion.insert(
              id: entryId,
              householdId: householdId,
              direction: direction.databaseValue,
              amountInCents: amountInCents,
              description: normalizedDescription,
              occurredAt: normalizedOccurredAt,
              updatedAt: now,
            ),
          );

      await _database
          .into(_database.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              operationId: operationId,
              entityId: entryId,
              operation: 'finance-entry.created',
              payload: jsonEncode({
                'operationId': operationId,
                'id': entryId,
                'householdId': householdId,
                'direction': direction.name,
                'amountInCents': amountInCents,
                'description': normalizedDescription,
                'occurredAt': normalizedOccurredAt.toIso8601String(),
              }),
              createdAt: now,
            ),
          );
    });
  }

  Future<void> addDraftExpense({
    required int amountInCents,
    required String description,
  }) async {
    return addEntry(
      householdId: 'local-unassigned',
      direction: FinanceEntryDirection.expense,
      amountInCents: amountInCents,
      description: description,
      occurredAt: DateTime.now(),
    );
  }
}
