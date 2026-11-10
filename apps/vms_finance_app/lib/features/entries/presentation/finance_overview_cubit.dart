import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/finance_entries_repository.dart';
import '../domain/finance_entry.dart';
import 'finance_overview_state.dart';

class FinanceOverviewCubit extends Cubit<FinanceOverviewState> {
  FinanceOverviewCubit({
    required FinanceEntriesRepository repository,
    DateTime? now,
  }) : _repository = repository,
       super(FinanceOverviewState.initial(now ?? DateTime.now()));

  final FinanceEntriesRepository _repository;
  StreamSubscription<List<FinanceEntry>>? _entriesSubscription;
  StreamSubscription<MonthlyFinanceSummary>? _summarySubscription;
  StreamSubscription<int>? _pendingSubscription;

  Future<void> initialize() async {
    _pendingSubscription ??= _repository.watchPendingOperations().listen(
      (count) => emit(state.copyWith(pendingOperations: count)),
      onError: _handleStreamError,
    );
    await selectMonth(state.month);
  }

  Future<void> selectMonth(DateTime month) async {
    final normalized = DateTime.utc(month.year, month.month);
    emit(
      state.copyWith(
        month: normalized,
        status: FinanceOverviewStatus.loading,
        clearError: true,
      ),
    );
    await _entriesSubscription?.cancel();
    await _summarySubscription?.cancel();
    _entriesSubscription = _repository
        .watchEntriesForMonth(normalized)
        .listen(
          (entries) => emit(
            state.copyWith(
              entries: entries,
              status: FinanceOverviewStatus.ready,
              clearError: true,
            ),
          ),
          onError: _handleStreamError,
        );
    _summarySubscription = _repository
        .watchSummaryForMonth(normalized)
        .listen(
          (summary) => emit(state.copyWith(summary: summary)),
          onError: _handleStreamError,
        );
  }

  Future<bool> addEntry({
    required FinanceEntryDirection direction,
    required int amountInCents,
    required String description,
    required DateTime occurredAt,
  }) async {
    emit(
      state.copyWith(status: FinanceOverviewStatus.saving, clearError: true),
    );
    try {
      await _repository.addEntry(
        householdId: 'local-unassigned',
        direction: direction,
        amountInCents: amountInCents,
        description: description,
        occurredAt: occurredAt,
      );
      emit(state.copyWith(status: FinanceOverviewStatus.ready));
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          status: FinanceOverviewStatus.failure,
          errorMessage: 'Não foi possível salvar o lançamento.',
        ),
      );
      return false;
    }
  }

  void _handleStreamError(Object _) {
    emit(
      state.copyWith(
        status: FinanceOverviewStatus.failure,
        errorMessage: 'Não foi possível carregar os dados locais.',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    await _summarySubscription?.cancel();
    await _pendingSubscription?.cancel();
    return super.close();
  }
}
