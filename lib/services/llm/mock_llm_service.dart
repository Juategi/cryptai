import 'dart:async';
import 'llm_service.dart';
import 'llm_response.dart';

/// Mock implementation for development and testing.
/// Simulates LLM behavior with configurable delays and responses.
class MockLLMService implements LLMService {
  bool _isReady = false;
  LLMModelInfo? _currentModel;
  bool _isCancelled = false;

  final List<LLMModelInfo> _mockModels = const [
    LLMModelInfo(
      id: 'mock-fast',
      name: 'Mock Fast',
      description: 'Fast placeholder responses for testing',
      parameterCount: 0,
      requiredMemoryMB: 0,
      isDownloaded: true,
    ),
    LLMModelInfo(
      id: 'mock-realistic',
      name: 'Mock Realistic',
      description: 'Simulates realistic generation timing with streaming',
      parameterCount: 0,
      requiredMemoryMB: 0,
      isDownloaded: true,
    ),
    LLMModelInfo(
      id: 'phi-2-placeholder',
      name: 'Phi-2 (Not Downloaded)',
      description: 'Microsoft Phi-2 2.7B - Requires download',
      parameterCount: 3,
      requiredMemoryMB: 3000,
      isDownloaded: false,
    ),
    LLMModelInfo(
      id: 'llama-7b-placeholder',
      name: 'Llama 2 7B (Not Downloaded)',
      description: 'Meta Llama 2 7B - Requires download',
      parameterCount: 7,
      requiredMemoryMB: 5000,
      isDownloaded: false,
    ),
  ];

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isReady = true;
  }

  @override
  bool get isReady => _isReady;

  @override
  LLMModelInfo? get currentModel => _currentModel;

  @override
  Future<List<LLMModelInfo>> getAvailableModels() async => _mockModels;

  @override
  Future<void> loadModel(String modelId) async {
    final model = _mockModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw Exception('Model not found: $modelId'),
    );

    if (!model.isDownloaded) {
      throw Exception('Model not downloaded: ${model.name}');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _currentModel = model;
  }

  @override
  Future<void> unloadModel() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentModel = null;
  }

  @override
  Future<LLMResponse> generateResponse({
    required List<LLMMessage> messages,
    String? systemPrompt,
    int maxTokens = 2048,
    double temperature = 0.7,
    double topP = 0.9,
    void Function(String token)? onToken,
  }) async {
    _isCancelled = false;
    final stopwatch = Stopwatch()..start();

    if (_currentModel == null) {
      return LLMResponse.error('No model loaded');
    }

    // Generate mock response based on last user message
    final lastUserMessage = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => const LLMMessage(role: 'user', content: ''),
    );

    final response = _generateMockResponse(lastUserMessage.content);

    // Simulate streaming if callback provided and using realistic mode
    if (onToken != null && _currentModel!.id == 'mock-realistic') {
      final words = response.split(' ');
      for (int i = 0; i < words.length; i++) {
        if (_isCancelled) {
          return LLMResponse(
            content: words.sublist(0, i).join(' '),
            generationTime: stopwatch.elapsed,
            status: LLMResponseStatus.cancelled,
          );
        }
        await Future.delayed(const Duration(milliseconds: 50));
        onToken(i == 0 ? words[i] : ' ${words[i]}');
      }
    } else {
      // Fast mode - small delay
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isCancelled) {
        return LLMResponse(
          content: '',
          generationTime: stopwatch.elapsed,
          status: LLMResponseStatus.cancelled,
        );
      }
    }

    stopwatch.stop();

    return LLMResponse(
      content: response,
      promptTokens: _estimateTokens(messages.map((m) => m.content).join()),
      completionTokens: _estimateTokens(response),
      generationTime: stopwatch.elapsed,
      wasStreamed: onToken != null,
    );
  }

  @override
  Future<void> cancelGeneration() async {
    _isCancelled = true;
  }

  @override
  Future<void> dispose() async {
    await unloadModel();
    _isReady = false;
  }

  String _generateMockResponse(String input) {
    final lowered = input.toLowerCase();

    if (lowered.contains('hello') || lowered.contains('hi') || lowered.contains('hola')) {
      return 'Hello! I am CryptAI, your private AI assistant running completely offline on your device. '
          'All our conversations are encrypted and stored locally - no data ever leaves your phone. '
          'How can I help you today?';
    }

    if (lowered.contains('help') || lowered.contains('ayuda')) {
      return 'I can help you with various tasks! This is currently a mock response '
          'demonstrating the chat interface.\n\n'
          'When a real local LLM model is loaded, I will be able to assist with:\n\n'
          '• Answering questions on many topics\n'
          '• Writing and editing text\n'
          '• Brainstorming ideas\n'
          '• Explaining concepts\n'
          '• Code assistance\n'
          '• And much more!\n\n'
          'All processing happens locally on your device for complete privacy.';
    }

    if (lowered.contains('privacy') || lowered.contains('private') || lowered.contains('privacidad')) {
      return 'Your privacy is our top priority! Here\'s how CryptAI protects you:\n\n'
          '🔒 **100% Offline**: No internet connection required\n'
          '🔐 **Encrypted Storage**: All conversations are encrypted with AES-256\n'
          '📱 **Local Processing**: AI runs entirely on your device\n'
          '🚫 **No Data Collection**: We never collect or transmit your data\n\n'
          'Your conversations stay on your device, always.';
    }

    if (lowered.contains('how') && lowered.contains('work')) {
      return 'CryptAI works by running a local Large Language Model (LLM) directly on your device. '
          'Here\'s the technical overview:\n\n'
          '1. **Local Model**: A quantized LLM runs using your phone\'s CPU/GPU\n'
          '2. **No Cloud**: All inference happens locally - no API calls\n'
          '3. **Encrypted Database**: SQLCipher encrypts all stored data\n'
          '4. **Secure Keys**: Encryption keys are stored in secure hardware\n\n'
          'This ensures maximum privacy while still providing helpful AI assistance.';
    }

    // Default response
    return 'This is a mock response to demonstrate the chat interface. '
        'Your message was: "$input"\n\n'
        'In the future, with a real local LLM model loaded (like Phi-2 or Llama), '
        'you\'ll receive intelligent, context-aware responses generated entirely on your device.\n\n'
        '**Remember**: All your conversations are encrypted and never leave your phone!';
  }

  int _estimateTokens(String text) => (text.length / 4).round();
}
