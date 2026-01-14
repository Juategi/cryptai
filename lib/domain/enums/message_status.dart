/// Status of a message
enum MessageStatus {
  /// Message is being composed
  pending,

  /// Message sent, waiting for AI response
  sending,

  /// Message successfully processed
  sent,

  /// Message failed to process
  error;

  bool get isLoading => this == MessageStatus.pending || this == MessageStatus.sending;
}
