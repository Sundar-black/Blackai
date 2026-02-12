import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:black_ai/core/models/message_model.dart';
import 'package:black_ai/core/models/session_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:black_ai/feature/service/ai_service.dart';
import 'package:black_ai/config/app_config.dart';

class ChatProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final AiService _aiService = AiService();
  final List<ChatSession> _sessions = [];
  String? _currentUserEmail;
  String? _currentUserName;
  String? _currentUserAvatar;
  String? _token;
  String? _activeSessionId;
  bool _isLoading = false;
  final List<String> _selectedAttachments = [];

  ChatProvider(this._prefs) {
    final userEmail = _prefs.getString("user_email");
    final token = _prefs.getString("token");
    _currentUserName = _prefs.getString("user_name");
    _currentUserAvatar = _prefs.getString("user_avatar");

    if (userEmail != null && token != null) {
      updateUser(userEmail, token);
    }
  }

  bool get isLoggedIn => _token != null;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  String? get currentUserAvatar => _currentUserAvatar;

  static const String _baseSessionsKey = 'chat_sessions_v2';
  static const String _baseActiveSessionKey = 'active_session_id';

  String get _sessionsKey => _currentUserEmail != null
      ? '${_baseSessionsKey}_${_currentUserEmail!.replaceAll('.', '_')}'
      : _baseSessionsKey;

  String get _activeSessionKey => _currentUserEmail != null
      ? '${_baseActiveSessionKey}_${_currentUserEmail!.replaceAll('.', '_')}'
      : _baseActiveSessionKey;

  void updateUser(String? email, String? token) {
    if (_currentUserEmail == email && _token == token) return;
    _currentUserEmail = email;
    _token = token;
    _sessions.clear();
    _activeSessionId = null;
    if (_currentUserEmail != null) {
      _loadSessions();
    } else {
      notifyListeners();
    }
  }

  List<ChatSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  List<String> get selectedAttachments => _selectedAttachments;

  ChatSession? get activeSession {
    if (_sessions.isEmpty) {
      _activeSessionId = null;
      return null;
    }

    _activeSessionId ??= _sessions.first.id;

    return _sessions.firstWhere(
      (s) => s.id == _activeSessionId,
      orElse: () => _sessions.first,
    );
  }

  List<ChatMessage> get messages => activeSession?.messages ?? [];

  void _loadSessions() {
    final String? sessionsJson = _prefs.getString(_sessionsKey);
    if (sessionsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _sessions.clear();
        _sessions.addAll(decoded.map((s) => ChatSession.fromJson(s)));

        // Sort: Pinned first, then by date (newest first)
        _sessions.sort((a, b) {
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          return b.createdAt.compareTo(a.createdAt);
        });

        final savedActiveId = _prefs.getString(_activeSessionKey);
        if (savedActiveId != null &&
            _sessions.any((s) => s.id == savedActiveId)) {
          _activeSessionId = savedActiveId;
        } else if (_sessions.isNotEmpty) {
          _activeSessionId = _sessions.first.id;
        }
      } catch (e) {
        debugPrint('Error loading sessions: $e');
      }
    }
    notifyListeners();
    if (_currentUserEmail != null) {
      syncSessionsFromServer();
    }
  }

  Future<void> syncSessionsFromServer() async {
    if (_token == null) return;
    try {
      final baseUrl = AppConfig.fullUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/chat/sessions'),
        headers: {
          'Authorization': 'Bearer $_token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];

        final remoteSessions = data
            .map(
              (json) => ChatSession(
                id: json['_id'],
                title: json['title'] ?? 'New Chat',
                messages: (json['messages'] as List)
                    .map((m) => ChatMessage.fromJson(m))
                    .toList(),
                createdAt: DateTime.parse(json['createdAt']),
                isPinned: json['isPinned'] ?? false,
              ),
            )
            .toList();

        // Merge or replace? Let's replace for a clean sync from server
        _sessions.clear();
        _sessions.addAll(remoteSessions);

        // Sort
        _sessions.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        if (_activeSessionId == null && _sessions.isNotEmpty) {
          _activeSessionId = _sessions.first.id;
        }

        _saveSessions();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing sessions: $e');
    }
  }

  void _saveSessions() {
    final String sessionsJson = jsonEncode(
      _sessions.map((s) => s.toJson()).toList(),
    );
    _prefs.setString(_sessionsKey, sessionsJson);
    if (_activeSessionId != null) {
      _prefs.setString(_activeSessionKey, _activeSessionId!);
    } else {
      _prefs.remove(_activeSessionKey);
    }
  }

  Future<void> createNewSession() async {
    // 1. If user is logged in, create session on backend
    if (_currentUserEmail != null) {
      try {
        final baseUrl = AppConfig.fullUrl;
        final response = await http.post(
          Uri.parse('$baseUrl/chat/sessions'),
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true', // Essential for ngrok
            if (_token != null) 'Authorization': 'Bearer $_token',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final body = jsonDecode(response.body);
          final data = body['data'];
          final newSession = ChatSession(
            id: data['_id'],
            title: data['title'] ?? 'New Chat',
            messages: [],
            createdAt: DateTime.now(),
          );
          _sessions.insert(0, newSession);
          _activeSessionId = newSession.id;
          _saveSessions();
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error creating backend session: $e');
      }
    }

    // Fallback to local session if backend fails or no user
    final newSession = ChatSession.empty();
    _sessions.insert(0, newSession);
    _activeSessionId = newSession.id;
    _saveSessions();
    notifyListeners();
  }

  void switchSession(String sessionId) {
    _activeSessionId = sessionId;
    _saveSessions();
    notifyListeners();
  }

  void renameSession(String sessionId, String newTitle) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index].title = newTitle;
      _saveSessions();
      notifyListeners();
    }
  }

  void togglePin(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index].isPinned = !_sessions[index].isPinned;

      // Re-sort sessions
      _sessions.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      _saveSessions();
      notifyListeners();
    }
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_activeSessionId == sessionId) {
      _activeSessionId = _sessions.isNotEmpty ? _sessions.first.id : null;
    }
    _saveSessions();
    notifyListeners();
  }

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      _selectedAttachments.addAll(images.map((img) => img.path));
      notifyListeners();
    }
  }

  Future<void> pickFiles() async {
    try {
      debugPrint('DEBUG: Picking files using FileType.any...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        debugPrint('DEBUG: Files picked: ${result.paths.length}');
        _selectedAttachments.addAll(result.paths.whereType<String>());
        notifyListeners();
      } else {
        debugPrint('DEBUG: File picker canceled by user');
      }
    } catch (e) {
      debugPrint('DEBUG: CRITICAL ERROR in pickFiles: $e');
      // Attempting extremely basic fallback if the above fails
      try {
        debugPrint('DEBUG: Attempting absolute fallback...');
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null && result.files.single.path != null) {
          _selectedAttachments.add(result.files.single.path!);
          notifyListeners();
        }
      } catch (e2) {
        debugPrint('DEBUG: Fallback failed: $e2');
      }
    }
  }

  void removeAttachment(int index) {
    if (index >= 0 && index < _selectedAttachments.length) {
      _selectedAttachments.removeAt(index);
      notifyListeners();
    }
  }

  void notifyManualUpdate() {
    notifyListeners();
  }

  Future<List<String>> _uploadAttachments(List<String> localPaths) async {
    if (_token == null || localPaths.isEmpty) return localPaths;

    List<String> uploadedUrls = [];
    final baseUrl = AppConfig.baseUrl;

    for (var path in localPaths) {
      if (path.startsWith('http')) {
        uploadedUrls.add(path);
        continue;
      }
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/chat/upload'),
        );
        request.headers['Authorization'] = 'Bearer $_token';
        request.headers['ngrok-skip-browser-warning'] =
            'true'; // Essential for ngrok
        request.files.add(await http.MultipartFile.fromPath('file', path));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final relativeUrl = data['data']['url'];
          uploadedUrls.add('$baseUrl$relativeUrl');
        } else {
          debugPrint('Upload failed with status: ${response.statusCode}');
          uploadedUrls.add(path);
        }
      } catch (e) {
        debugPrint('Upload error: $e');
        uploadedUrls.add(path);
      }
    }
    return uploadedUrls;
  }

  Future<void> sendMessage(
    String text, {
    String language = 'English',
    String tone = 'Friendly',
    String length = 'Detailed',
    double temperature = 0.7,
    bool autoLanguage = true,
  }) async {
    if (activeSession == null) {
      createNewSession();
    }

    final attachments = List<String>.from(_selectedAttachments);
    _selectedAttachments.clear();

    try {
      _isLoading = true;
      notifyListeners();

      final uploadedAttachments = await _uploadAttachments(attachments);

      activeSession!.messages.add(
        ChatMessage.user(text, attachments: uploadedAttachments),
      );
      _saveSessions();
      notifyListeners();

      // Create a placeholder AI message for streaming
      final aiMessage = ChatMessage.ai('');
      activeSession!.messages.add(aiMessage);

      // We keep loading true while "thinking", but for streaming UI we usually want the stream to start
      // I'll set it to false here so the input field unlocks, while the stream continues.
      _isLoading = false;
      notifyListeners();

      // Auto-generate title if it's 'New Chat'
      // Capture session reference/ID to ensure we rename the correct one even if user switches
      final currentSession = activeSession!;
      final currentSessionId = currentSession.id;

      if (currentSession.title == 'New Chat' &&
          currentSession.messages.length <= 2) {
        // Don't await this, let it run in background
        _aiService
            .generateChatTitle(currentSessionId, token: _token, message: text)
            .then((newTitle) {
              // Find the session by ID
              final index = _sessions.indexWhere(
                (s) => s.id == currentSessionId,
              );
              if (index != -1 && newTitle.isNotEmpty) {
                // Verify it is still 'New Chat' to avoid overwriting user edits
                if (_sessions[index].title == 'New Chat') {
                  _sessions[index].title = newTitle;
                  _saveSessions();
                  notifyListeners();
                }
              }
            });
      }

      // Stream real AI response
      try {
        await for (final chunk in _aiService.generateStreamingResponse(
          currentSessionId,
          currentSession.messages.sublist(
            0,
            currentSession.messages.length - 1,
          ),
          token: _token,
          language: language,
          tone: tone,
          length: length,
          temperature: temperature,
          autoLanguage: autoLanguage,
        )) {
          aiMessage.text += chunk;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('DEBUG: Streaming error: $e');
        if (aiMessage.text.isEmpty) {
          aiMessage.text = 'Error: Failed to get response. $e';
        }
      }

      _saveSessions();
      notifyListeners();
    } catch (e) {
      debugPrint("Error in sendMessage: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearMessages() async {
    activeSession?.messages.clear();
    _saveSessions();
    notifyListeners();
  }

  Future<void> clearAllSessions() async {
    _sessions.clear();
    _activeSessionId = null;
    _saveSessions();
    notifyListeners();
  }
}
