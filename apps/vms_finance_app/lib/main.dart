import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/config/api_endpoint.dart';
import 'core/database/app_database.dart';
import 'core/database/finance_repository.dart';
import 'core/sync/connectivity_monitor.dart';
import 'core/sync/development_access_token_provider.dart';
import 'core/sync/entry_sync_api.dart';
import 'core/sync/finance_sync_service.dart';
import 'core/sync/secure_storage_access_token_provider.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/households/data/household_api.dart';
import 'features/households/data/household_repository.dart';

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
    this.householdStore,
  });

  final AppDatabase database;
  final bool closeDatabaseOnDispose;
  final FinanceSyncRunner? syncRunner;
  final ConnectivityMonitor? connectivityMonitor;
  final HouseholdStore? householdStore;

  @override
  State<VmsFinanceApp> createState() => _VmsFinanceAppState();
}

class _VmsFinanceAppState extends State<VmsFinanceApp> {
  late final FinanceRepository repository = FinanceRepository(widget.database);
  late final ConnectivityMonitor connectivityMonitor =
      widget.connectivityMonitor ?? PluginConnectivityMonitor();
  late final Uri? apiEndpoint = parseVmsApiBaseUrl(
    const String.fromEnvironment('VMS_API_BASE_URL'),
    allowLocalHttp: !kReleaseMode,
  );
  late final Dio? apiClient = apiEndpoint == null
      ? null
      : Dio(BaseOptions(baseUrl: apiEndpoint.toString()));
  late final AccessTokenProvider tokenProvider = selectAccessTokenProvider(
    releaseMode: kReleaseMode,
    apiEndpoint: apiEndpoint,
    developmentToken: const String.fromEnvironment(
      'VMS_DEVELOPMENT_ACCESS_TOKEN',
    ),
    secureProvider: const SecureStorageAccessTokenProvider(
      FlutterSecureStorage(),
    ),
  );
  late final FinanceSyncRunner? syncRunner =
      widget.syncRunner ?? _createConfiguredSyncRunner();
  late final HouseholdStore? householdStore =
      widget.householdStore ?? _createConfiguredHouseholdStore();

  FinanceSyncRunner? _createConfiguredSyncRunner() {
    final client = apiClient;
    if (client == null) return null;

    return FinanceSyncService(
      database: widget.database,
      api: DioEntrySyncApi(client),
      tokenProvider: tokenProvider,
    );
  }

  HouseholdStore? _createConfiguredHouseholdStore() {
    final client = apiClient;
    if (client == null) return null;
    return HouseholdRepository(
      database: widget.database,
      api: DioHouseholdApi(client),
      tokenProvider: tokenProvider,
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
        householdStore: householdStore,
      ),
    );
  }
}
