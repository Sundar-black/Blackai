import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:black_ai/config/app_config.dart';
import 'package:black_ai/core/models/message_model.dart';

class AiService {
  final String _backendUrl = AppConfig.fullUrl;

  Stream<String> generateStreamingResponse(
    String sessionId,
    List<ChatMessage> history, {
    String? token,
    String language = 'English',
    String tone = 'Friendly',
    String length = 'Detailed',
    double temperature = 0.7,
    bool autoLanguage = true,
  }) async* {
    final client = IOClient(
      HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true,
    );

    try {
      final userMessage = history.last;

      final request = http.Request(
        'POST',
        Uri.parse('$_backendUrl/chat/sessions/$sessionId/messages/stream'),
      );

      final headers = {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      request.headers.addAll(headers);
      request.body = jsonEncode({
        'role': 'user',
        'content': userMessage.text,
        'attachments': userMessage.attachmentPaths,
        'language': language,
        'tone': tone,
        'length': length,
        'temperature': temperature,
        'autoLanguage': autoLanguage,
      });

      debugPrint("AI Service: Sending streaming request to ${request.url}");

      final response = await client.send(request);

      debugPrint(
        "AI Service: Response received. Status: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          yield chunk;
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint("AI Service Error Body: $errorBody");
        yield 'AI Error (${response.statusCode}): $errorBody';
      }
    } catch (e) {
      debugPrint('DEBUG: AI Backend Connection Error: $e');
      yield 'AI CONNECTION ERROR: $e. Please check your backend is running.';
    } finally {
      client.close();
    }
  }

  Future<String> generateResponse(
    String sessionId,
    List<ChatMessage> history, {
    String? token,
    String language = 'English',
    String tone = 'Friendly',
    String length = 'Detailed',
    double temperature = 0.7,
    bool autoLanguage = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/chat/sessions/$sessionId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Essential for ngrok
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'role': 'user',
          'content': history.last.text,
          'attachments': history.last.attachmentPaths,
          'language': language,
          'tone': tone,
          'length': length,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          try {
            final data = jsonDecode(response.body);
            return data['data']?['content'] ?? '';
          } catch (e) {
            debugPrint('DEBUG: Invalid JSON in AI response: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('DEBUG: Failed to generate AI response: $e');
    }
    return 'Error: Failed to connect to AI server.';
  }

  Future<String> generateChatTitle(
    String sessionId, {
    String? token,
    String? message,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse('$_backendUrl/chat/sessions/$sessionId/title'),
        headers: headers,
        body: message != null ? jsonEncode({'message': message}) : null,
      );

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          try {
            final data = jsonDecode(response.body);
            return data['data'] ?? '';
          } catch (e) {
            debugPrint('DEBUG: Invalid JSON in title response: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('DEBUG: Failed to generate chat title: $e');
    }
    return '';
  }
}
