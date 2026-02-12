import 'package:black_ai/core/custom_widgets/audio_player_widget.dart';
import 'package:black_ai/core/models/message_model.dart';
import 'package:black_ai/core/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:black_ai/config/app_colors.dart';
import 'package:black_ai/feature/provider/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'dart:convert';

class MessageWidget extends StatelessWidget {
  final ChatMessage message;

  const MessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: SizedBox(
            width: 800,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context, isUser),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.transparent
                          : AppColors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUser
                            ? Colors.transparent
                            : AppColors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.attachmentPaths.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: message.attachmentPaths.map((path) {
                                final isImage =
                                    path.toLowerCase().endsWith('.jpg') ||
                                    path.toLowerCase().endsWith('.jpeg') ||
                                    path.toLowerCase().endsWith('.png') ||
                                    path.toLowerCase().endsWith('.webp');
                                final isAudio =
                                    path.toLowerCase().endsWith('.m4a') ||
                                    path.toLowerCase().endsWith('.mp3') ||
                                    path.toLowerCase().endsWith('.wav') ||
                                    path.toLowerCase().endsWith('.aac');

                                if (isImage) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: path.startsWith('http')
                                        ? Image.network(
                                            path,
                                            width: 260,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white54,
                                                    ),
                                          )
                                        : Image.file(
                                            io.File(path),
                                            width: 260,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white54,
                                                    ),
                                          ),
                                  );
                                } else if (isAudio) {
                                  return AudioPlayerWidget(audioPath: path);
                                } else {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.insert_drive_file,
                                          color: AppColors.accent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            path.startsWith('http')
                                                ? path.split('/').last
                                                : path
                                                      .split(
                                                        io
                                                            .Platform
                                                            .pathSeparator,
                                                      )
                                                      .last,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }).toList(),
                            ),
                          ),
                        isUser
                            ? CustomText(
                                message.text,
                                fontSize: 16,
                                color: AppColors.white,
                                height: 1.6,
                              )
                            : MarkdownBody(
                                data: message.text,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: AppColors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                    height: 1.6,
                                  ),
                                  code: GoogleFonts.firaCode(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.08,
                                    ),
                                    color: AppColors.accent,
                                    fontSize: 14,
                                  ),
                                  codeblockPadding: const EdgeInsets.all(16),
                                  codeblockDecoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  blockquote: GoogleFonts.inter(
                                    color: AppColors.white60,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  blockquoteDecoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: AppColors.accent,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    if (!isUser) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.bolt, color: AppColors.white, size: 20),
      );
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final imagePath = chatProvider.currentUserAvatar;
        final name =
            chatProvider.currentUserName ??
            (chatProvider.currentUserEmail != null
                ? chatProvider.currentUserEmail!.split('@')[0]
                : "U");

        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF5436DA),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            image: imagePath != null
                ? (imagePath.startsWith('data:image')
                      ? DecorationImage(
                          image: MemoryImage(
                            base64Decode(imagePath.split(',').last),
                          ),
                          fit: BoxFit.cover,
                        )
                      : DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(imagePath)
                              : FileImage(io.File(imagePath)) as ImageProvider,
                          fit: BoxFit.cover,
                        ))
                : null,
          ),
          child: imagePath == null
              ? Center(
                  child: CustomText(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "U",
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      },
    );
  }
}
