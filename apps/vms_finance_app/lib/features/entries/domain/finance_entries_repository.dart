import 'finance_entry.dart';

abstract interface class FinanceEntriesRepository {
  Stream<List<FinanceEntry>> watchEntriesForMonth(DateTime month);

  Stream<MonthlyFinanceSummary> watchSummaryForMonth(DateTime month);

  Stream<int> watchPendingOperations();

  Future<void> addEntry({
    required String householdId,
    required FinanceEntryDirection direction,
    required int amountInCents,
    required String description,
    required DateTime occurredAt,
  });
}
