import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/speech/speech_service.dart';
import '../services/speech/native_speech_service.dart';

/// Provider for the speech-to-text service
final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = NativeSpeechService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for speech service initialization state
final speechInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(speechServiceProvider);
  return service.initialize();
});

/// Provider for checking if speech recognition is available
final speechAvailableProvider = Provider<bool>((ref) {
  final service = ref.watch(speechServiceProvider);
  return service.isAvailable;
});

/// Provider for checking if currently listening
final speechListeningProvider = Provider<bool>((ref) {
  final service = ref.watch(speechServiceProvider);
  return service.isListening;
});

/// Provider for available speech locales
final speechLocalesProvider = FutureProvider<List<SpeechLocale>>((ref) async {
  final service = ref.watch(speechServiceProvider);
  final initialized = await ref.watch(speechInitializedProvider.future);
  if (!initialized) return [];
  return service.getAvailableLocales();
});
