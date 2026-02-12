import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/core/custom_widgets/custom_text.dart';
import 'package:black_ai/core/custom_widgets/custom_text_form_field.dart';
import 'package:black_ai/core/custom_widgets/decoration.dart';
import 'package:black_ai/feature/service/node_auth_service.dart';
import 'package:black_ai/feature/view/new_password_screen.dart';
import 'package:black_ai/core/extensions/navigation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email.')));
      return;
    }

    setState(() => _isLoading = true);

    final res = await NodeAuthService.forgotPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Code sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.push(NewPasswordScreen(email: email));
    } else {
      final error = res['message'] ?? 'Something went wrong.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(iconTheme: const IconThemeData(color: AppColors.white)),
      body: AuraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppColors.accent,
                ).animate().fade().scale(duration: 400.ms),
                const SizedBox(height: 32),
                const CustomText(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ).animate().fade().slideY(begin: 0.1, end: 0, delay: 100.ms),
                const SizedBox(height: 16),
                const CustomText(
                  'Enter your email to receive a password reset code.',
                  textAlign: TextAlign.center,
                  fontSize: 16,
                  color: AppColors.white60,
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 48),
                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.white38,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ).animate().fade().slideX(begin: -0.05, end: 0, delay: 300.ms),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleReset,
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
                            'Send Code',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                  ),
                ).animate().fade().slideY(begin: 0.1, end: 0, delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
