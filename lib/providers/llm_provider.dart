import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/mock_llm_service.dart';

/// Provider for the LLM service
final llmServiceProvider = Provider<LLMService>((ref) {
  throw UnimplementedError(
    'LLM service provider must be overridden with an initialized service',
  );
});

/// Provider for available models
final availableModelsProvider = FutureProvider<List<LLMModelInfo>>((ref) async {
  final service = ref.watch(llmServiceProvider);
  return service.getAvailableModels();
});

/// Provider for current model info
final currentModelProvider = Provider<LLMModelInfo?>((ref) {
  final service = ref.watch(llmServiceProvider);
  return service.currentModel;
});

/// Provider for LLM ready state
final llmReadyProvider = Provider<bool>((ref) {
  final service = ref.watch(llmServiceProvider);
  return service.isReady;
});

/// Creates and initializes the LLM service
Future<LLMService> createLLMService() async {
  final service = MockLLMService();
  await service.initialize();
  await service.loadModel('mock-fast');
  return service;
}
