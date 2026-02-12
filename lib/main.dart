import 'dart:io';
import 'package:black_ai/core/http_overrides.dart';
import 'package:black_ai/feature/provider/chat_provider.dart';
import 'package:black_ai/feature/provider/settings_provider.dart';
import 'package:black_ai/feature/view/chat.dart';
import 'package:black_ai/feature/view/login_screen.dart';
import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/feature/service/keep_alive_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Start Keep Alive Service to prevent backend from sleeping
  KeepAliveService().start();

  // Bypass SSL certificate validation for development (fixes HandshakeException)
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
      ],
      child: const AiChatBotApp(),
    ),
  );
}

class AiChatBotApp extends StatelessWidget {
  const AiChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Black',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    return chatProvider.isLoggedIn ? const ChatPage() : const LoginScreen();
  }
}
