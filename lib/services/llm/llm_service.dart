import 'llm_response.dart';

/// Abstract interface for LLM inference services.
/// This allows easy swapping between mock, local (fllama), and potential
/// cloud fallback implementations.
abstract class LLMService {
  /// Initialize the service and load the model
  Future<void> initialize();

  /// Check if service is ready for inference
  bool get isReady;

  /// Get information about the currently loaded model
  LLMModelInfo? get currentModel;

  /// List available models
  Future<List<LLMModelInfo>> getAvailableModels();

  /// Load a specific model by ID
  Future<void> loadModel(String modelId);

  /// Unload current model to free memory
  Future<void> unloadModel();

  /// Generate a response from the LLM
  /// [messages] - List of conversation messages for context
  /// [systemPrompt] - Optional system prompt to set behavior
  /// [maxTokens] - Maximum tokens in response
  /// [temperature] - Randomness (0.0-1.0)
  /// [onToken] - Callback for streaming tokens (optional)
  Future<LLMResponse> generateResponse({
    required List<LLMMessage> messages,
    String? systemPrompt,
    int maxTokens = 2048,
    double temperature = 0.7,
    double topP = 0.9,
    void Function(String token)? onToken,
  });

  /// Cancel ongoing generation
  Future<void> cancelGeneration();

  /// Dispose resources
  Future<void> dispose();
}

/// Represents a message in the conversation context
class LLMMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;

  const LLMMessage({
    required this.role,
    required this.content,
  });
}

/// Information about an LLM model
class LLMModelInfo {
  final String id;
  final String name;
  final String? description;
  final int parameterCount; // in billions
  final int requiredMemoryMB;
  final bool isDownloaded;
  final String? localPath;

  const LLMModelInfo({
    required this.id,
    required this.name,
    this.description,
    required this.parameterCount,
    required this.requiredMemoryMB,
    this.isDownloaded = false,
    this.localPath,
  });
}
