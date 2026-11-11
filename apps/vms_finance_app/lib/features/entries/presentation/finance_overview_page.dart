import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/finance_entries_repository.dart';
import '../domain/finance_entry.dart';
import 'finance_overview_cubit.dart';
import 'finance_overview_state.dart';

class FinanceOverviewPage extends StatelessWidget {
  const FinanceOverviewPage({
    super.key,
    required this.repository,
    required this.householdId,
    this.householdName,
    this.now,
  });

  final FinanceEntriesRepository repository;
  final String householdId;
  final String? householdName;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinanceOverviewCubit(
        repository: repository,
        householdId: householdId,
        now: now,
      )..initialize(),
      child: Scaffold(
        appBar: AppBar(title: Text(householdName ?? 'Lançamentos')),
        body: const FinanceOverviewView(),
        floatingActionButton: const _AddEntryButton(),
      ),
    );
  }
}

class FinanceOverviewView extends StatelessWidget {
  const FinanceOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceOverviewCubit, FinanceOverviewState>(
      builder: (context, state) {
        return Column(
          children: [
            _MonthSelector(month: state.month),
            _SummaryPanel(summary: state.summary),
            if (state.pendingOperations > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${state.pendingOperations} operação(ões) aguardando sincronização',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            if (state.errorMessage case final message?)
              MaterialBanner(
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => context
                        .read<FinanceOverviewCubit>()
                        .selectMonth(state.month),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            Expanded(child: _EntryList(state: state)),
          ],
        );
      },
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceOverviewCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('previous-month'),
            tooltip: 'Mês anterior',
            onPressed: cubit.showPreviousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              _monthLabel(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('next-month'),
            tooltip: 'Próximo mês',
            onPressed: cubit.showNextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.summary});

  final MonthlyFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Receitas',
                  value: summary.incomeInCents,
                  color: Colors.green.shade700,
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'Despesas',
                  value: summary.expenseInCents,
                  color: Colors.red.shade700,
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'Saldo',
                  value: summary.balanceInCents,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatCurrency(value),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.state});

  final FinanceOverviewState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == FinanceOverviewStatus.loading &&
        state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == FinanceOverviewStatus.failure &&
        state.entries.isEmpty) {
      return const Center(child: Text('Não foi possível carregar o mês.'));
    }
    if (state.entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum lançamento neste mês.\nUse o botão + para começar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: state.entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        final income = entry.direction == FinanceEntryDirection.income;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: income
                ? Colors.green.withValues(alpha: 0.12)
                : Colors.red.withValues(alpha: 0.12),
            child: Icon(
              income ? Icons.arrow_downward : Icons.arrow_upward,
              color: income ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          title: Text(entry.description),
          subtitle: Text(
            '${_dateLabel(entry.occurredAt)} · ${_syncLabel(entry.syncState)}',
          ),
          trailing: Text(
            '${income ? '+' : '-'} ${_formatCurrency(entry.amountInCents)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: income ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        );
      },
    );
  }
}

class _AddEntryButton extends StatelessWidget {
  const _AddEntryButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      key: const Key('add-entry'),
      onPressed: () {
        final cubit = context.read<FinanceOverviewCubit>();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: _EntryForm(initialMonth: cubit.state.month),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Novo lançamento'),
    );
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  FinanceEntryDirection _direction = FinanceEntryDirection.expense;
  late DateTime _occurredAt = _initialDate(widget.initialMonth);
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Novo lançamento',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              SegmentedButton<FinanceEntryDirection>(
                key: const Key('entry-direction'),
                segments: const [
                  ButtonSegment(
                    value: FinanceEntryDirection.expense,
                    label: Text('Despesa'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: FinanceEntryDirection.income,
                    label: Text('Receita'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (selection) =>
                    setState(() => _direction = selection.single),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('entry-description'),
                controller: _descriptionController,
                maxLength: 240,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final normalized = value?.trim() ?? '';
                  if (normalized.isEmpty) return 'Informe a descrição.';
                  if (normalized.length > 240) {
                    return 'Use no máximo 240 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('entry-amount'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _parseAmountInCents(value) == null
                    ? 'Informe um valor maior que zero, com até 2 decimais.'
                    : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('entry-date'),
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('Data: ${_dateLabel(_occurredAt)}'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('entry-save'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(9999, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => _occurredAt = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmountInCents(_amountController.text)!;
    setState(() => _saving = true);
    final saved = await context.read<FinanceOverviewCubit>().addEntry(
      direction: _direction,
      amountInCents: amount,
      description: _descriptionController.text,
      occurredAt: _occurredAt,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o lançamento.')),
      );
    }
  }
}

int? _parseAmountInCents(String? raw) {
  final value = raw?.trim().replaceAll(' ', '') ?? '';
  final match = RegExp(r'^(\d+)(?:[,.](\d{1,2}))?$').firstMatch(value);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return null;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final cents = whole * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
  return cents > 0 ? cents : null;
}

DateTime _initialDate(DateTime month) {
  final now = DateTime.now();
  if (now.year == month.year && now.month == month.month) return now;
  return DateTime(month.year, month.month);
}

String _monthLabel(DateTime month) {
  const names = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${names[month.month - 1]} ${month.year}';
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _syncLabel(String state) => switch (state) {
  'synced' => 'Sincronizado',
  'conflict' => 'Conflito',
  'local-only' => 'Somente neste dispositivo',
  _ => 'Aguardando sincronização',
};

String _formatCurrency(int cents) {
  final negative = cents < 0;
  final absolute = cents.abs();
  final whole = absolute ~/ 100;
  final decimal = (absolute % 100).toString().padLeft(2, '0');
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}R\$ ${buffer.toString()},$decimal';
}
