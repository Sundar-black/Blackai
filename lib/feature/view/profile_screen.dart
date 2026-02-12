import 'package:black_ai/feature/service/node_auth_service.dart';
import 'package:black_ai/feature/view/login_screen.dart';
import 'package:black_ai/feature/view/settings_screen.dart';
import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/core/custom_widgets/custom_text.dart';
import 'package:black_ai/core/custom_widgets/custom_text_form_field.dart';
import 'package:black_ai/core/extensions/navigation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEditing = false;

  String? _displayName;
  String? _email;
  String? _avatar;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayName = prefs.getString("user_name") ?? "User";
      _email = prefs.getString("user_email");
      _avatar = prefs.getString("user_avatar");
      _role = prefs.getString("user_role");

      _nameController.text = _displayName ?? "";
    });

    try {
      final res = await NodeAuthService.getProfile();
      if (res['user'] != null) {
        final user = res['user'];
        setState(() {
          _displayName = user['name'];
          _email = user['email'];
          _avatar = user['avatar'];
          _role = user['role'];
          _nameController.text = _displayName ?? "";
        });
        // Update prefs
        if (_displayName != null) {
          await prefs.setString("user_name", _displayName!);
        }
        if (_email != null) {
          await prefs.setString("user_email", _email!);
        }
        if (_avatar != null) {
          await prefs.setString("user_avatar", _avatar!);
        }
        if (_role != null) {
          await prefs.setString("user_role", _role!);
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isEditing = false);

    final res = await NodeAuthService.updateProfile(name: name);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUserData(); // Reload to reflect changes
    } else {
      final error = res['message'] ?? 'Failed to update profile.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _logout() async {
    await NodeAuthService.logout();
    if (!mounted) return;
    context.pushAndRemoveUntil(const LoginScreen());
  }

  void _viewAvatar(String? imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: imagePath != null
                    ? (imagePath.startsWith('data:image')
                          ? DecorationImage(
                              image: MemoryImage(
                                base64Decode(imagePath.split(',').last),
                              ),
                              fit: BoxFit.contain,
                            )
                          : DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(imagePath)
                                  : FileImage(io.File(imagePath))
                                        as ImageProvider,
                              fit: BoxFit.contain,
                            ))
                    : null,
              ),
              child: imagePath == null
                  ? Container(
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 150,
                        color: AppColors.white24,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const CustomText('Close', color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picking disabled in this version.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => context.pop(),
            ),
            title: const CustomText(
              'Profile',
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.check_circle : Icons.edit_note,
                  color: AppColors.accent,
                ),
                onPressed: _isEditing ? _saveProfile : _toggleEdit,
              ).animate().scale(duration: 200.ms),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_role == 'admin')
                          Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.amberAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .rotate(duration: 10.seconds),
                        Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 4,
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.15, 1.15),
                              duration: 2.seconds,
                            )
                            .fade(begin: 0.5, end: 0.1),

                        GestureDetector(
                          onTap: () {
                            if (_isEditing) {
                              _pickImage();
                            } else {
                              _viewAvatar(_avatar);
                            }
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.accent,
                                backgroundImage: _avatar != null
                                    ? (_avatar!.startsWith('data:image')
                                          ? MemoryImage(
                                                  base64Decode(
                                                    _avatar!.split(',').last,
                                                  ),
                                                )
                                                as ImageProvider
                                          : (kIsWeb
                                                ? NetworkImage(_avatar!)
                                                : FileImage(io.File(_avatar!))
                                                      as ImageProvider))
                                    : null,
                                child: _avatar == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppColors.white,
                                      )
                                    : null,
                              ),
                              if (_role == 'admin')
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              if (_isEditing && _role != 'admin')
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                ).animate().scale(duration: 200.ms),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().scale(duration: 400.ms),

                  const SizedBox(height: 16),

                  if (_isEditing)
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: AppColors.white70,
                      ),
                      label: const CustomText(
                        'Change Avatar',
                        color: AppColors.white70,
                      ),
                    ).animate().fade().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  _buildFieldLabel("Name"),
                  CustomTextFormField(
                    controller: _nameController,
                    enabled: _isEditing,
                  ).animate().fade(delay: 100.ms).slideX(begin: -0.05, end: 0),

                  const SizedBox(height: 16),

                  _buildFieldLabel("Email"),
                  CustomTextFormField(
                    controller: TextEditingController(text: _email ?? ''),
                    enabled: false,
                  ).animate().fade(delay: 200.ms).slideX(begin: -0.05, end: 0),

                  const SizedBox(height: 16),

                  _buildAdminButton(context),
                  _buildSettingsButton(context),
                  const SizedBox(height: 32),
                  if (_isEditing) ...[
                    _buildFieldLabel("New Password"),
                    CustomTextFormField(
                      controller: _passwordController,
                      enabled: true,
                      obscureText: true,
                    ).animate().fade().slideX(begin: -0.05, end: 0),
                  ],

                  const SizedBox(height: 48),

                  Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const CustomText(
                              'Log Out',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fade(delay: 300.ms)
                      .shimmer(duration: 2.seconds, color: AppColors.white10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomText(label, fontSize: 14, color: AppColors.white70),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildSettingsButton(BuildContext context) {
    return ListTile(
      onTap: () {
        context.push(const SettingsScreen());
      },
      leading: const Icon(Icons.settings_outlined, color: AppColors.accent),
      title: const CustomText(
        'Settings',
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      subtitle: const CustomText(
        'Chatbot behavior, theme, and more',
        fontSize: 12,
        color: AppColors.white60,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.white10),
      contentPadding: EdgeInsets.zero,
    ).animate().fade(delay: 150.ms).slideX(begin: -0.05, end: 0);
  }
}
