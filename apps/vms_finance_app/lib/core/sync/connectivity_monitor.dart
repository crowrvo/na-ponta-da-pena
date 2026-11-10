import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class ConnectivityMonitor {
  Future<bool> get isOnline;

  Stream<bool> get onConnectivityChanged;
}

class PluginConnectivityMonitor implements ConnectivityMonitor {
  PluginConnectivityMonitor([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async =>
      _hasConnection(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection).distinct();

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
