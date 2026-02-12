import 'package:black_ai/feature/service/node_auth_service.dart';
import 'package:black_ai/feature/view/login_screen.dart';
import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/core/custom_widgets/custom_text.dart';
import 'package:black_ai/core/extensions/navigation_extension.dart';
import 'package:black_ai/feature/provider/chat_provider.dart';
import 'package:black_ai/feature/provider/settings_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _logout() async {
    await NodeAuthService.logout();
    if (!mounted) return;
    context.pushAndRemoveUntil(const LoginScreen());
  }

  void _deleteAccount() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const CustomText(
          'Delete Account?',
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        content: const CustomText(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
          color: AppColors.white70,
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const CustomText('Cancel', color: AppColors.white60),
          ),
          TextButton(
            onPressed: () async {
              dialogContext.pop();
              setState(
                () {},
              ); // Trigger rebuild if needed for loading state, though not strictly necessary here

              final res = await NodeAuthService.deleteAccount();

              if (!mounted) return;

              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
                _logout();
              } else {
                final error = res['message'] ?? 'Failed to delete account.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const CustomText(
              'Delete',
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const CustomText(
          'Clear history?',
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        content: const CustomText(
          'This will permanently delete all your chat conversations. This action cannot be undone.',
          color: AppColors.white70,
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const CustomText('Cancel', color: AppColors.white60),
          ),
          TextButton(
            onPressed: () {
              dialogContext.pop();
              context.read<ChatProvider>().clearAllSessions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All chat history cleared')),
              );
            },
            child: const CustomText(
              'Clear',
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Sync settings disabled for this static version as per user request to use specific code
  /*
  void _syncSettings() {
    final authService = context.read<NodeAuthService>();
    final settingsProvider = context.read<SettingsProvider>();
    if (authService.isLoggedIn) {
      authService.updateSettings(settingsProvider.toMap());
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            centerTitle: true,
            title: const CustomText(
              'Settings',
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => context.pop(),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('Chatbot Behavior'),
              _buildSettingCard([
                _buildDropdownTile(
                  'Response Language',
                  settings.selectedLanguage,
                  ['English', 'Spanish', 'French', 'German', 'Chinese'],
                  (val) {
                    context.read<SettingsProvider>().setSelectedLanguage(val!);
                    // _syncSettings();
                  },
                  icon: Icons.language,
                ),
                _buildSwitchTile(
                  'Auto Language Match',
                  'Detect and match your input language',
                  settings.autoLanguageMatch,
                  (val) {
                    context.read<SettingsProvider>().setAutoLanguageMatch(val);
                    // _syncSettings();
                  },
                ),
                _buildToggleRow(
                  'Response Tone',
                  settings.responseTone,
                  ['Friendly', 'Formal'],
                  (val) {
                    context.read<SettingsProvider>().setResponseTone(val);
                    // _syncSettings();
                  },
                ),
                _buildToggleRow(
                  'Answer Length',
                  settings.answerLength,
                  ['Short', 'Detailed'],
                  (val) {
                    context.read<SettingsProvider>().setAnswerLength(val);
                    // _syncSettings();
                  },
                ),
                _buildSliderTile(
                  'AI Personalization',
                  settings.aiPersonalization,
                  (val) {
                    context.read<SettingsProvider>().setAiPersonalization(val);
                    // _syncSettings();
                  },
                ),
              ]),

              _buildSectionHeader('App Experience'),
              _buildSettingCard([
                _buildSwitchTile(
                  'Enable Animations',
                  'Toggle premium UI animations',
                  settings.animationsEnabled,
                  (val) {
                    context.read<SettingsProvider>().setAnimationsEnabled(val);
                    // _syncSettings();
                  },
                ),
              ]),

              _buildSectionHeader('Data & Privacy'),
              _buildSettingCard([
                _buildActionTile(
                  'Clear Chat History',
                  'Permanently delete conversations',
                  Icons.delete_sweep_outlined,
                  _clearChatHistory,
                  destructive: true,
                ),
                _buildActionTile(
                  'Privacy Settings',
                  'Manage data usage and privacy',
                  Icons.privacy_tip_outlined,
                  () {},
                ),
              ]),

              _buildSectionHeader('Account & App'),
              _buildSettingCard([
                _buildActionTile(
                  'Log Out',
                  'Sign out of your account',
                  Icons.logout,
                  _logout,
                ),
                _buildActionTile(
                  'Delete Account',
                  'Permanently remove your account',
                  Icons.delete_forever,
                  _deleteAccount,
                  destructive: true,
                ),
                _buildInfoTile('App Version', '2.0.1 (Black Premium)'),
              ]),

              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CustomText(
                      'BLACK AI',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white.withValues(alpha: 0.2),
                      letterSpacing: 4,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      'Created & Trained by Sundar',
                      fontSize: 10,
                      color: AppColors.white.withValues(alpha: 0.15),
                      letterSpacing: 1.2,
                    ),
                  ],
                ),
              ).animate().fade(delay: 500.ms),
              const SizedBox(height: 48),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      child: CustomText(
        title.toUpperCase(),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.accent,
        letterSpacing: 1.5,
      ),
    ).animate().fade().slideX(begin: -0.1, end: 0);
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: children
            .map(
              (w) => Column(
                children: [
                  w,
                  if (w != children.last)
                    const Divider(
                      color: AppColors.white10,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              ),
            )
            .toList(),
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.02, end: 0);
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: CustomText(title, fontSize: 15, color: AppColors.white),
      subtitle: CustomText(subtitle, fontSize: 12, color: AppColors.white60),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accent,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.white38, size: 20),
      title: CustomText(title, fontSize: 15, color: AppColors.white),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.secondaryBackground,
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
        ),
        underline: const SizedBox(),
        icon: const Icon(Icons.expand_more, color: AppColors.white38),
        items: options
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String current,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return ListTile(
      title: CustomText(title, fontSize: 15, color: AppColors.white),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = current == opt;
            return GestureDetector(
              onTap: () => onChanged(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomText(
                  opt,
                  color: isSelected ? AppColors.white : AppColors.white38,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(title, fontSize: 15, color: AppColors.white),
          CustomText(
            '${(value * 100).toInt()}%',
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ],
      ),
      subtitle: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        ),
        child: Slider(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.white10,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: destructive
            ? Colors.redAccent.withValues(alpha: 0.6)
            : AppColors.white38,
        size: 20,
      ),
      title: CustomText(
        title,
        fontSize: 15,
        color: destructive ? Colors.redAccent : AppColors.white,
      ),
      subtitle: CustomText(subtitle, fontSize: 11, color: AppColors.white38),
      onTap: onTap,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.white10,
        size: 18,
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: CustomText(title, fontSize: 15, color: AppColors.white),
      trailing: CustomText(value, fontSize: 13, color: AppColors.white38),
    );
  }
}
