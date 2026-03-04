import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

enum ConnectivityStatus { connected, disconnected }

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.connected;
  ConnectivityStatus get status => _status;

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
      _status = status == InternetStatus.connected
          ? ConnectivityStatus.connected
          : ConnectivityStatus.disconnected;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
