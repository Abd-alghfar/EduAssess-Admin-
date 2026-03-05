import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

enum ConnectivityStatus { connected, disconnected }

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.connected;
  ConnectivityStatus get status => _status;
  Timer? _debounceTimer;

  StreamSubscription<InternetStatus>? _subscription;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    final hasConnection = await InternetConnection().hasInternetAccess;
    _status = hasConnection
        ? ConnectivityStatus.connected
        : ConnectivityStatus.disconnected;
    notifyListeners();

    _subscription = InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        _debounceTimer?.cancel();
        if (_status != ConnectivityStatus.connected) {
          _status = ConnectivityStatus.connected;
          notifyListeners();
        }
      } else {
        // Debounce: Wait 5 seconds before showing disconnected banner
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 5), () async {
          final stillOut = !(await InternetConnection().hasInternetAccess);
          if (stillOut && _status != ConnectivityStatus.disconnected) {
            _status = ConnectivityStatus.disconnected;
            notifyListeners();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
