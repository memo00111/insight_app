import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// مدير الاتصال بالإنترنت
/// يستخدم للتحقق من حالة الاتصال بالإنترنت وإخطار المستمعين بالتغييرات
class ConnectionManager {
  // Singleton instance
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  // Connectivity instance
  final Connectivity _connectivity = Connectivity();
  
  // Stream controller for connection status
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  // Current connection status
  bool _hasConnection = true;
  
  // Stream subscription for connectivity changes
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Getters
  Stream<bool> get connectionStream => _connectionStatusController.stream;
  bool get hasConnection => _hasConnection;

  /// Initialize connection manager
  Future<void> initialize() async {
    try {
      // Check initial connection status
      _hasConnection = await _checkConnection();
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) async {
        _hasConnection = result != ConnectivityResult.none;
        _connectionStatusController.add(_hasConnection);
        debugPrint('🔌 تغيرت حالة الاتصال: ${_hasConnection ? 'متصل' : 'غير متصل'}');
      });
      
      debugPrint('🔌 تم تهيئة مدير الاتصال. الحالة الأولية: ${_hasConnection ? 'متصل' : 'غير متصل'}');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة مدير الاتصال: $e');
      // Set default value in case of error
      _hasConnection = true;
    }
  }

  /// Check current connection status
  Future<bool> _checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('❌ خطأ في فحص حالة الاتصال: $e');
      return true; // Assume there is connection in case of error
    }
  }

  /// Dispose connection manager
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
  }
}
