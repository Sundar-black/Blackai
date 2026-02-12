import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/core/custom_widgets/custom_text.dart';
import 'package:black_ai/core/custom_widgets/custom_text_form_field.dart';
import 'package:black_ai/core/custom_widgets/decoration.dart';
import 'package:black_ai/feature/view/login_screen.dart'; // Used in navigation

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:black_ai/core/extensions/navigation_extension.dart';
import 'package:black_ai/feature/service/node_auth_service.dart';

import 'dart:async';

class NewPasswordScreen extends StatefulWidget {
  final String? email;
  const NewPasswordScreen({super.key, this.email});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Resend Timer & Limit logic
  int _secondsRemaining = 50;
  Timer? _timer;
  bool _canResend = false;
  int _resendCount = 0;
  final int _maxResends = 3;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 50;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    if (_resendCount >= _maxResends) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum resend attempts reached. Please try again later.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resendCount++;
    });

    final res = await NodeAuthService.forgotPassword(widget.email ?? '');

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'New code sent to your email.'),
          backgroundColor: Colors.green,
        ),
      );
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to resend code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleReset() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    final res = await NodeAuthService.resetPassword(
      email: widget.email ?? '',
      otp: code,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please login.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pushAndRemoveUntil(const LoginScreen());
    } else {
      final error = res['message'] ?? 'Invalid code or request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
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
              children: [
                const Icon(
                  Icons.vpn_key_outlined,
                  size: 80,
                  color: AppColors.accent,
                ).animate().fade().scale(),
                const SizedBox(height: 32),
                const CustomText(
                  'Set New Password',
                  textAlign: TextAlign.center,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ).animate().fade().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                CustomText(
                  'Enter the verification code sent to ${widget.email} and create your new password.',
                  textAlign: TextAlign.center,
                  fontSize: 16,
                  color: AppColors.white60,
                ).animate().fade(delay: 100.ms),
                const SizedBox(height: 40),
                CustomTextFormField(
                  controller: _codeController,
                  hintText: 'Verification Code',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(
                    Icons.numbers,
                    color: AppColors.white38,
                  ),
                ).animate().fade(delay: 200.ms).slideX(begin: -0.05, end: 0),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _passwordController,
                  hintText: 'New Password',
                  obscureText: !_isPasswordVisible,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.white38,
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
                ).animate().fade(delay: 250.ms).slideX(begin: -0.05, end: 0),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: !_isConfirmPasswordVisible,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.white38,
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
                ).animate().fade(delay: 300.ms).slideX(begin: -0.05, end: 0),
                const SizedBox(height: 24),

                // Resend OTP Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      _canResend ? "Didn't receive code? " : "Resend code in ",
                      color: AppColors.white60,
                      fontSize: 14,
                    ),
                    if (!_canResend)
                      CustomText(
                        "${_secondsRemaining}s",
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    if (_canResend)
                      TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const CustomText(
                          "Resend Code",
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ).animate().fade(delay: 350.ms),

                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleReset,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const CustomText(
                            'Reset Password',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                  ),
                ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
