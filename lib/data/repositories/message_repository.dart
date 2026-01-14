import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/message_model.dart';
import '../../domain/enums/message_role.dart';
import '../../domain/enums/message_status.dart';

/// Repository for managing messages
class MessageRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  MessageRepository(this._db);

  /// Get all messages for a conversation
  Future<List<MessageModel>> getMessagesForConversation(
      String conversationId) async {
    final results = await _db.getMessagesForConversation(conversationId);
    return results.map(_mapToModel).toList();
  }

  /// Watch messages for a conversation
  Stream<List<MessageModel>> watchMessagesForConversation(
      String conversationId) {
    return _db.watchMessagesForConversation(conversationId).map(
          (list) => list.map(_mapToModel).toList(),
        );
  }

  /// Create a new message
  Future<MessageModel> createMessage({
    required String conversationId,
    required String content,
    required MessageRole role,
    MessageStatus status = MessageStatus.sent,
    int? tokenCount,
    Duration? generationTime,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.insertMessage(
      MessagesCompanion(
        id: Value(id),
        conversationId: Value(conversationId),
        content: Value(content),
        role: Value(role.name),
        createdAt: Value(now),
        status: Value(status.name),
        tokenCount: Value(tokenCount),
        generationTimeMs: Value(generationTime?.inMilliseconds),
      ),
    );

    return MessageModel(
      id: id,
      conversationId: conversationId,
      content: content,
      role: role,
      createdAt: now,
      status: status,
      tokenCount: tokenCount,
      generationTime: generationTime,
    );
  }

  /// Update a message
  Future<void> updateMessage(MessageModel message) async {
    await _db.updateMessage(
      MessagesCompanion(
        id: Value(message.id),
        content: Value(message.content),
        status: Value(message.status.name),
        tokenCount: Value(message.tokenCount),
        generationTimeMs: Value(message.generationTime?.inMilliseconds),
      ),
    );
  }

  /// Update message status
  Future<void> updateMessageStatus(String id, MessageStatus status) async {
    await _db.updateMessage(
      MessagesCompanion(
        id: Value(id),
        status: Value(status.name),
      ),
    );
  }

  /// Delete a message
  Future<void> deleteMessage(String id) async {
    await _db.deleteMessage(id);
  }

  /// Get message count for a conversation
  Future<int> getMessageCount(String conversationId) async {
    return await _db.getMessageCount(conversationId);
  }

  MessageModel _mapToModel(Message data) {
    return MessageModel(
      id: data.id,
      conversationId: data.conversationId,
      content: data.content,
      role: MessageRole.values.firstWhere(
        (r) => r.name == data.role,
        orElse: () => MessageRole.user,
      ),
      createdAt: data.createdAt,
      status: MessageStatus.values.firstWhere(
        (s) => s.name == data.status,
        orElse: () => MessageStatus.sent,
      ),
      tokenCount: data.tokenCount,
      generationTime: data.generationTimeMs != null
          ? Duration(milliseconds: data.generationTimeMs!)
          : null,
    );
  }
}
