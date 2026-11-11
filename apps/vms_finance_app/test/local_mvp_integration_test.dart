import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/database/app_database.dart';
import 'package:vms_finance_app/core/database/finance_repository.dart';
import 'package:vms_finance_app/core/sync/development_access_token_provider.dart';
import 'package:vms_finance_app/core/sync/entry_sync_api.dart';
import 'package:vms_finance_app/core/sync/finance_sync_service.dart';
import 'package:vms_finance_app/features/entries/domain/finance_entry.dart';
import 'package:vms_finance_app/features/households/data/household_api.dart';
import 'package:vms_finance_app/features/households/data/household_repository.dart';

void main() {
  const enabled = bool.fromEnvironment('VMS_RUN_LOCAL_MVP_TEST');
  const baseUrl = String.fromEnvironment('VMS_API_BASE_URL');
  const accessToken = String.fromEnvironment('VMS_DEVELOPMENT_ACCESS_TOKEN');

  test(
    'creates a household, syncs income and expense, and survives reopen',
    () async {
      expect(baseUrl, isNotEmpty);
      expect(accessToken, isNotEmpty);

      final directory = await Directory.systemTemp.createTemp(
        'vms-finance-local-mvp-',
      );
      final file = File('${directory.path}${Platform.pathSeparator}finance.db');
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      const tokenProvider = DevelopmentAccessTokenProvider(accessToken);
      late String householdId;
      AppDatabase? database;
      try {
        database = AppDatabase.forTesting(NativeDatabase(file));
        final households = HouseholdRepository(
          database: database,
          api: DioHouseholdApi(dio),
          tokenProvider: tokenProvider,
        );
        final created = await households.createHousehold(
          'MVP local ${DateTime.now().toUtc().toIso8601String()}',
        );
        householdId = created.activeHouseholdId!;

        final finance = FinanceRepository(database);
        await finance.addEntry(
          householdId: householdId,
          direction: FinanceEntryDirection.income,
          amountInCents: 750000,
          description: 'Receita MVP local',
          occurredAt: DateTime.utc(2026, 11, 11),
        );
        await finance.addEntry(
          householdId: householdId,
          direction: FinanceEntryDirection.expense,
          amountInCents: 12550,
          description: 'Despesa MVP local',
          occurredAt: DateTime.utc(2026, 11, 11),
        );

        final sync = FinanceSyncService(
          database: database,
          api: DioEntrySyncApi(dio),
          tokenProvider: tokenProvider,
        );
        final syncResult = await sync.syncPending();
        expect(syncResult.status, SyncRunStatus.completed);
        expect(syncResult.synced, 2);
        await database.close();
        database = null;

        database = AppDatabase.forTesting(NativeDatabase(file));
        final reopenedFinance = FinanceRepository(database);
        final entries = await reopenedFinance
            .watchEntriesForMonth(
              householdId: householdId,
              month: DateTime.utc(2026, 11),
            )
            .first;
        final summary = await reopenedFinance
            .watchSummaryForMonth(
              householdId: householdId,
              month: DateTime.utc(2026, 11),
            )
            .first;
        final outbox = await database.select(database.syncOutbox).get();

        expect(entries, hasLength(2));
        expect(entries.every((entry) => entry.syncState == 'synced'), isTrue);
        expect(summary.incomeInCents, 750000);
        expect(summary.expenseInCents, 12550);
        expect(summary.balanceInCents, 737450);
        expect(outbox, isEmpty);

        final remote = await dio.get<Map<String, dynamic>>(
          '/api/households/$householdId/entries',
          queryParameters: {'year': 2026, 'month': 11},
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
        expect(remote.data?['incomeInCents'], 750000);
        expect(remote.data?['expenseInCents'], 12550);
        expect(remote.data?['balanceInCents'], 737450);
        expect(remote.data?['entries'], hasLength(2));
        await database.close();
        database = null;
      } finally {
        await database?.close();
        dio.close(force: true);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
    skip: enabled ? false : 'Requires the explicitly enabled local MVP stack.',
  );
}
