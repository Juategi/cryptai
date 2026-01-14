/// Response from LLM inference
class LLMResponse {
  final String content;
  final int promptTokens;
  final int completionTokens;
  final Duration generationTime;
  final bool wasStreamed;
  final LLMResponseStatus status;
  final String? errorMessage;

  const LLMResponse({
    required this.content,
    this.promptTokens = 0,
    this.completionTokens = 0,
    required this.generationTime,
    this.wasStreamed = false,
    this.status = LLMResponseStatus.success,
    this.errorMessage,
  });

  factory LLMResponse.error(String message) => LLMResponse(
        content: '',
        generationTime: Duration.zero,
        status: LLMResponseStatus.error,
        errorMessage: message,
      );

  int get totalTokens => promptTokens + completionTokens;

  bool get isSuccess => status == LLMResponseStatus.success;
  bool get isError => status == LLMResponseStatus.error;
}

/// Status of LLM response
enum LLMResponseStatus {
  success,
  cancelled,
  error,
  outOfMemory,
  modelNotLoaded,
}
