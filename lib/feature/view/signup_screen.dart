import 'package:black_ai/feature/service/node_auth_service.dart';
import 'package:black_ai/feature/view/chat.dart';
import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/config/app_assets.dart';
import 'package:black_ai/core/custom_widgets/custom_text.dart';
import 'package:black_ai/core/custom_widgets/custom_text_form_field.dart';
import 'package:black_ai/core/extensions/navigation_extension.dart';
import 'package:black_ai/core/custom_widgets/decoration.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);

    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (password != confirmPassword) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    // Call static signup method
    final res = await NodeAuthService.signup(
      name: name,
      email: email,
      password: password,
    );

    // Debug print
    debugPrint("Signup result: $res");

    if (!mounted) return;

    // Check for success via token
    final success = res['token'] != null || res['access_token'] != null;

    if (success) {
      if (mounted) {
        // Auto-login or navigate to login page, or directly to chat if token is saved
        // The new static login saves token, but signup usually returns token too.
        // If signup returns token, we should probably save it here too or just navigate to login.
        // Let's assume signup returns token and we want to auto-login.
        final token = res["token"] ?? res["access_token"];
        if (token != null) {
          // Manually save token since static signup in example didn't save it,
          // but user might expect auto-login.
          // Actually, user's example snippet for signup didn't save token, only Login did.
          // So for safety, let's navigate to Login Screen or assume auto-login if backend returns it.

          // To match USER REQUEST EXACTLY:
          // User snippet for signup: returns map, doesn't save token explicitly in snippet.
          // BUT usually we want auto login.
          // Let's just navigate to ChatPage if success, assuming backend might have set cookie or we rely on user to login.
          // Wait, if we don't save token, ChatPage won't work.
          // Let's check logic. Static login saves token. Static signup just returns map.

          // I will navigate to LoginScreen to be safe and force them to login,
          // UNLESS we want to save token here.
          // Let's save it if present to be helpful.
          // However, since I can't import SharedPreferences easily here without clutter,
          // I'll stick to navigating to ChatPage if we are confident, or just Login.
          // Let's just navigate to ChatPage for now as per original code flow.

          // Actually, the original code had `authentication` logic inside the service.
          // New static service `signup` does NOT save token in the user provided snippet.
          // So we should navigate to Login, or call login automatically.

          // Let's call login automatically to be smooth.
          await NodeAuthService.login(email: email, password: password);
          if (mounted) context.pushAndRemoveUntil(const ChatPage());
        }
      }
    } else {
      setState(() => _isLoading = false);
      String error = res['detail'] ?? res['message'] ?? 'Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup Failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: AuraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'appLogo',
                  child: Image.asset(
                    AppAssets.logo,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ).animate().fade().scale(
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
                const SizedBox(height: 32),
                CustomText(
                  'CREATE ACCOUNT',
                  textAlign: TextAlign.center,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ).animate().fade().slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 300.ms,
                  delay: 50.ms,
                ),
                const SizedBox(height: 48),

                CustomTextFormField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.white70,
                  ),
                  keyboardType: TextInputType.name,
                ).animate().fade().slideX(
                  begin: -0.05,
                  end: 0,
                  duration: 300.ms,
                  delay: 100.ms,
                ),
                const SizedBox(height: 16),

                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.white70,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ).animate().fade().slideX(
                  begin: -0.05,
                  end: 0,
                  duration: 300.ms,
                  delay: 150.ms,
                ),
                const SizedBox(height: 16),

                CustomTextFormField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: !_isPasswordVisible,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.white70,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.white38,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ).animate().fade().slideX(
                  begin: -0.05,
                  end: 0,
                  duration: 300.ms,
                  delay: 200.ms,
                ),
                const SizedBox(height: 16),

                CustomTextFormField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: !_isConfirmPasswordVisible,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.white70,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.white38,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ).animate().fade().slideX(
                  begin: -0.05,
                  end: 0,
                  duration: 300.ms,
                  delay: 250.ms,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const CustomText(
                            'Sign Up',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                  ),
                ).animate().fade().slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 300.ms,
                  delay: 300.ms,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CustomText(
                        "Already have an account?",
                        color: AppColors.white70,
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const CustomText(
                          'Log in',
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 350.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
