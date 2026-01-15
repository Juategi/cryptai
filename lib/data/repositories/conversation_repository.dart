import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/conversation_model.dart';

/// Repository for managing conversations
class ConversationRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  ConversationRepository(this._db);

  /// Get all conversations
  Future<List<ConversationModel>> getAllConversations() async {
    final results = await _db.getAllConversations();
    return results.map(_mapToModel).toList();
  }

  /// Watch all conversations for reactive updates
  Stream<List<ConversationModel>> watchAllConversations() {
    return _db.watchAllConversations().map(
          (list) => list.map(_mapToModel).toList(),
        );
  }

  /// Get a conversation by ID
  Future<ConversationModel?> getConversation(String id) async {
    final result = await _db.getConversation(id);
    return result != null ? _mapToModel(result) : null;
  }

  /// Create a new conversation
  Future<ConversationModel> createConversation({
    String title = 'New Chat',
    String? systemPrompt,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.insertConversation(
      ConversationsCompanion(
        id: Value(id),
        title: Value(title),
        createdAt: Value(now),
        updatedAt: Value(now),
        systemPrompt: Value(systemPrompt),
      ),
    );

    return ConversationModel(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      systemPrompt: systemPrompt,
    );
  }

  /// Update a conversation
  Future<void> updateConversation(ConversationModel conversation) async {
    await _db.updateConversation(
      ConversationsCompanion(
        id: Value(conversation.id),
        title: Value(conversation.title),
        updatedAt: Value(DateTime.now()),
        lastMessagePreview: Value(conversation.lastMessagePreview),
        messageCount: Value(conversation.messageCount),
        systemPrompt: Value(conversation.systemPrompt),
      ),
    );
  }

  /// Update conversation title
  Future<void> updateTitle(String id, String title) async {
    final conversation = await getConversation(id);
    if (conversation != null) {
      await updateConversation(conversation.copyWith(title: title));
    }
  }

  /// Update conversation after a new message
  Future<void> updateAfterMessage(
    String id, {
    required String lastMessagePreview,
    required int messageCount,
  }) async {
    final conversation = await getConversation(id);
    if (conversation != null) {
      await updateConversation(conversation.copyWith(
        lastMessagePreview: lastMessagePreview,
        messageCount: messageCount,
      ));
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String id) async {
    await _db.deleteConversation(id);
  }

  /// Delete all empty conversations (no messages)
  Future<void> deleteEmptyConversations() async {
    final conversations = await getAllConversations();
    for (final conversation in conversations) {
      if (conversation.messageCount == 0) {
        await deleteConversation(conversation.id);
      }
    }
  }

  /// Search conversations by title or message content
  Future<List<ConversationModel>> searchConversations(String query) async {
    if (query.trim().isEmpty) {
      return getAllConversations();
    }
    final results = await _db.searchConversations(query);
    return results.map(_mapToModel).toList();
  }

  ConversationModel _mapToModel(Conversation data) {
    return ConversationModel(
      id: data.id,
      title: data.title,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      lastMessagePreview: data.lastMessagePreview,
      messageCount: data.messageCount,
      systemPrompt: data.systemPrompt,
    );
  }
}
