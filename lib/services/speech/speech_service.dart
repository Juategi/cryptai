/// Abstract interface for speech-to-text services.
/// This allows easy swapping between different speech recognition implementations.
abstract class SpeechService {
  /// Initialize the service and check for availability
  Future<bool> initialize();

  /// Check if speech recognition is available on this device
  bool get isAvailable;

  /// Check if currently listening for speech
  bool get isListening;

  /// Check if microphone permission has been granted
  bool get hasPermission;

  /// Start listening for speech input
  /// [onResult] - Callback with transcribed text and whether it's final
  /// [onSoundLevel] - Optional callback for sound level changes (for UI feedback)
  /// [localeId] - Optional locale for speech recognition (e.g., 'en_US', 'es_ES')
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(double level)? onSoundLevel,
    String? localeId,
  });

  /// Stop listening and finalize any pending results
  Future<void> stopListening();

  /// Cancel listening without finalizing results
  Future<void> cancelListening();

  /// Get list of available locales for speech recognition
  Future<List<SpeechLocale>> getAvailableLocales();

  /// Dispose resources
  Future<void> dispose();
}

/// Represents a locale available for speech recognition
class SpeechLocale {
  final String localeId;
  final String name;

  const SpeechLocale({
    required this.localeId,
    required this.name,
  });

  @override
  String toString() => '$name ($localeId)';
}
