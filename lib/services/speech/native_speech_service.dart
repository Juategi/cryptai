import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'speech_service.dart';

/// Native speech-to-text implementation using the device's speech recognition engine.
/// Works offline if the user has downloaded language packs on their device.
class NativeSpeechService implements SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isAvailable = false;
  bool _isListening = false;
  bool _hasPermission = false;

  void Function(String text, bool isFinal)? _onResult;
  void Function(double level)? _onSoundLevel;

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _isListening;

  @override
  bool get hasPermission => _hasPermission;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;

    _isAvailable = await _speech.initialize(
      onStatus: _handleStatus,
      onError: _handleError,
    );

    _hasPermission = _isAvailable;
    _isInitialized = true;

    return _isAvailable;
  }

  void _handleStatus(String status) {
    _isListening = status == 'listening';
  }

  void _handleError(dynamic error) {
    _isListening = false;
    // Errors are handled via the result callback returning empty/final
  }

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(double level)? onSoundLevel,
    String? localeId,
  }) async {
    if (!_isAvailable) {
      await initialize();
      if (!_isAvailable) return;
    }

    _onResult = onResult;
    _onSoundLevel = onSoundLevel;
    _isListening = true;

    await _speech.listen(
      onResult: _handleResult,
      onSoundLevelChange: _handleSoundLevel,
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        autoPunctuation: true,
      ),
      pauseFor: const Duration(seconds: 2),
      listenFor: const Duration(seconds: 30),
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    _onResult?.call(
      result.recognizedWords,
      result.finalResult,
    );

    if (result.finalResult) {
      _isListening = false;
    }
  }

  void _handleSoundLevel(double level) {
    _onSoundLevel?.call(level);
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  @override
  Future<void> cancelListening() async {
    if (!_isListening) return;
    await _speech.cancel();
    _isListening = false;
    _onResult = null;
    _onSoundLevel = null;
  }

  @override
  Future<List<SpeechLocale>> getAvailableLocales() async {
    if (!_isAvailable) return [];

    final locales = await _speech.locales();
    return locales
        .map((l) => SpeechLocale(
              localeId: l.localeId,
              name: l.name,
            ))
        .toList();
  }

  @override
  Future<void> dispose() async {
    await cancelListening();
    _isInitialized = false;
    _isAvailable = false;
  }
}
