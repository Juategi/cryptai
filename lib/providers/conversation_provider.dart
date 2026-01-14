import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/conversation_model.dart';
import '../data/repositories/conversation_repository.dart';
import 'database_provider.dart';

/// Provider for conversation repository
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ConversationRepository(db);
});

/// Provider that watches all conversations
final conversationsProvider = StreamProvider<List<ConversationModel>>((ref) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.watchAllConversations();
});

/// Provider for the currently active conversation
final activeConversationProvider =
    StateNotifierProvider<ActiveConversationNotifier, ConversationModel?>(
  (ref) => ActiveConversationNotifier(),
);

/// Notifier for managing the active conversation
class ActiveConversationNotifier extends StateNotifier<ConversationModel?> {
  ActiveConversationNotifier() : super(null);

  void setConversation(ConversationModel conversation) {
    state = conversation;
  }

  void updateConversation(ConversationModel conversation) {
    if (state?.id == conversation.id) {
      state = conversation;
    }
  }

  void clear() {
    state = null;
  }
}
