import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/database/app_database.dart';
import 'package:vms_finance_app/core/database/finance_repository.dart';
import 'package:vms_finance_app/core/sync/entry_sync_api.dart';
import 'package:vms_finance_app/core/sync/finance_sync_service.dart';
import 'package:vms_finance_app/features/entries/domain/finance_entry.dart';

void main() {
  late AppDatabase database;
  late FinanceRepository repository;
  final now = DateTime.utc(2026, 11, 10, 21);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinanceRepository(database);
  });

  tearDown(() => database.close());

  test(
    'acknowledges only confirmed operations and marks entry synced',
    () async {
      await repository.addEntry(
        householdId: 'household-1',
        direction: FinanceEntryDirection.expense,
        amountInCents: 1599,
        description: 'Groceries',
        occurredAt: DateTime.utc(2026, 11, 10, 12, 30),
      );
      final api = FakeEntrySyncApi();
      final service = FinanceSyncService(
        database: database,
        api: api,
        tokenProvider: const FixedTokenProvider('access-token'),
        clock: () => now,
      );

      final result = await service.syncPending();

      expect(result.status, SyncRunStatus.completed);
      expect(result.synced, 1);
      expect(await database.select(database.syncOutbox).get(), isEmpty);
      final entry = await database
          .select(database.localFinanceEntries)
          .getSingle();
      expect(entry.syncState, 'synced');
      expect(api.calls, hasLength(1));
      expect(api.calls.single.householdId, 'household-1');
      expect(api.calls.single.accessToken, 'access-token');
      final sent = api.calls.single.operations.single;
      expect(sent.direction, 'expense');
      expect(sent.occurredOn, '2026-11-10');
      expect(sent.operationId, isNotEmpty);
      expect(sent.toJson(), {
        'id': sent.entryId,
        'idempotencyKey': sent.operationId,
        'direction': 'expense',
        'amountInCents': 1599,
        'description': 'Groceries',
        'occurredOn': '2026-11-10',
      });
    },
  );

  test(
    'retains operation and schedules exponential retry after failure',
    () async {
      await repository.addEntry(
        householdId: 'household-1',
        direction: FinanceEntryDirection.income,
        amountInCents: 500000,
        description: 'Salary',
        occurredAt: DateTime.utc(2026, 11, 1),
      );
      final api = FakeEntrySyncApi(error: Exception('offline'));
      final service = FinanceSyncService(
        database: database,
        api: api,
        tokenProvider: const FixedTokenProvider('access-token'),
        clock: () => now,
      );

      final first = await service.syncPending();
      final retry = await database.select(database.syncOutbox).getSingle();
      final second = await service.syncPending();

      expect(first.status, SyncRunStatus.completed);
      expect(retry.attemptCount, 1);
      expect(retry.nextAttemptAt?.toUtc(), now.add(const Duration(seconds: 1)));
      expect(retry.lastError, 'transport_error');
      expect(second.status, SyncRunStatus.nothingToDo);
      expect(api.calls, hasLength(1));
      final entry = await database
          .select(database.localFinanceEntries)
          .getSingle();
      expect(entry.syncState, 'pending');
    },
  );

  test(
    'does not contact API or mutate outbox without an access token',
    () async {
      await repository.addEntry(
        householdId: 'household-1',
        direction: FinanceEntryDirection.expense,
        amountInCents: 800,
        description: 'Lunch',
        occurredAt: now,
      );
      final api = FakeEntrySyncApi();
      final service = FinanceSyncService(
        database: database,
        api: api,
        tokenProvider: const FixedTokenProvider(null),
        clock: () => now,
      );

      final result = await service.syncPending();

      expect(result.status, SyncRunStatus.authenticationRequired);
      expect(api.calls, isEmpty);
      expect(await database.select(database.syncOutbox).get(), hasLength(1));
    },
  );

  test('quarantines an atomic batch rejected with a conflict', () async {
    await repository.addEntry(
      householdId: 'household-1',
      direction: FinanceEntryDirection.expense,
      amountInCents: 800,
      description: 'Lunch',
      occurredAt: now,
    );
    final api = FakeEntrySyncApi(
      error: const EntrySyncConflictException('idempotency mismatch'),
    );
    final service = FinanceSyncService(
      database: database,
      api: api,
      tokenProvider: const FixedTokenProvider('access-token'),
      clock: () => now,
    );

    final result = await service.syncPending();

    expect(result.conflicts, 1);
    expect(await database.select(database.syncOutbox).get(), isEmpty);
    final entry = await database
        .select(database.localFinanceEntries)
        .getSingle();
    expect(entry.syncState, 'conflict');
  });

  test('quarantines malformed payload without aborting the run', () async {
    await repository.addEntry(
      householdId: 'household-1',
      direction: FinanceEntryDirection.expense,
      amountInCents: 800,
      description: 'Lunch',
      occurredAt: now,
    );
    await database
        .update(database.syncOutbox)
        .write(const SyncOutboxCompanion(payload: Value('{not-json')));
    final service = FinanceSyncService(
      database: database,
      api: FakeEntrySyncApi(),
      tokenProvider: const FixedTokenProvider(null),
      clock: () => now,
    );

    final result = await service.syncPending();

    expect(result.status, SyncRunStatus.completed);
    expect(result.conflicts, 1);
    expect(await database.select(database.syncOutbox).get(), isEmpty);
    final entry = await database
        .select(database.localFinanceEntries)
        .getSingle();
    expect(entry.syncState, 'conflict');
  });

  test('401 or 403 requires authentication without scheduling retry', () async {
    await repository.addEntry(
      householdId: 'household-1',
      direction: FinanceEntryDirection.expense,
      amountInCents: 800,
      description: 'Lunch',
      occurredAt: now,
    );
    final service = FinanceSyncService(
      database: database,
      api: FakeEntrySyncApi(error: const EntrySyncAuthenticationException()),
      tokenProvider: const FixedTokenProvider('expired-token'),
      clock: () => now,
    );

    final result = await service.syncPending();
    final outbox = await database.select(database.syncOutbox).getSingle();

    expect(result.status, SyncRunStatus.authenticationRequired);
    expect(outbox.attemptCount, 0);
    expect(outbox.nextAttemptAt, isNull);
    expect(outbox.lastError, isNull);
  });

  test('invalid response retries the entire batch before any ack', () async {
    for (var index = 0; index < 2; index++) {
      await repository.addEntry(
        householdId: 'household-1',
        direction: FinanceEntryDirection.expense,
        amountInCents: 100 + index,
        description: 'Entry $index',
        occurredAt: now,
      );
    }
    final service = FinanceSyncService(
      database: database,
      api: FakeEntrySyncApi(results: (_) => const []),
      tokenProvider: const FixedTokenProvider('access-token'),
      clock: () => now,
    );

    await service.syncPending();
    final outbox = await database.select(database.syncOutbox).get();
    final entries = await database.select(database.localFinanceEntries).get();

    expect(outbox, hasLength(2));
    expect(outbox.map((row) => row.attemptCount), everyElement(1));
    expect(
      outbox.map((row) => row.lastError),
      everyElement('invalid_response'),
    );
    expect(entries.map((entry) => entry.syncState), everyElement('pending'));
  });

  test('rejects a concurrent sync run with a guard result', () async {
    await repository.addEntry(
      householdId: 'household-1',
      direction: FinanceEntryDirection.expense,
      amountInCents: 800,
      description: 'Lunch',
      occurredAt: now,
    );
    final gate = Completer<void>();
    final api = FakeEntrySyncApi(delay: gate.future);
    final service = FinanceSyncService(
      database: database,
      api: api,
      tokenProvider: const FixedTokenProvider('access-token'),
      clock: () => now,
    );

    final first = service.syncPending();
    await api.whenCalled;
    final concurrent = await service.syncPending();
    gate.complete();
    await first;

    expect(concurrent.status, SyncRunStatus.alreadyRunning);
    expect(api.calls, hasLength(1));
  });

  test('groups operations by household into authenticated batches', () async {
    for (final householdId in ['household-1', 'household-2']) {
      await repository.addEntry(
        householdId: householdId,
        direction: FinanceEntryDirection.expense,
        amountInCents: 100,
        description: householdId,
        occurredAt: now,
      );
    }
    final api = FakeEntrySyncApi();
    final service = FinanceSyncService(
      database: database,
      api: api,
      tokenProvider: const FixedTokenProvider('access-token'),
      clock: () => now,
    );

    await service.syncPending();

    expect(api.calls, hasLength(2));
    expect(api.calls.map((call) => call.householdId), {
      'household-1',
      'household-2',
    });
  });
}

class ApiCall {
  const ApiCall(this.householdId, this.accessToken, this.operations);

  final String householdId;
  final String accessToken;
  final List<PendingEntryOperation> operations;
}

class FakeEntrySyncApi implements EntrySyncApi {
  FakeEntrySyncApi({this.error, this.results, this.delay});

  final Object? error;
  final List<EntrySyncResult> Function(List<PendingEntryOperation>)? results;
  final Future<void>? delay;
  final List<ApiCall> calls = [];
  final Completer<void> _called = Completer<void>();

  Future<void> get whenCalled => _called.future;

  @override
  Future<List<EntrySyncResult>> pushEntries({
    required String householdId,
    required String accessToken,
    required List<PendingEntryOperation> operations,
  }) async {
    calls.add(ApiCall(householdId, accessToken, operations));
    if (!_called.isCompleted) {
      _called.complete();
    }
    if (delay case final delay?) {
      await delay;
    }
    if (error case final error?) {
      throw error;
    }
    if (results case final results?) {
      return results(operations);
    }
    return operations
        .map(
          (operation) => EntrySyncResult(
            operationId: operation.operationId,
            status: EntrySyncStatus.applied,
          ),
        )
        .toList(growable: false);
  }
}

class FixedTokenProvider implements AccessTokenProvider {
  const FixedTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> readAccessToken() async => token;
}
