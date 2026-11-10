import 'package:flutter/material.dart';

import '../../core/database/finance_repository.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VMS Finance')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Finanças da família',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'A base offline está pronta. Sincronização e login serão habilitados no próximo incremento.',
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
            const Spacer(),
            FilledButton.icon(
              onPressed: () async {
                await repository.addDraftExpense(
                  amountInCents: 1250,
                  description: 'Lançamento local de demonstração',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lançamento salvo no dispositivo.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar lançamento local de teste'),
            ),
          ],
        ),
      ),
    );
  }
}
