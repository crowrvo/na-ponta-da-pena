import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/features/entries/domain/finance_entries_repository.dart';
import 'package:vms_finance_app/features/entries/domain/finance_entry.dart';
import 'package:vms_finance_app/features/entries/presentation/finance_overview_cubit.dart';
import 'package:vms_finance_app/features/entries/presentation/finance_overview_page.dart';

void main() {
  const householdId = '11111111-1111-4111-8111-111111111111';
  final november = DateTime.utc(2026, 11);

  test('cubit scopes reads and writes to the active household', () async {
    final repository = FakeFinanceEntriesRepository();
    final cubit = FinanceOverviewCubit(
      repository: repository,
      householdId: householdId,
      now: november,
    );

    await cubit.initialize();
    await cubit.showNextMonth();
    await cubit.addEntry(
      direction: FinanceEntryDirection.expense,
      amountInCents: 1250,
      description: 'Lunch',
      occurredAt: DateTime.utc(2026, 11, 10),
    );

    expect(repository.watchedHouseholdIds, everyElement(householdId));
    expect(repository.lastEntriesMonth, DateTime.utc(2026, 12));
    expect(repository.added.single.householdId, householdId);
    await cubit.close();
    await repository.close();
  });

  test('cubit refuses an unassigned household', () {
    expect(
      () => FinanceOverviewCubit(
        repository: FakeFinanceEntriesRepository(),
        householdId: 'local-unassigned',
      ),
      throwsArgumentError,
    );
  });

  testWidgets('shows monthly summary, entries and empty navigation state', (
    tester,
  ) async {
    final repository = FakeFinanceEntriesRepository(
      entries: [
        FinanceEntry(
          id: 'entry-1',
          householdId: householdId,
          direction: FinanceEntryDirection.income,
          amountInCents: 500000,
          description: 'Salário',
          occurredAt: DateTime.utc(2026, 11, 5),
          syncState: 'synced',
        ),
      ],
      summary: const MonthlyFinanceSummary(incomeInCents: 500000),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FinanceOverviewPage(
          repository: repository,
          householdId: householdId,
          householdName: 'Casa',
          now: november,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Novembro 2026'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('R\$ 5.000,00'), findsAtLeastNWidgets(2));

    final nextMonth = tester.widget<IconButton>(
      find.byKey(const Key('next-month')),
    );
    nextMonth.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Dezembro 2026'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await repository.close();
  });

  testWidgets('validates and saves an income entry', (tester) async {
    final repository = FakeFinanceEntriesRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceOverviewPage(
          repository: repository,
          householdId: householdId,
          now: november,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();

    expect(find.text('Informe a descrição.'), findsOneWidget);
    expect(
      find.text('Informe um valor maior que zero, com até 2 decimais.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('entry-description')),
      'Freelance',
    );
    await tester.enterText(find.byKey(const Key('entry-amount')), '1250,75');
    await tester.tap(find.text('Receita'));
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pumpAndSettle();

    final added = repository.added.single;
    expect(added.householdId, householdId);
    expect(added.direction, FinanceEntryDirection.income);
    expect(added.amountInCents, 125075);
    expect(added.description, 'Freelance');
    expect(find.byKey(const Key('entry-save')), findsNothing);
    expect(find.text('Novo lançamento'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await repository.close();
  });
}

class AddedEntry {
  const AddedEntry({
    required this.householdId,
    required this.direction,
    required this.amountInCents,
    required this.description,
    required this.occurredAt,
  });

  final String householdId;
  final FinanceEntryDirection direction;
  final int amountInCents;
  final String description;
  final DateTime occurredAt;
}

class FakeFinanceEntriesRepository implements FinanceEntriesRepository {
  FakeFinanceEntriesRepository({
    List<FinanceEntry> entries = const [],
    MonthlyFinanceSummary summary = const MonthlyFinanceSummary(),
  }) : _entries = entries,
       _summary = summary;

  final List<FinanceEntry> _entries;
  final MonthlyFinanceSummary _summary;
  final StreamController<int> _pending = StreamController.broadcast();
  final List<String> watchedHouseholdIds = [];
  final List<AddedEntry> added = [];
  DateTime? lastEntriesMonth;

  @override
  Stream<List<FinanceEntry>> watchEntriesForMonth({
    required String householdId,
    required DateTime month,
  }) {
    watchedHouseholdIds.add(householdId);
    lastEntriesMonth = month;
    return Stream.value(_entries);
  }

  @override
  Stream<MonthlyFinanceSummary> watchSummaryForMonth({
    required String householdId,
    required DateTime month,
  }) {
    watchedHouseholdIds.add(householdId);
    return Stream.value(_summary);
  }

  @override
  Stream<int> watchPendingOperations() async* {
    yield 0;
    yield* _pending.stream;
  }

  @override
  Future<void> addEntry({
    required String householdId,
    required FinanceEntryDirection direction,
    required int amountInCents,
    required String description,
    required DateTime occurredAt,
  }) async {
    added.add(
      AddedEntry(
        householdId: householdId,
        direction: direction,
        amountInCents: amountInCents,
        description: description,
        occurredAt: occurredAt,
      ),
    );
  }

  Future<void> close() => _pending.close();
}
