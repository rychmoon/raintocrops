import 'dart:async';
import 'package:flutter/foundation.dart';
import 'network_service.dart';

class NetworkController extends ChangeNotifier {
  final NetworkService _networkService;
  StreamSubscription<NetworkStatus>? _sub;

  NetworkController({NetworkService? networkService})
      : _networkService = networkService ?? NetworkService.instance;

  NetworkStatus _status = NetworkStatus.online;
  NetworkStatus get status => _status;

  bool get isOnline => _status == NetworkStatus.online;
  bool get isOffline => _status == NetworkStatus.offline;

  Future<void> init() async {
    await _networkService.init();
    _status = _networkService.currentStatus;
    notifyListeners();

    _sub ??= _networkService.statusStream.listen((newStatus) {
      _status = newStatus;
      notifyListeners();
    });
  }

  Future<bool> checkNow() => _networkService.isOnline();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}