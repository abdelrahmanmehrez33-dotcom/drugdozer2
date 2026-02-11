import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> init() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    // In newer connectivity_plus, it returns a list. 
    // It's connected if the list is not empty and doesn't only contain 'none'.
    _isConnected = results.isNotEmpty && 
        !results.every((result) => result == ConnectivityResult.none);
    
    if (wasConnected != _isConnected) {
      _connectivityController.add(_isConnected);
      debugPrint('Connectivity changed: $_isConnected');
    }
  }

  /// Check if currently connected
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

/// Mixin for widgets that need connectivity awareness
mixin ConnectivityAware<T extends StatefulWidget> on State<T> {
  late StreamSubscription<bool> _connectivitySubscription;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService().isConnected;
    _connectivitySubscription = ConnectivityService()
        .connectivityStream
        .listen((isConnected) {
      if (mounted) {
        setState(() => _isOnline = isConnected);
        onConnectivityChanged(isConnected);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  /// Override this to handle connectivity changes
  void onConnectivityChanged(bool isConnected) {}
}
