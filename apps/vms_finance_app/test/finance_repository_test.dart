import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/database/app_database.dart';
import 'package:vms_finance_app/core/database/finance_repository.dart';
import 'package:vms_finance_app/features/entries/domain/finance_entry.dart';

void main() {
  test('monthly queries are isolated by household', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = FinanceRepository(database);
    final month = DateTime.utc(2026, 11);

    await repository.addEntry(
      householdId: '11111111-1111-4111-8111-111111111111',
      direction: FinanceEntryDirection.income,
      amountInCents: 500000,
      description: 'Salary',
      occurredAt: DateTime.utc(2026, 11, 1),
    );
    await repository.addEntry(
      householdId: '22222222-2222-4222-8222-222222222222',
      direction: FinanceEntryDirection.expense,
      amountInCents: 999999,
      description: 'Other household',
      occurredAt: DateTime.utc(2026, 11, 2),
    );

    final entries = await repository
        .watchEntriesForMonth(
          householdId: '11111111-1111-4111-8111-111111111111',
          month: month,
        )
        .first;
    final summary = await repository
        .watchSummaryForMonth(
          householdId: '11111111-1111-4111-8111-111111111111',
          month: month,
        )
        .first;

    expect(entries, hasLength(1));
    expect(entries.single.description, 'Salary');
    expect(summary.incomeInCents, 500000);
    expect(summary.expenseInCents, 0);

    await database.close();
  });

  test('entry and outbox survive closing and reopening the database', () async {
    final directory = await Directory.systemTemp.createTemp(
      'vms-finance-reopen-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}finance.db');
    try {
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = FinanceRepository(database);
      await repository.addEntry(
        householdId: '11111111-1111-4111-8111-111111111111',
        direction: FinanceEntryDirection.expense,
        amountInCents: 4590,
        description: 'Persisted offline',
        occurredAt: DateTime.utc(2026, 11, 10),
      );
      await database.close();

      database = AppDatabase.forTesting(NativeDatabase(file));
      repository = FinanceRepository(database);
      final entries = await repository
          .watchEntriesForMonth(
            householdId: '11111111-1111-4111-8111-111111111111',
            month: DateTime.utc(2026, 11),
          )
          .first;
      final outbox = await database.select(database.syncOutbox).get();

      expect(entries, hasLength(1));
      expect(entries.single.description, 'Persisted offline');
      expect(outbox, hasLength(1));
      expect(outbox.single.entityId, entries.single.id);
      await database.close();
    } finally {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });
}
