import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:black_ai/config/app_config.dart';

class ApiClient {
  final http.Client _client = http.Client();
  final int _maxRetries = 3;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final headers = {
      "Content-Type": "application/json",
      "ngrok-skip-browser-warning": "true",
    };
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    return _requestWithRetry(
      () => _client.post(
        Uri.parse("${AppConfig.fullUrl}$path"),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
  }

  Future<dynamic> get(String path, {String? token}) async {
    final headers = {"ngrok-skip-browser-warning": "true"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    return _requestWithRetry(
      () =>
          _client.get(Uri.parse("${AppConfig.fullUrl}$path"), headers: headers),
    );
  }

  /// Pings the server health endpoint
  Future<void> ping() async {
    try {
      await _client
          .get(
            Uri.parse("${AppConfig.rootUrl}/health"),
            headers: {"ngrok-skip-browser-warning": "true"},
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore ping errors
    }
  }

  Future<T> _requestWithRetry<T>(
    Future<http.Response> Function() requestFn,
  ) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        final response = await requestFn();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (response.headers['content-type']?.contains('application/json') ??
              false) {
            try {
              return jsonDecode(response.body);
            } catch (e) {
              throw Exception("Invalid JSON response from server");
            }
          }
          throw Exception("Server returned non-JSON response");
        } else if (response.statusCode == 503 || response.statusCode == 502) {
          // Server might be starting up (Cold Start on Render)
          attempts++;
          await Future.delayed(Duration(seconds: 2 * attempts));
        } else {
          throw Exception(
            "Failed with status ${response.statusCode}: ${response.body}",
          );
        }
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
    throw Exception("Max retries reached");
  }
}
