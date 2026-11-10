import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/database/finance_repository.dart';
import 'features/dashboard/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(VmsFinanceApp(database: AppDatabase()));
}

class VmsFinanceApp extends StatefulWidget {
  const VmsFinanceApp({
    super.key,
    required this.database,
    this.closeDatabaseOnDispose = true,
  });

  final AppDatabase database;
  final bool closeDatabaseOnDispose;

  @override
  State<VmsFinanceApp> createState() => _VmsFinanceAppState();
}

class _VmsFinanceAppState extends State<VmsFinanceApp> {
  late final FinanceRepository repository = FinanceRepository(widget.database);

  @override
  void dispose() {
    if (widget.closeDatabaseOnDispose) {
      widget.database.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VMS Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C66)),
        useMaterial3: true,
      ),
      home: DashboardPage(repository: repository),
    );
  }
}
