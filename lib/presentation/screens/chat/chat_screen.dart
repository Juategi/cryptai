import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/conversation_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../widgets/chat/message_list.dart';
import '../../widgets/chat/chat_input_field.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

/// Chat conversation screen
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  ConversationRepository? _conversationRepo;

  @override
  void initState() {
    super.initState();
    // Load conversation if not already active
    _loadConversation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache repo reference before dispose
    _conversationRepo = ref.read(conversationRepositoryProvider);
  }

  @override
  void dispose() {
    // Clean up empty conversation when leaving this screen
    final conversation = ref.read(activeConversationProvider);
    if (conversation != null && conversation.messageCount == 0) {
      _conversationRepo?.deleteConversation(conversation.id);
    }
    super.dispose();
  }

  Future<void> _loadConversation() async {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation?.id != widget.conversationId) {
      final repo = ref.read(conversationRepositoryProvider);
      final conversation = await repo.getConversation(widget.conversationId);
      if (conversation != null && mounted) {
        ref.read(activeConversationProvider.notifier).setConversation(conversation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(activeConversationProvider);
    final messagesAsync = ref.watch(chatMessagesProvider);
    final chatState = ref.watch(chatControllerProvider);
    final settings = ref.watch(settingsProvider);

    if (conversation == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const LoadingWidget(message: 'Loading conversation...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showRenameDialog(context, ref, conversation.title),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  conversation.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 12),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'system_prompt',
                child: Row(
                  children: [
                    Icon(Icons.psychology_outlined),
                    SizedBox(width: 12),
                    Text('System Prompt'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Clear Messages', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (chatState.error != null)
            MaterialBanner(
              content: Text(chatState.error!),
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              contentTextStyle: const TextStyle(color: AppColors.error),
              actions: [
                TextButton(
                  onPressed: () =>
                      ref.read(chatControllerProvider.notifier).clearError(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty && !chatState.isGenerating) {
                  return EmptyStateWidget(
                    icon: Icons.chat_outlined,
                    title: 'Start the conversation',
                    message: 'Send a message to begin chatting with your private AI',
                  );
                }

                return MessageList(
                  messages: messages,
                  streamingContent: chatState.streamingContent.isNotEmpty
                      ? chatState.streamingContent
                      : null,
                  showTimestamps: settings.showTimestamps,
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => Center(
                child: Text('Error loading messages: $error'),
              ),
            ),
          ),
          // Typing indicator when generating but no streaming content yet
          if (chatState.isGenerating && chatState.streamingContent.isEmpty)
            const TypingIndicator(),
          // Input field
          ChatInputField(
            enabled: !chatState.isGenerating,
            onSend: (content) {
              ref.read(chatControllerProvider.notifier).sendMessage(content);
            },
            onCancel: chatState.isGenerating
                ? () => ref.read(chatControllerProvider.notifier).cancelGeneration()
                : null,
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    final conversation = ref.read(activeConversationProvider);
    if (conversation == null) return;

    switch (action) {
      case 'rename':
        _showRenameDialog(context, ref, conversation.title);
        break;
      case 'system_prompt':
        _showSystemPromptDialog(context, ref, conversation.systemPrompt);
        break;
      case 'clear':
        _showClearMessagesDialog(context, ref);
        break;
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentTitle,
  ) async {
    final controller = TextEditingController(text: currentTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final conversation = ref.read(activeConversationProvider);
      if (conversation != null) {
        final repo = ref.read(conversationRepositoryProvider);
        await repo.updateTitle(conversation.id, result.trim());
        ref.read(activeConversationProvider.notifier).setConversation(
              conversation.copyWith(title: result.trim()),
            );
      }
    }
  }

  Future<void> _showSystemPromptDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentPrompt,
  ) async {
    final controller = TextEditingController(text: currentPrompt ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set instructions for how the AI should behave in this conversation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'System Prompt',
                hintText: 'e.g., You are a helpful coding assistant...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (currentPrompt != null)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Clear'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final conversation = ref.read(activeConversationProvider);
      if (conversation != null) {
        final repo = ref.read(conversationRepositoryProvider);
        final updatedConversation = conversation.copyWith(
          systemPrompt: result.isEmpty ? null : result,
        );
        await repo.updateConversation(updatedConversation);
        ref.read(activeConversationProvider.notifier).setConversation(updatedConversation);
      }
    }
  }

  Future<void> _showClearMessagesDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Messages'),
        content: const Text(
          'Are you sure you want to delete all messages in this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final conversation = ref.read(activeConversationProvider);
      if (conversation != null) {
        // Delete all messages and update conversation
        final conversationRepo = ref.read(conversationRepositoryProvider);
        await conversationRepo.updateConversation(
          conversation.copyWith(
            messageCount: 0,
            lastMessagePreview: null,
          ),
        );
      }
    }
  }
}
