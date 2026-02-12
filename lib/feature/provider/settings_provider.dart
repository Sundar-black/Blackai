import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  bool _animationsEnabled = true;
  String _selectedLanguage = 'English';
  bool _autoLanguageMatch = true;
  String _responseTone = 'Friendly';
  String _answerLength = 'Detailed';
  double _aiPersonalization = 0.7;

  bool get animationsEnabled => _animationsEnabled;
  String get selectedLanguage => _selectedLanguage;
  bool get autoLanguageMatch => _autoLanguageMatch;
  String get responseTone => _responseTone;
  String get answerLength => _answerLength;
  double get aiPersonalization => _aiPersonalization;

  Map<String, dynamic> toMap() {
    return {
      'animations_enabled': _animationsEnabled,
      'selected_language': _selectedLanguage,
      'auto_language_match': _autoLanguageMatch,
      'response_tone': _responseTone,
      'answer_length': _answerLength,
      'ai_personalization': _aiPersonalization,
    };
  }

  void updateFromMap(Map<String, dynamic> map) {
    _animationsEnabled = map['animations_enabled'] ?? _animationsEnabled;
    _selectedLanguage = map['selected_language'] ?? _selectedLanguage;
    _autoLanguageMatch = map['auto_language_match'] ?? _autoLanguageMatch;
    _responseTone = map['response_tone'] ?? _responseTone;
    _answerLength = map['answer_length'] ?? _answerLength;
    _aiPersonalization =
        (map['ai_personalization'] as num?)?.toDouble() ?? _aiPersonalization;

    // Save locally
    _prefs.setBool('animationsEnabled', _animationsEnabled);
    _prefs.setString('selectedLanguage', _selectedLanguage);
    _prefs.setBool('autoLanguageMatch', _autoLanguageMatch);
    _prefs.setString('responseTone', _responseTone);
    _prefs.setString('answerLength', _answerLength);
    _prefs.setDouble('aiPersonalization', _aiPersonalization);

    notifyListeners();
  }

  void _loadSettings() {
    _animationsEnabled = _prefs.getBool('animationsEnabled') ?? true;
    _selectedLanguage = _prefs.getString('selectedLanguage') ?? 'English';
    _autoLanguageMatch = _prefs.getBool('autoLanguageMatch') ?? true;
    _responseTone = _prefs.getString('responseTone') ?? 'Friendly';
    _answerLength = _prefs.getString('answerLength') ?? 'Detailed';
    _aiPersonalization = _prefs.getDouble('aiPersonalization') ?? 0.7;
    notifyListeners();
  }

  void setAnimationsEnabled(bool value) {
    _animationsEnabled = value;
    _prefs.setBool('animationsEnabled', value);
    notifyListeners();
  }

  void setSelectedLanguage(String value) {
    _selectedLanguage = value;
    _prefs.setString('selectedLanguage', value);
    notifyListeners();
  }

  void setAutoLanguageMatch(bool value) {
    _autoLanguageMatch = value;
    _prefs.setBool('autoLanguageMatch', value);
    notifyListeners();
  }

  void setResponseTone(String value) {
    _responseTone = value;
    _prefs.setString('responseTone', value);
    notifyListeners();
  }

  void setAnswerLength(String value) {
    _answerLength = value;
    _prefs.setString('answerLength', value);
    notifyListeners();
  }

  void setAiPersonalization(double value) {
    _aiPersonalization = value;
    saveToPrefs();
    notifyListeners();
  }

  void saveToPrefs() {
    _prefs.setBool('animationsEnabled', _animationsEnabled);
    _prefs.setString('selectedLanguage', _selectedLanguage);
    _prefs.setBool('autoLanguageMatch', _autoLanguageMatch);
    _prefs.setString('responseTone', _responseTone);
    _prefs.setString('answerLength', _answerLength);
    _prefs.setDouble('aiPersonalization', _aiPersonalization);
  }
}
