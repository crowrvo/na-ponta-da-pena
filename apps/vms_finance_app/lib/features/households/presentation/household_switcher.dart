import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/sync/connectivity_monitor.dart';
import '../data/household_repository.dart';
import '../domain/household.dart';
import 'household_cubit.dart';
import 'household_state.dart';

class HouseholdSwitcher extends StatelessWidget {
  const HouseholdSwitcher({
    super.key,
    required this.store,
    required this.connectivityMonitor,
    required this.onOpenHousehold,
  });

  final HouseholdStore store;
  final ConnectivityMonitor connectivityMonitor;
  final ValueChanged<HouseholdSummary> onOpenHousehold;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HouseholdCubit(repository: store, connectivity: connectivityMonitor)
            ..initialize(),
      child: _HouseholdSwitcherView(onOpenHousehold: onOpenHousehold),
    );
  }
}

class _HouseholdSwitcherView extends StatelessWidget {
  const _HouseholdSwitcherView({required this.onOpenHousehold});

  final ValueChanged<HouseholdSummary> onOpenHousehold;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HouseholdCubit, HouseholdState>(
      builder: (context, state) {
        if (state.status == HouseholdStatus.loading ||
            state.status == HouseholdStatus.initial) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Carregando famílias',
            ),
          );
        }

        final canMutate =
            state.status != HouseholdStatus.offline &&
            state.status != HouseholdStatus.authenticationRequired &&
            state.status != HouseholdStatus.saving;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Famílias', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (state.status == HouseholdStatus.offline)
              const _StatusBanner(
                icon: Icons.cloud_off,
                message:
                    'Offline: mostrando as famílias salvas neste dispositivo.',
              ),
            if (state.status == HouseholdStatus.authenticationRequired)
              const _StatusBanner(
                icon: Icons.lock_outline,
                message: 'Entre na sua conta para carregar suas famílias.',
              ),
            if (state.status == HouseholdStatus.failure)
              _StatusBanner(
                icon: Icons.error_outline,
                message:
                    state.errorMessage ??
                    'Não foi possível carregar as famílias.',
                action: TextButton(
                  onPressed: () => context.read<HouseholdCubit>().refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ),
            if (state.households.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Você ainda não participa de uma família financeira.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              RadioGroup<String>(
                groupValue: state.activeHouseholdId,
                onChanged: (householdId) {
                  if (householdId != null &&
                      state.status != HouseholdStatus.saving) {
                    context.read<HouseholdCubit>().selectHousehold(householdId);
                  }
                },
                child: Column(
                  children: state.households
                      .map(
                        (household) => RadioListTile<String>(
                          value: household.id,
                          enabled: state.status != HouseholdStatus.saving,
                          title: Text(household.name),
                          subtitle: Text(
                            household.role == HouseholdRole.owner
                                ? 'Responsável'
                                : 'Membro',
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            if (state.activeHousehold case final active?) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => onOpenHousehold(active),
                icon: const Icon(Icons.arrow_forward),
                label: Text('Abrir ${active.name}'),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: canMutate
                      ? () => _showCreateDialog(context)
                      : null,
                  icon: const Icon(Icons.add_home_outlined),
                  label: const Text('Criar família'),
                ),
                OutlinedButton.icon(
                  onPressed: canMutate
                      ? () => _showInvitationDialog(context)
                      : null,
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Aceitar convite'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final cubit = context.read<HouseholdCubit>();
    await showDialog<void>(
      context: context,
      builder: (_) => _CreateHouseholdDialog(cubit: cubit),
    );
  }

  Future<void> _showInvitationDialog(BuildContext context) async {
    final cubit = context.read<HouseholdCubit>();
    await showDialog<void>(
      context: context,
      builder: (_) => _InvitationDialog(cubit: cubit),
    );
  }
}

class _CreateHouseholdDialog extends StatefulWidget {
  const _CreateHouseholdDialog({required this.cubit});

  final HouseholdCubit cubit;

  @override
  State<_CreateHouseholdDialog> createState() => _CreateHouseholdDialogState();
}

class _CreateHouseholdDialogState extends State<_CreateHouseholdDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Criar família'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        maxLength: 120,
        decoration: const InputDecoration(labelText: 'Nome da família'),
        validator: (value) {
          final name = value?.trim() ?? '';
          if (name.isEmpty) return 'Informe o nome da família.';
          return null;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () async {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          final success = await widget.cubit.createHousehold(_controller.text);
          if (success && context.mounted) Navigator.pop(context);
        },
        child: const Text('Criar'),
      ),
    ],
  );
}

class _InvitationDialog extends StatefulWidget {
  const _InvitationDialog({required this.cubit});

  final HouseholdCubit cubit;

  @override
  State<_InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<_InvitationDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Aceitar convite'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        maxLength: 512,
        decoration: const InputDecoration(labelText: 'Token do convite'),
        validator: (value) =>
            (value?.trim().isEmpty ?? true) ? 'Cole o token do convite.' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () async {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          final success = await widget.cubit.acceptInvitation(_controller.text);
          _controller.clear();
          if (success && context.mounted) Navigator.pop(context);
        },
        child: const Text('Aceitar'),
      ),
    ],
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(message),
        trailing: action,
      ),
    );
  }
}
