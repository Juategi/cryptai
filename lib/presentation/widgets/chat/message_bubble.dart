import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/message_model.dart';
import '../../../domain/enums/message_role.dart';

/// Chat message bubble widget
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 16,
          right: isUser ? 16 : 48,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.userBubble
                    : (isDark
                        ? AppColors.assistantBubbleDark
                        : AppColors.assistantBubble),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? AppColors.userBubbleText
                      : (isDark
                          ? AppColors.assistantBubbleTextDark
                          : AppColors.assistantBubbleText),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            if (showTimestamp) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Streaming message bubble (for AI response being generated)
class StreamingMessageBubble extends StatelessWidget {
  final String content;

  const StreamingMessageBubble({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.only(
          left: 16,
          right: 48,
          top: 4,
          bottom: 4,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.assistantBubbleDark
                : AppColors.assistantBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  content.isEmpty ? '...' : content,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.assistantBubbleTextDark
                        : AppColors.assistantBubbleText,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark
                      ? AppColors.assistantBubbleTextDark.withValues(alpha: 0.5)
                      : AppColors.assistantBubbleText.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
