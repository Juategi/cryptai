import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fllama/fllama.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'llm_service.dart';
import 'llm_response.dart';

/// LLM service implementation using fllama (llama.cpp bindings)
class FllamaLLMService implements LLMService {
  bool _isReady = false;
  LLMModelInfo? _currentModel;
  bool _isCancelled = false;
  String? _modelPath;
  double? _contextId;
  StreamSubscription? _tokenSubscription;

  static const String _modelAssetPath = 'assets/llama.gguf';
  static const String _modelFileName = 'llama.gguf';

  final LLMModelInfo _phi3Model = const LLMModelInfo(
    id: 'llama',
    name: 'Tiny Llama Phi-3 Mini',
    description:
        'A compact Phi-3 based LLaMA model optimized for local inference.',
    parameterCount: 4,
    requiredMemoryMB: 2500,
    isDownloaded: true,
  );

  @override
  Future<void> initialize() async {
    try {
      // Copy model from assets to app documents directory
      _modelPath = await _copyModelToDocuments();
      _isReady = true;
      debugPrint('FllamaLLMService: Initialized, model at $_modelPath');
    } catch (e) {
      _isReady = false;
      debugPrint('FllamaLLMService: Initialize failed: $e');
      rethrow;
    }
  }

  /// Copy the GGUF model from assets to documents directory
  Future<String> _copyModelToDocuments() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final modelFile = File(p.join(documentsDir.path, _modelFileName));

    // Check if model already exists
    if (await modelFile.exists()) {
      return modelFile.path;
    }

    // Copy from assets
    final byteData = await rootBundle.load(_modelAssetPath);
    final buffer = byteData.buffer;
    await modelFile.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );

    return modelFile.path;
  }

  @override
  bool get isReady => _isReady;

  @override
  LLMModelInfo? get currentModel => _currentModel;

  @override
  Future<List<LLMModelInfo>> getAvailableModels() async {
    return [
      LLMModelInfo(
        id: _phi3Model.id,
        name: _phi3Model.name,
        description: _phi3Model.description,
        parameterCount: _phi3Model.parameterCount,
        requiredMemoryMB: _phi3Model.requiredMemoryMB,
        isDownloaded: true,
        localPath: _modelPath,
      ),
    ];
  }

  @override
  Future<void> loadModel(String modelId) async {
    debugPrint('FllamaLLMService: loadModel called with $modelId');

    if (_modelPath == null) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    // Release any existing context
    if (_contextId != null) {
      await unloadModel();
    }

    final fllama = Fllama.instance();
    if (fllama == null) {
      throw Exception('Fllama not available on this platform');
    }

    debugPrint('FllamaLLMService: Initializing context...');

    // Initialize context with model
    final result = await fllama.initContext(
      _modelPath!,
      nCtx: 2048,
      nBatch: 512,
      nGpuLayers: 99,
      emitLoadProgress: true,
    );

    debugPrint('FllamaLLMService: initContext result: $result');

    if (result != null && result['contextId'] != null) {
      _contextId = (result['contextId'] as num).toDouble();
      _currentModel = LLMModelInfo(
        id: _phi3Model.id,
        name: _phi3Model.name,
        description: _phi3Model.description,
        parameterCount: _phi3Model.parameterCount,
        requiredMemoryMB: _phi3Model.requiredMemoryMB,
        isDownloaded: true,
        localPath: _modelPath,
      );
      debugPrint('FllamaLLMService: Model loaded, contextId: $_contextId');
    } else {
      throw Exception('Failed to load model: context initialization failed');
    }
  }

  @override
  Future<void> unloadModel() async {
    if (_contextId != null) {
      try {
        final fllama = Fllama.instance();
        await fllama?.releaseContext(_contextId!);
      } catch (_) {
        // Ignore errors during unload
      }
      _contextId = null;
      _currentModel = null;
    }
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
    debugPrint('FllamaLLMService: generateResponse called');
    _isCancelled = false;
    final stopwatch = Stopwatch()..start();

    if (_contextId == null || _currentModel == null) {
      debugPrint('FllamaLLMService: No model loaded!');
      return LLMResponse.error('No model loaded');
    }

    final fllama = Fllama.instance();
    if (fllama == null) {
      debugPrint('FllamaLLMService: Fllama not available!');
      return LLMResponse.error('Fllama not available');
    }

    try {
      // Build system prompt
      final sysPrompt =
          systemPrompt ??
          'You are a helpful, private AI assistant. Always respond in the same language the user writes to you. Be concise and helpful.';

      // Build prompt using ChatML format directly (avoid getFormattedChat issues)
      final formattedPrompt = _buildChatMLPrompt(messages, sysPrompt);
      debugPrint('FllamaLLMService: Prompt ready, length: ${formattedPrompt.length}');

      final responseBuffer = StringBuffer();

      // Set up token stream listener for streaming
      _tokenSubscription?.cancel();
      if (onToken != null) {
        _tokenSubscription = fllama.onTokenStream?.listen((data) {
          if (_isCancelled) return;

          final token = data['token'] as String?;
          if (token != null && token.isNotEmpty) {
            responseBuffer.write(token);
            onToken(token);
          }
        });
      }

      debugPrint('FllamaLLMService: Starting completion...');

      // Start completion
      final result = await fllama.completion(
        _contextId!,
        prompt: formattedPrompt,
        temperature: temperature,
        topP: topP,
        nPredict: maxTokens,
        penaltyRepeat: 1.1,
        stop: ['<|end|>', '<|user|>', '<|endoftext|>'],
        emitRealtimeCompletion: onToken != null,
      );

      debugPrint('FllamaLLMService: Completion result: $result');

      // Cancel token subscription
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;

      stopwatch.stop();

      // Get response from result or buffer
      String responseText;
      if (onToken != null && responseBuffer.isNotEmpty) {
        responseText = responseBuffer.toString();
      } else {
        responseText = result?['text'] as String? ?? '';
      }

      debugPrint('FllamaLLMService: Response text length: ${responseText.length}');

      if (_isCancelled) {
        return LLMResponse(
          content: responseText,
          generationTime: stopwatch.elapsed,
          status: LLMResponseStatus.cancelled,
        );
      }

      if (responseText.isEmpty) {
        return LLMResponse.error('Model returned empty response');
      }

      return LLMResponse(
        content: _cleanResponse(responseText),
        promptTokens: _estimateTokens(formattedPrompt),
        completionTokens: _estimateTokens(responseText),
        generationTime: stopwatch.elapsed,
        wasStreamed: onToken != null,
      );
    } catch (e) {
      debugPrint('FllamaLLMService: Error during generation: $e');
      stopwatch.stop();
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      return LLMResponse.error('Generation failed: $e');
    }
  }

  /// Build ChatML format prompt for Phi-3 (fallback)
  String _buildChatMLPrompt(List<LLMMessage> messages, String systemPrompt) {
    final buffer = StringBuffer();

    // Add system prompt
    buffer.writeln('<|system|>');
    buffer.writeln(systemPrompt);
    buffer.writeln('<|end|>');

    // Add conversation messages
    for (final message in messages) {
      if (message.role == 'user') {
        buffer.writeln('<|user|>');
        buffer.writeln(message.content);
        buffer.writeln('<|end|>');
      } else if (message.role == 'assistant') {
        buffer.writeln('<|assistant|>');
        buffer.writeln(message.content);
        buffer.writeln('<|end|>');
      }
    }

    // Add assistant prompt to start generation
    buffer.writeln('<|assistant|>');

    return buffer.toString();
  }

  /// Clean up the response (remove special tokens if present)
  String _cleanResponse(String response) {
    return response
        .replaceAll('<|end|>', '')
        .replaceAll('<|assistant|>', '')
        .replaceAll('<|user|>', '')
        .replaceAll('<|system|>', '')
        .replaceAll('<|endoftext|>', '')
        .trim();
  }

  @override
  Future<void> cancelGeneration() async {
    _isCancelled = true;
    if (_contextId != null) {
      try {
        final fllama = Fllama.instance();
        await fllama?.stopCompletion(contextId: _contextId!);
      } catch (_) {
        // Ignore errors during cancellation
      }
    }
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  @override
  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    await unloadModel();
    _isReady = false;
    _modelPath = null;
  }

  int _estimateTokens(String text) => (text.length / 4).round();
}
