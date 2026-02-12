import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:black_ai/feature/service/api_client.dart';

class KeepAliveService {
  final ApiClient _apiClient = ApiClient();
  Timer? _timer;

  /// Starts the keep-alive ping loop
  void start() {
    // Ping every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (kDebugMode) {
        debugPrint("KeepAlive: Pinging server...");
      }
      _apiClient.ping();
    });

    // Immediate ping on start
    _apiClient.ping();
  }

  /// Stops the keep-alive ping loop
  void stop() {
    _timer?.cancel();
  }
}
