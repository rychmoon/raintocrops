import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Represents app-level network status.
/// [offline] = no route / no internet.
/// [online] = internet reachable.
enum NetworkStatus { online, offline }

/// A robust network service:
/// 1) Listens to connectivity changes (wifi/mobile/none)
/// 2) Verifies real internet reachability
/// 3) Exposes stream + synchronous latest status
class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetConnection = InternetConnection();

  final StreamController<NetworkStatus> _statusController =
  StreamController<NetworkStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetStatus>? _internetSub;

  NetworkStatus _currentStatus = NetworkStatus.online;
  bool _isInitialized = false;

  NetworkStatus get currentStatus => _currentStatus;
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Initial check
    await _emitLatestStatus();

    // connectivity_plus v6 emits List<ConnectivityResult>
    _connectivitySub = _connectivity.onConnectivityChanged.listen((_) async {
      await _emitLatestStatus();
    });

    // Extra reliability: internet checker stream
    _internetSub = _internetConnection.onStatusChange.listen((_) async {
      await _emitLatestStatus();
    });
  }

  Future<void> _emitLatestStatus() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasRoute = !connectivityResults.contains(ConnectivityResult.none);

      if (!hasRoute) {
        _setStatus(NetworkStatus.offline);
        return;
      }

      final hasInternet = await _internetConnection.hasInternetAccess;
      _setStatus(hasInternet ? NetworkStatus.online : NetworkStatus.offline);
    } catch (e) {
      debugPrint('NetworkService _emitLatestStatus error: $e');
      _setStatus(NetworkStatus.offline);
    }
  }

  void _setStatus(NetworkStatus status) {
    if (_currentStatus == status) return;
    _currentStatus = status;
    _statusController.add(_currentStatus);
  }

  Future<bool> isOnline() async {
    await _emitLatestStatus();
    return _currentStatus == NetworkStatus.online;
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _internetSub?.cancel();
    await _statusController.close();
  }
}