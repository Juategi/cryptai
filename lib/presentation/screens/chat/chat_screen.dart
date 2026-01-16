import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../providers/conversation_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../widgets/chat/message_list.dart';
import '../../widgets/chat/chat_input_field.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/common/loading_widget.dart';

/// Main chat screen with drawer for conversation list
class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;

  const ChatScreen({super.key, this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ConversationRepository? _conversationRepo;
  String? _currentConversationId;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _conversationRepo = ref.read(conversationRepositoryProvider);
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationId != oldWidget.conversationId) {
      _currentConversationId = widget.conversationId;
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    // Clean up previous empty conversation if switching
    await _cleanupEmptyConversation();

    if (widget.conversationId != null) {
      // Load existing conversation
      await _loadConversation(widget.conversationId!);
    } else {
      // Create new conversation
      await _createNewChat();
    }
  }

  Future<void> _cleanupEmptyConversation() async {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation != null && _conversationRepo != null) {
      final conversation = await _conversationRepo!.getConversation(
        activeConversation.id,
      );
      if (conversation != null && conversation.messageCount == 0) {
        await _conversationRepo!.deleteConversation(activeConversation.id);
      }
    }
  }

  Future<void> _loadConversation(String id) async {
    final repo = ref.read(conversationRepositoryProvider);
    final conversation = await repo.getConversation(id);
    if (conversation != null && mounted) {
      _currentConversationId = conversation.id;
      ref
          .read(activeConversationProvider.notifier)
          .setConversation(conversation);
    }
  }

  Future<void> _createNewChat() async {
    final repo = ref.read(conversationRepositoryProvider);
    final conversation = await repo.createConversation(title: ' ');
    if (mounted) {
      _currentConversationId = conversation.id;
      ref
          .read(activeConversationProvider.notifier)
          .setConversation(conversation);
    }
  }

  Future<void> _selectConversation(ConversationModel conversation) async {
    // Clean up current empty conversation before switching
    await _cleanupEmptyConversation();

    _currentConversationId = conversation.id;
    ref.read(activeConversationProvider.notifier).setConversation(conversation);

    if (mounted) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  Future<void> _startNewChat() async {
    // Clean up current empty conversation
    await _cleanupEmptyConversation();

    await _createNewChat();

    if (mounted) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(activeConversationProvider);
    final messagesAsync = ref.watch(chatMessagesProvider);
    final chatState = ref.watch(chatControllerProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          conversation?.title ?? 'CryptAI',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      drawer: _ChatDrawer(
        onNewChat: _startNewChat,
        onSelectConversation: _selectConversation,
        currentConversationId: _currentConversationId,
      ),
      body: conversation == null
          ? const LoadingWidget(message: 'Loading...')
          : Column(
              children: [
                // Error banner
                if (chatState.error != null)
                  MaterialBanner(
                    content: Text(chatState.error!),
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    contentTextStyle: const TextStyle(color: AppColors.error),
                    actions: [
                      TextButton(
                        onPressed: () => ref
                            .read(chatControllerProvider.notifier)
                            .clearError(),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                // Messages
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty && !chatState.isGenerating) {
                        final theme = Theme.of(context);
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: ListView(
                            children: [
                              // Logo
                              Center(
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 80,
                                  height: 80,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Title
                              Text(
                                'Welcome to CryptAI',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blueDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your private, offline AI assistant',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.blueDeep,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              // Privacy features
                              _buildFeatureCard(
                                icon: Icons.wifi_off_rounded,
                                title: '100% Offline',
                                description:
                                    'No internet required. All processing on-device.',
                              ),
                              const SizedBox(height: 12),
                              _buildFeatureCard(
                                icon: Icons.security_rounded,
                                title: 'Encrypted Storage',
                                description:
                                    'All conversations encrypted with AES-256.',
                              ),
                              const SizedBox(height: 12),
                              _buildFeatureCard(
                                icon: Icons.visibility_off_rounded,
                                title: 'Complete Privacy',
                                description:
                                    'Your data never leaves your device.',
                              ),
                              const SizedBox(height: 60),
                              Text(
                                'Start the conversation',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColors.blueDeep,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Send a message to begin chatting with your private AI',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.blueDeep,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
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
                    error: (error, stack) =>
                        Center(child: Text('Error loading messages: $error')),
                  ),
                ),
                // Typing indicator
                if (chatState.isGenerating &&
                    chatState.streamingContent.isEmpty)
                  const TypingIndicator(),
                // Input field
                ChatInputField(
                  enabled: !chatState.isGenerating,
                  onSend: (content) {
                    ref
                        .read(chatControllerProvider.notifier)
                        .sendMessage(content);
                  },
                  onCancel: chatState.isGenerating
                      ? () => ref
                            .read(chatControllerProvider.notifier)
                            .cancelGeneration()
                      : null,
                ),
              ],
            ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.turquoise.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.turquoise, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.blueDark,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.blueDeep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Drawer with conversation list and settings
class _ChatDrawer extends ConsumerStatefulWidget {
  final VoidCallback onNewChat;
  final Function(ConversationModel) onSelectConversation;
  final String? currentConversationId;

  const _ChatDrawer({
    required this.onNewChat,
    required this.onSelectConversation,
    this.currentConversationId,
  });

  @override
  ConsumerState<_ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<_ChatDrawer> {
  final TextEditingController _searchController = TextEditingController();
  List<ConversationModel>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final repo = ref.read(conversationRepositoryProvider);
    final results = await repo.searchConversations(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with logo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Image.asset('assets/logo.png', width: 70, height: 70),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
                onChanged: _performSearch,
              ),
            ),
            // New chat button
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New chat'),
              onTap: widget.onNewChat,
            ),
            const Divider(),
            // Conversation list
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _buildConversationList(conversationsAsync, theme),
            ),
            const Divider(),
            // Settings button
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(
    AsyncValue<List<ConversationModel>> conversationsAsync,
    ThemeData theme,
  ) {
    // Use search results if available, otherwise use the stream
    if (_searchResults != null) {
      if (_searchResults!.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No matches found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _searchResults!.length,
        itemBuilder: (context, index) {
          final conversation = _searchResults![index];
          return _buildConversationTile(conversation);
        },
      );
    }

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No conversations yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationTile(conversation);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildConversationTile(ConversationModel conversation) {
    final isSelected = conversation.id == widget.currentConversationId;

    return _DrawerConversationTile(
      conversation: conversation,
      isSelected: isSelected,
      onTap: () => widget.onSelectConversation(conversation),
      onRename: () => _renameConversation(conversation),
      onDelete: () => _deleteConversation(conversation),
    );
  }

  Future<void> _renameConversation(ConversationModel conversation) async {
    final controller = TextEditingController(text: conversation.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
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
      final repo = ref.read(conversationRepositoryProvider);
      await repo.updateTitle(conversation.id, result.trim());
      // Clear search to refresh
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    }
  }

  Future<void> _deleteConversation(ConversationModel conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete "${conversation.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(conversationRepositoryProvider);
      await repo.deleteConversation(conversation.id);
      // Clear search to refresh
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    }
  }
}

/// Conversation tile for drawer
class _DrawerConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _DrawerConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPressStart: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: ListTile(
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.3,
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: conversation.lastMessagePreview != null
            ? Text(
                conversation.lastMessagePreview!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 12),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: AppColors.error),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'rename') {
        onRename();
      } else if (value == 'delete') {
        onDelete();
      }
    });
  }
}
