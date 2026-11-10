import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'app_database.dart';

class FinanceRepository {
  FinanceRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Stream<int> watchPendingOperations() {
    final query = _database.select(_database.syncOutbox);
    return query.watch().map((operations) => operations.length);
  }

  Future<void> addDraftExpense({
    required int amountInCents,
    required String description,
  }) async {
    final entryId = _uuid.v7();
    final operationId = _uuid.v7();
    final now = DateTime.now().toUtc();

    await _database.transaction(() async {
      await _database
          .into(_database.localFinanceEntries)
          .insert(
            LocalFinanceEntriesCompanion.insert(
              id: entryId,
              householdId: 'local-unassigned',
              direction: 0,
              amountInCents: amountInCents,
              description: description,
              occurredAt: now,
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
                'id': entryId,
                'amountInCents': amountInCents,
                'description': description,
                'occurredAt': now.toIso8601String(),
              }),
              createdAt: now,
            ),
          );
    });
  }
}
