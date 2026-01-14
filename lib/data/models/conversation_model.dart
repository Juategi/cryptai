import 'package:equatable/equatable.dart';

/// Model representing a conversation
class ConversationModel extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessagePreview;
  final int messageCount;
  final String? systemPrompt;

  const ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessagePreview,
    this.messageCount = 0,
    this.systemPrompt,
  });

  ConversationModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessagePreview,
    int? messageCount,
    String? systemPrompt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      messageCount: messageCount ?? this.messageCount,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        updatedAt,
        lastMessagePreview,
        messageCount,
        systemPrompt,
      ];
}
