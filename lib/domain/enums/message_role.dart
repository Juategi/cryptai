/// Role of a message in a conversation
enum MessageRole {
  /// Message from the user
  user,

  /// Message from the AI assistant
  assistant,

  /// System prompt or instruction
  system;

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return 'You';
      case MessageRole.assistant:
        return 'Assistant';
      case MessageRole.system:
        return 'System';
    }
  }
}
