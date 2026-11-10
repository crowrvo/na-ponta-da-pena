import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'entry_sync_api.dart';

enum SyncRunStatus {
  completed,
  nothingToDo,
  authenticationRequired,
  alreadyRunning,
}

class SyncRunResult {
  const SyncRunResult(this.status, {this.synced = 0, this.conflicts = 0});

  final SyncRunStatus status;
  final int synced;
  final int conflicts;
}

class FinanceSyncService {
  FinanceSyncService({
    required AppDatabase database,
    required EntrySyncApi api,
    required AccessTokenProvider tokenProvider,
    DateTime Function()? clock,
  }) : _database = database,
       _api = api,
       _tokenProvider = tokenProvider,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final EntrySyncApi _api;
  final AccessTokenProvider _tokenProvider;
  final DateTime Function() _clock;
  bool _isRunning = false;

  Future<SyncRunResult> syncPending({int limit = 50}) async {
    if (_isRunning) {
      return const SyncRunResult(SyncRunStatus.alreadyRunning);
    }
    _isRunning = true;
    try {
      return await _syncPending(limit: limit);
    } finally {
      _isRunning = false;
    }
  }

  Future<SyncRunResult> _syncPending({required int limit}) async {
    final now = _clock().toUtc();
    final query = _database.select(_database.syncOutbox)
      ..where(
        (row) =>
            row.nextAttemptAt.isNull() |
            row.nextAttemptAt.isSmallerOrEqualValue(now),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
      ..limit(limit);
    final rows = await query.get();
    if (rows.isEmpty) {
      return const SyncRunResult(SyncRunStatus.nothingToDo);
    }

    var conflicts = 0;
    final operations = <PendingEntryOperation>[];
    for (final row in rows) {
      try {
        operations.add(_decode(row));
      } on Object {
        await _quarantineMalformed(row);
        conflicts++;
      }
    }
    if (operations.isEmpty) {
      return SyncRunResult(SyncRunStatus.completed, conflicts: conflicts);
    }

    final token = await _tokenProvider.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      return SyncRunResult(
        SyncRunStatus.authenticationRequired,
        conflicts: conflicts,
      );
    }

    final byHousehold = <String, List<PendingEntryOperation>>{};
    for (final operation in operations) {
      byHousehold.putIfAbsent(operation.householdId, () => []).add(operation);
    }

    var synced = 0;
    for (final householdBatch in byHousehold.entries) {
      try {
        final results = await _api.pushEntries(
          householdId: householdBatch.key,
          accessToken: token,
          operations: householdBatch.value,
        );
        if (!_isExactResponse(householdBatch.value, results)) {
          for (final operation in householdBatch.value) {
            await _recordRetry(operation.operationId, 'invalid_response', now);
          }
          continue;
        }
        final resultsById = {
          for (final result in results) result.operationId: result,
        };
        for (final operation in householdBatch.value) {
          final result = resultsById[operation.operationId]!;
          switch (result.status) {
            case EntrySyncStatus.applied:
            case EntrySyncStatus.duplicate:
              await _complete(operation, 'synced');
              synced++;
            case EntrySyncStatus.conflict:
            case EntrySyncStatus.rejected:
              await _complete(operation, 'conflict');
              conflicts++;
          }
        }
      } on EntrySyncConflictException {
        for (final operation in householdBatch.value) {
          await _complete(operation, 'conflict');
          conflicts++;
        }
      } on EntrySyncAuthenticationException {
        return SyncRunResult(
          SyncRunStatus.authenticationRequired,
          synced: synced,
          conflicts: conflicts,
        );
      } on EntrySyncInvalidResponseException {
        for (final operation in householdBatch.value) {
          await _recordRetry(operation.operationId, 'invalid_response', now);
        }
      } on Object {
        for (final operation in householdBatch.value) {
          await _recordRetry(operation.operationId, 'transport_error', now);
        }
      }
    }
    return SyncRunResult(
      SyncRunStatus.completed,
      synced: synced,
      conflicts: conflicts,
    );
  }

  bool _isExactResponse(
    List<PendingEntryOperation> operations,
    List<EntrySyncResult> results,
  ) {
    final expected = operations.map((item) => item.operationId).toSet();
    final received = results.map((item) => item.operationId).toList();
    return received.length == expected.length &&
        received.toSet().length == received.length &&
        received.toSet().containsAll(expected);
  }

  PendingEntryOperation _decode(SyncOutboxData row) {
    final payload = jsonDecode(row.payload);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid outbox payload.');
    }
    final occurredAt = DateTime.parse(payload['occurredAt'] as String).toUtc();
    return PendingEntryOperation(
      operationId: row.operationId,
      entryId: payload['id'] as String,
      householdId: payload['householdId'] as String,
      direction: payload['direction'] as String,
      amountInCents: payload['amountInCents'] as int,
      description: payload['description'] as String,
      occurredOn: occurredAt.toIso8601String().substring(0, 10),
    );
  }

  Future<void> _complete(PendingEntryOperation operation, String state) async {
    await _database.transaction(() async {
      await (_database.update(_database.localFinanceEntries)
            ..where((entry) => entry.id.equals(operation.entryId)))
          .write(LocalFinanceEntriesCompanion(syncState: Value(state)));
      await (_database.delete(
        _database.syncOutbox,
      )..where((row) => row.operationId.equals(operation.operationId))).go();
    });
  }

  Future<void> _quarantineMalformed(SyncOutboxData row) async {
    await _database.transaction(() async {
      await (_database.update(
        _database.localFinanceEntries,
      )..where((entry) => entry.id.equals(row.entityId))).write(
        const LocalFinanceEntriesCompanion(syncState: Value('conflict')),
      );
      await (_database.delete(
        _database.syncOutbox,
      )..where((item) => item.operationId.equals(row.operationId))).go();
    });
  }

  Future<void> _recordRetry(
    String operationId,
    String error,
    DateTime now,
  ) async {
    final row = await (_database.select(
      _database.syncOutbox,
    )..where((item) => item.operationId.equals(operationId))).getSingle();
    final attempts = row.attemptCount + 1;
    final seconds = 1 << (attempts - 1).clamp(0, 8);
    await (_database.update(
      _database.syncOutbox,
    )..where((item) => item.operationId.equals(operationId))).write(
      SyncOutboxCompanion(
        attemptCount: Value(attempts),
        nextAttemptAt: Value(now.add(Duration(seconds: seconds))),
        lastError: Value(error.length > 500 ? error.substring(0, 500) : error),
      ),
    );
  }
}
