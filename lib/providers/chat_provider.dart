import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message_model.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/message_repository.dart';
import '../domain/enums/message_role.dart';
import '../domain/enums/message_status.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/llm_response.dart';
import 'database_provider.dart';
import 'conversation_provider.dart';
import 'llm_provider.dart';

/// Provider for message repository
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MessageRepository(db);
});

/// Provider that watches messages for the active conversation
final chatMessagesProvider = StreamProvider<List<MessageModel>>((ref) {
  final conversation = ref.watch(activeConversationProvider);
  if (conversation == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(messageRepositoryProvider);
  return repo.watchMessagesForConversation(conversation.id);
});

/// Provider for chat state and actions
final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref);
});

/// State for the chat
class ChatState {
  final bool isGenerating;
  final String streamingContent;
  final String? error;

  const ChatState({
    this.isGenerating = false,
    this.streamingContent = '',
    this.error,
  });

  ChatState copyWith({
    bool? isGenerating,
    String? streamingContent,
    String? error,
  }) {
    return ChatState(
      isGenerating: isGenerating ?? this.isGenerating,
      streamingContent: streamingContent ?? this.streamingContent,
      error: error,
    );
  }
}

/// Controller for chat actions
class ChatController extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatController(this._ref) : super(const ChatState());

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final conversation = _ref.read(activeConversationProvider);
    if (conversation == null) return;

    state = state.copyWith(isGenerating: true, error: null, streamingContent: '');

    try {
      final messageRepo = _ref.read(messageRepositoryProvider);
      final conversationRepo = _ref.read(conversationRepositoryProvider);
      final llmService = _ref.read(llmServiceProvider);

      // Save user message
      await messageRepo.createMessage(
        conversationId: conversation.id,
        content: content,
        role: MessageRole.user,
        status: MessageStatus.sent,
      );

      // Get conversation history for context
      final messages = await messageRepo.getMessagesForConversation(conversation.id);
      final llmMessages = messages.map((m) => LLMMessage(
            role: m.role.name,
            content: m.content,
          )).toList();

      // Generate response with streaming
      final response = await llmService.generateResponse(
        messages: llmMessages,
        systemPrompt: conversation.systemPrompt,
        onToken: (token) {
          state = state.copyWith(
            streamingContent: state.streamingContent + token,
          );
        },
      );

      if (response.isSuccess) {
        // Save assistant message
        await messageRepo.createMessage(
          conversationId: conversation.id,
          content: response.content,
          role: MessageRole.assistant,
          status: MessageStatus.sent,
          tokenCount: response.totalTokens,
          generationTime: response.generationTime,
        );

        // Update conversation metadata
        final messageCount = await messageRepo.getMessageCount(conversation.id);
        await conversationRepo.updateAfterMessage(
          conversation.id,
          lastMessagePreview: response.content.length > 100
              ? '${response.content.substring(0, 100)}...'
              : response.content,
          messageCount: messageCount,
        );

        // Generate title from first message (if it's a new conversation)
        if (conversation.title == 'New Chat' && messages.length == 1) {
          _generateTitle(content, llmService, conversationRepo, conversation.id);
        }
      } else if (response.status == LLMResponseStatus.cancelled) {
        // Handle cancellation - save partial response if any
        if (state.streamingContent.isNotEmpty) {
          await messageRepo.createMessage(
            conversationId: conversation.id,
            content: state.streamingContent,
            role: MessageRole.assistant,
            status: MessageStatus.sent,
          );
        }
      } else {
        state = state.copyWith(error: response.errorMessage ?? 'Unknown error');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(
        isGenerating: false,
        streamingContent: '',
      );
    }
  }

  Future<void> cancelGeneration() async {
    final llmService = _ref.read(llmServiceProvider);
    await llmService.cancelGeneration();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Generate a title for the conversation based on the first message
  Future<void> _generateTitle(
    String userMessage,
    LLMService llmService,
    ConversationRepository conversationRepo,
    String conversationId,
  ) async {
    try {
      // Use a more explicit prompt format that forces the model to output just a title
      final titleResponse = await llmService.generateResponse(
        messages: [
          LLMMessage(
            role: 'user',
            content: 'Extract the main topic from this text in 2-4 words. Output ONLY the topic, nothing else.\n\nText: "$userMessage"\n\nTopic:',
          ),
        ],
        systemPrompt:
            'You are a title extractor. Output only 2-4 words describing the main topic. No explanations, no sentences, no punctuation. Just the topic words.',
        maxTokens: 10,
        temperature: 0.1,
      );

      if (titleResponse.isSuccess && titleResponse.content.isNotEmpty) {
        // Clean the title
        String title = titleResponse.content
            .replaceAll('"', '')
            .replaceAll("'", '')
            .replaceAll('.', '')
            .replaceAll(':', '')
            .replaceAll('!', '')
            .replaceAll('?', '')
            .replaceAll('\n', ' ')
            .trim();

        // Reject conversational responses (starts with common conversation starters)
        final lowerTitle = title.toLowerCase();
        if (lowerTitle.startsWith('sure') ||
            lowerTitle.startsWith('here') ||
            lowerTitle.startsWith('the topic') ||
            lowerTitle.startsWith('i ') ||
            lowerTitle.startsWith('this ') ||
            lowerTitle.startsWith('okay') ||
            lowerTitle.startsWith('ok ') ||
            lowerTitle.contains('topic is')) {
          // Fallback: extract key words from user message
          title = _extractKeyWords(userMessage);
        }

        // Limit to 4 words max
        final words = title.split(' ').where((w) => w.isNotEmpty).toList();
        if (words.length > 4) {
          title = words.take(4).join(' ');
        }

        if (title.isNotEmpty && title.length > 1) {
          await conversationRepo.updateTitle(conversationId, title);

          // Update active conversation
          final conversation = _ref.read(activeConversationProvider);
          if (conversation != null && conversation.id == conversationId) {
            _ref
                .read(activeConversationProvider.notifier)
                .setConversation(conversation.copyWith(title: title));
          }
        }
      }
    } catch (e) {
      // Silently fail - title generation is not critical
      debugPrint('Failed to generate title: $e');
    }
  }

  /// Fallback method to extract key words from user message
  String _extractKeyWords(String message) {
    // Remove common question words and extract meaningful words
    final stopWords = {
      'what', 'how', 'why', 'when', 'where', 'who', 'which', 'is', 'are', 'was',
      'were', 'do', 'does', 'did', 'can', 'could', 'would', 'should', 'will',
      'the', 'a', 'an', 'of', 'to', 'in', 'for', 'on', 'with', 'at', 'by',
      'from', 'as', 'be', 'this', 'that', 'it', 'and', 'or', 'but', 'if',
      'me', 'my', 'i', 'you', 'your', 'we', 'our', 'they', 'their', 'about',
      'tell', 'explain', 'describe', 'give', 'show', 'please', 'help',
      'que', 'como', 'por', 'para', 'el', 'la', 'los', 'las', 'un', 'una',
      'de', 'en', 'es', 'son', 'del', 'al', 'con', 'se', 'su', 'sus', 'mi',
    };

    final words = message
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .take(4)
        .toList();

    if (words.isEmpty) {
      return 'Chat';
    }

    // Capitalize first letter of each word
    return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
