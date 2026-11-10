import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/config/api_endpoint.dart';
import 'core/database/app_database.dart';
import 'core/database/finance_repository.dart';
import 'core/sync/connectivity_monitor.dart';
import 'core/sync/entry_sync_api.dart';
import 'core/sync/finance_sync_service.dart';
import 'core/sync/secure_storage_access_token_provider.dart';
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
    this.syncRunner,
    this.connectivityMonitor,
  });

  final AppDatabase database;
  final bool closeDatabaseOnDispose;
  final FinanceSyncRunner? syncRunner;
  final ConnectivityMonitor? connectivityMonitor;

  @override
  State<VmsFinanceApp> createState() => _VmsFinanceAppState();
}

class _VmsFinanceAppState extends State<VmsFinanceApp> {
  late final FinanceRepository repository = FinanceRepository(widget.database);
  late final ConnectivityMonitor connectivityMonitor =
      widget.connectivityMonitor ?? PluginConnectivityMonitor();
  late final FinanceSyncRunner? syncRunner =
      widget.syncRunner ?? _createConfiguredSyncRunner();

  FinanceSyncRunner? _createConfiguredSyncRunner() {
    const apiBaseUrl = String.fromEnvironment('VMS_API_BASE_URL');
    final endpoint = parseVmsApiBaseUrl(
      apiBaseUrl,
      allowLocalHttp: !kReleaseMode,
    );
    if (endpoint == null) return null;

    return FinanceSyncService(
      database: widget.database,
      api: DioEntrySyncApi(Dio(BaseOptions(baseUrl: endpoint.toString()))),
      tokenProvider: const SecureStorageAccessTokenProvider(
        FlutterSecureStorage(),
      ),
    );
  }

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
      home: DashboardPage(
        repository: repository,
        syncRunner: syncRunner,
        connectivityMonitor: connectivityMonitor,
      ),
    );
  }
}
