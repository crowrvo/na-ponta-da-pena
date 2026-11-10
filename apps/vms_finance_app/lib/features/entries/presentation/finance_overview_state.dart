import '../domain/finance_entry.dart';

enum FinanceOverviewStatus { initial, loading, ready, saving, failure }

class FinanceOverviewState {
  const FinanceOverviewState({
    required this.month,
    this.status = FinanceOverviewStatus.initial,
    this.entries = const [],
    this.summary = const MonthlyFinanceSummary(),
    this.pendingOperations = 0,
    this.errorMessage,
  });

  factory FinanceOverviewState.initial(DateTime now) =>
      FinanceOverviewState(month: DateTime.utc(now.year, now.month));

  final DateTime month;
  final FinanceOverviewStatus status;
  final List<FinanceEntry> entries;
  final MonthlyFinanceSummary summary;
  final int pendingOperations;
  final String? errorMessage;

  FinanceOverviewState copyWith({
    DateTime? month,
    FinanceOverviewStatus? status,
    List<FinanceEntry>? entries,
    MonthlyFinanceSummary? summary,
    int? pendingOperations,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FinanceOverviewState(
      month: month ?? this.month,
      status: status ?? this.status,
      entries: entries ?? this.entries,
      summary: summary ?? this.summary,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
