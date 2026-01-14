import 'package:equatable/equatable.dart';
import '../../domain/enums/message_role.dart';
import '../../domain/enums/message_status.dart';

/// Model representing a message in a conversation
class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String content;
  final MessageRole role;
  final DateTime createdAt;
  final MessageStatus status;
  final int? tokenCount;
  final Duration? generationTime;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.tokenCount,
    this.generationTime,
  });

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? content,
    MessageRole? role,
    DateTime? createdAt,
    MessageStatus? status,
    int? tokenCount,
    Duration? generationTime,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      tokenCount: tokenCount ?? this.tokenCount,
      generationTime: generationTime ?? this.generationTime,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        content,
        role,
        createdAt,
        status,
        tokenCount,
        generationTime,
      ];
}
