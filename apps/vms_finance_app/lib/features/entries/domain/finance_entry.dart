enum FinanceEntryDirection {
  expense(0),
  income(1);

  const FinanceEntryDirection(this.databaseValue);

  final int databaseValue;

  static FinanceEntryDirection fromDatabase(int value) =>
      value == income.databaseValue ? income : expense;
}

class FinanceEntry {
  const FinanceEntry({
    required this.id,
    required this.householdId,
    required this.direction,
    required this.amountInCents,
    required this.description,
    required this.occurredAt,
    required this.syncState,
  });

  final String id;
  final String householdId;
  final FinanceEntryDirection direction;
  final int amountInCents;
  final String description;
  final DateTime occurredAt;
  final String syncState;
}

class MonthlyFinanceSummary {
  const MonthlyFinanceSummary({
    this.incomeInCents = 0,
    this.expenseInCents = 0,
  });

  final int incomeInCents;
  final int expenseInCents;

  int get balanceInCents => incomeInCents - expenseInCents;
}
