import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/database/finance_repository.dart';
import '../../core/sync/connectivity_monitor.dart';
import '../../core/sync/finance_sync_service.dart';
import '../entries/presentation/finance_overview_page.dart';
import '../households/data/household_repository.dart';
import '../households/domain/household.dart';
import '../households/presentation/household_switcher.dart';
import '../sync/presentation/finance_sync_cubit.dart';
import '../sync/presentation/finance_sync_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.repository,
    required this.connectivityMonitor,
    this.syncRunner,
    this.householdStore,
  });

  final FinanceRepository repository;
  final FinanceSyncRunner? syncRunner;
  final ConnectivityMonitor connectivityMonitor;
  final HouseholdStore? householdStore;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinanceSyncCubit(
        connectivity: connectivityMonitor,
        runner: syncRunner,
      )..initialize(),
      child: Scaffold(
        appBar: AppBar(title: const Text('VMS Finance')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Finanças da família',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seus lançamentos permanecem disponíveis no dispositivo mesmo sem conexão.',
            ),
            const SizedBox(height: 24),
            if (householdStore case final store?)
              HouseholdSwitcher(
                store: store,
                connectivityMonitor: connectivityMonitor,
                onOpenHousehold: (household) =>
                    _openHousehold(context, household),
              )
            else
              const Card(
                child: ListTile(
                  leading: Icon(Icons.settings_ethernet),
                  title: Text('Famílias indisponíveis'),
                  subtitle: Text(
                    'Configure uma origem segura da API para entrar ou criar uma família.',
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: StreamBuilder<int>(
                  stream: repository.watchPendingOperations(),
                  initialData: 0,
                  builder: (context, snapshot) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Operações aguardando sincronização'),
                      Text(
                        '${snapshot.data ?? 0}',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SyncCard(),
          ],
        ),
      ),
    );
  }

  void _openHousehold(BuildContext context, HouseholdSummary household) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FinanceOverviewPage(
          repository: repository,
          householdId: household.id,
          householdName: household.name,
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceSyncCubit, FinanceSyncState>(
      builder: (context, state) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sincronização',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_statusMessage(state)),
              if (state.conflicts > 0) ...[
                const SizedBox(height: 4),
                Text('${state.conflicts} operação(ões) com conflito.'),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.canSync
                    ? () => context.read<FinanceSyncCubit>().syncNow()
                    : null,
                icon: state.status == FinanceSyncStatus.syncing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Sincronizar agora'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusMessage(FinanceSyncState state) => switch (state.status) {
    FinanceSyncStatus.initial => 'Verificando conectividade…',
    FinanceSyncStatus.notConfigured =>
      'A API ainda não foi configurada neste aplicativo.',
    FinanceSyncStatus.offline =>
      'Sem conexão. Os dados continuam salvos localmente.',
    FinanceSyncStatus.syncing => 'Sincronizando com segurança…',
    FinanceSyncStatus.synchronized =>
      state.synced == 0
          ? 'Tudo está atualizado.'
          : '${state.synced} operação(ões) sincronizada(s).',
    FinanceSyncStatus.authenticationRequired =>
      'Entre na sua conta para sincronizar os dados da família.',
    FinanceSyncStatus.failure =>
      'Não foi possível sincronizar agora. Tentaremos novamente.',
  };
}
