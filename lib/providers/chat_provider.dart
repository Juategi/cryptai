import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message_model.dart';
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
}
