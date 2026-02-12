import 'package:black_ai/feature/service/node_auth_service.dart';
import 'package:black_ai/feature/view/chat.dart';
import 'package:black_ai/feature/view/signup_screen.dart';
import 'package:black_ai/feature/view/forgot_password_screen.dart';
import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/config/app_assets.dart';
import 'package:black_ai/core/custom_widgets/custom_text.dart';
import 'package:black_ai/core/custom_widgets/custom_text_form_field.dart';
import 'package:black_ai/core/extensions/navigation_extension.dart';
import 'package:black_ai/core/custom_widgets/decoration.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
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

    // Call static login method
    final res = await NodeAuthService.login(email: email, password: password);

    // Debug print
    debugPrint("Login result: $res");

    if (!mounted) return;

    // Check for success via token existence or success flag
    final success = res['token'] != null || res['access_token'] != null;

    if (success) {
      if (mounted) {
        context.pushAndRemoveUntil(const ChatPage());
      }
    } else {
      setState(() => _isLoading = false);
      final error = res['detail'] ?? res['message'] ?? 'Check credentials.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login Failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
                  'WELCOME',
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
                  delay: 100.ms,
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
                  delay: 150.ms,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white70,
                    ),
                    onPressed: () {
                      context.push(const ForgotPasswordScreen());
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ).animate().fade(delay: 180.ms),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                            'Continue',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                  ),
                ).animate().fade().slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 300.ms,
                  delay: 200.ms,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CustomText(
                        "Don't have an account?",
                        color: AppColors.white70,
                      ),
                      TextButton(
                        onPressed: () {
                          context.push(const SignupScreen());
                        },
                        child: const CustomText(
                          'Sign up',
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 250.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
