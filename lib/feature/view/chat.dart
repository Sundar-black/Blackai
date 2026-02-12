import 'package:black_ai/feature/provider/chat_provider.dart';
import 'package:black_ai/feature/provider/settings_provider.dart';
import 'package:black_ai/core/custom_widgets/message_widget.dart';
import 'package:black_ai/feature/view/profile_screen.dart';
import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/config/app_string.dart';
import 'package:black_ai/core/custom_widgets/custom_text.dart';
import 'package:black_ai/core/extensions/navigation_extension.dart';
import 'package:black_ai/core/custom_widgets/decoration.dart';
import 'package:black_ai/config/app_assets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;
import 'dart:async' show Timer;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showIntroAnimation = true;

  // Recording variables
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _showIntroAnimation = false);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    final provider = context.read<ChatProvider>();

    if (text.isEmpty && provider.selectedAttachments.isEmpty) return;

    final settings = context.read<SettingsProvider>();

    _textController.clear();
    await provider.sendMessage(
      text,
      language: settings.selectedLanguage,
      tone: settings.responseTone,
      length: settings.answerLength,
      temperature: settings.aiPersonalization,
      autoLanguage: settings.autoLanguageMatch,
    );
    _scrollToBottom();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'record_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final path = p.join(dir.path, fileName);

        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
          });
        });
      }
    } catch (e) {
      debugPrint("Recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();

    if (path != null) {
      if (!mounted) return;
      context.read<ChatProvider>().selectedAttachments.add(path);
      context.read<ChatProvider>().notifyManualUpdate();
    }

    setState(() {
      _isRecording = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntroAnimation) {
      return Scaffold(
        body: AuraBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                      tag: 'appLogo',
                      child: Image.asset(
                        AppAssets.logo,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    )
                    .animate()
                    .fade(duration: 800.ms)
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1200.ms, color: AppColors.accent),
                const SizedBox(height: 24),
                CustomText(
                      AppStrings.appName.toUpperCase(),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 8,
                    )
                    .animate()
                    .fade(delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms),
                const SizedBox(height: 12),
                CustomText(
                  "INITIALIZING SYSTEM",
                  fontSize: 10,
                  color: AppColors.white38,
                  letterSpacing: 4,
                ).animate().fade(delay: 800.ms).shimmer(duration: 2.seconds),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final activeSession = chatProvider.activeSession;
            return CustomText(
              activeSession?.title ?? AppStrings.appName,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            );
          },
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      drawer: _buildDrawer(),
      body: AuraBackground(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.messages.isEmpty &&
                      !chatProvider.isLoading) {
                    return Center(
                      child:
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                AppAssets.logo,
                                height: 60,
                                color: AppColors.white10,
                              ).animate().fade().scale(),
                              const SizedBox(height: 24),
                              const CustomText(
                                AppStrings.introMessage,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white70,
                              ),
                            ],
                          ).animate().fade().slideY(
                            begin: 0.2,
                            end: 0,
                            duration: 500.ms,
                          ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );

                  return RepaintBoundary(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount:
                          chatProvider.messages.length +
                          (chatProvider.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == chatProvider.messages.length &&
                            chatProvider.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }

                        int delayIndex = index;
                        if (index > 10) {
                          delayIndex = 0;
                        }

                        return MessageWidget(
                          message: chatProvider.messages[index],
                        ).animate().fade().slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 200.ms,
                          delay: Duration(milliseconds: 20 * delayIndex),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return _buildInputArea(chatProvider.isLoading);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameSession(String sessionId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const CustomText('Rename Chat', fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: AppColors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const CustomText('Cancel', color: AppColors.white60),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                context.read<ChatProvider>().renameSession(sessionId, newTitle);
              }
              context.pop();
            },
            child: const CustomText('Save', color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  void _deleteSession(String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const CustomText('Delete Chat', fontWeight: FontWeight.bold),
        content: const CustomText('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const CustomText('Cancel', color: AppColors.white60),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().deleteSession(sessionId);
              context.pop();
            },
            child: const CustomText('Delete', color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final chatProvider = context.watch<ChatProvider>();
    final sessions = chatProvider.sessions;
    final activeSession = chatProvider.activeSession;

    return Drawer(
      backgroundColor: AppColors.secondaryBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: OutlinedButton(
              onPressed: () {
                context.read<ChatProvider>().createNewSession();
                context.pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white24),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 12),
                  CustomText('New chat'),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.white24),
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: CustomText('No chats yet', color: AppColors.white38),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isSelected = activeSession?.id == session.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.white10,
                        leading: Icon(
                          session.isPinned
                              ? Icons.push_pin
                              : Icons.chat_bubble_outline,
                          color: isSelected
                              ? AppColors.white
                              : (session.isPinned
                                    ? AppColors.accent
                                    : AppColors.white70),
                          size: 20,
                        ),
                        title: CustomText(
                          session.title,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.white70,
                          fontSize: 14,
                        ),
                        trailing: isSelected
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      session.isPinned
                                          ? Icons.push_pin_outlined
                                          : Icons.push_pin,
                                      size: 16,
                                    ),
                                    color: AppColors.white38,
                                    tooltip: session.isPinned
                                        ? 'Unpin Chat'
                                        : 'Pin Chat',
                                    onPressed: () {
                                      context.read<ChatProvider>().togglePin(
                                        session.id,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    color: AppColors.white38,
                                    onPressed: () => _renameSession(
                                      session.id,
                                      session.title,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                    ),
                                    color: AppColors.white38,
                                    onPressed: () => _deleteSession(session.id),
                                  ),
                                ],
                              )
                            : (session.isPinned
                                  ? const Icon(
                                      Icons.push_pin,
                                      size: 14,
                                      color: AppColors.white38,
                                    )
                                  : null),
                        onTap: () {
                          context.read<ChatProvider>().switchSession(
                            session.id,
                          );
                          context.pop();
                        },
                      );
                    },
                  ),
          ),
          const Divider(color: AppColors.white24),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.white70),
            title: const CustomText(
              'Profile & Settings',
              color: AppColors.white,
            ),
            onTap: () {
              context.push(const ProfileScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    final chatProvider = context.watch<ChatProvider>();
    final selectedAttachments = chatProvider.selectedAttachments;

    return Column(
      children: [
        if (selectedAttachments.isNotEmpty)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.transparent,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedAttachments.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final path = selectedAttachments[index];
                final isImage =
                    path.toLowerCase().endsWith('.jpg') ||
                    path.toLowerCase().endsWith('.jpeg') ||
                    path.toLowerCase().endsWith('.png') ||
                    path.toLowerCase().endsWith('.webp');
                final isAudio =
                    path.toLowerCase().endsWith('.m4a') ||
                    path.toLowerCase().endsWith('.mp3');

                return Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: isImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                io.File(path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Icon(
                                isAudio ? Icons.mic : Icons.insert_drive_file,
                                color: AppColors.accent,
                                size: 32,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => context
                            .read<ChatProvider>()
                            .removeAttachment(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ).animate().fade().slideY(begin: 0.1, end: 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Column(
            children: [
              if (_isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.redAccent,
                            size: 12,
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .fade(duration: 500.ms),
                      const SizedBox(width: 12),
                      CustomText(
                        "Recording: ${_formatDuration(_recordDuration)}",
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ).animate().fade().scale(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.white60,
                      size: 28,
                    ),
                    onPressed: isLoading ? null : _showAttachmentOptions,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        enabled: !isLoading && !_isRecording,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: "Type message...",
                          hintStyle: TextStyle(color: AppColors.white24),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, child) {
                      final hasText = value.text.trim().isNotEmpty;
                      final hasAttachments = selectedAttachments.isNotEmpty;

                      if (!hasText && !hasAttachments) {
                        return GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  if (_isRecording) {
                                    _stopRecording();
                                  } else {
                                    _startRecording();
                                  }
                                },
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? Colors.redAccent
                                  : AppColors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic_none,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                        ).animate().scale();
                      }

                      return GestureDetector(
                        onTap: isLoading ? null : _sendMessage,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                      ).animate().scale();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.accent),
              title: const CustomText(
                'Photos & Videos',
                color: AppColors.white,
              ),
              onTap: () {
                context.pop();
                context.read<ChatProvider>().pickImages();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file,
                color: AppColors.accent,
              ),
              title: const CustomText('Documents', color: AppColors.white),
              onTap: () {
                context.pop();
                context.read<ChatProvider>().pickFiles();
              },
            ),
          ],
        ),
      ),
    );
  }
}
