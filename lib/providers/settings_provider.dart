import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_settings_model.dart';
import '../data/repositories/settings_repository.dart';
import 'database_provider.dart';

/// Provider for settings repository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(db);
});

/// Provider for app settings
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsModel>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});

/// Notifier for managing app settings
class SettingsNotifier extends StateNotifier<AppSettingsModel> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(const AppSettingsModel()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await _repo.getSettings();
  }

  Future<void> updateSelectedModel(String modelId) async {
    state = state.copyWith(selectedModelId: modelId);
    await _repo.saveSettings(state);
  }

  Future<void> updateMaxTokens(int maxTokens) async {
    state = state.copyWith(maxTokens: maxTokens);
    await _repo.saveSettings(state);
  }

  Future<void> updateTemperature(double temperature) async {
    state = state.copyWith(temperature: temperature);
    await _repo.saveSettings(state);
  }

  Future<void> updateTopP(double topP) async {
    state = state.copyWith(topP: topP);
    await _repo.saveSettings(state);
  }

  Future<void> updateCustomSystemPrompt(String? prompt) async {
    state = state.copyWith(customSystemPrompt: prompt);
    await _repo.saveSettings(state);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repo.saveSettings(state);
  }

  Future<void> updateFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _repo.saveSettings(state);
  }

  Future<void> updateShowTimestamps(bool show) async {
    state = state.copyWith(showTimestamps: show);
    await _repo.saveSettings(state);
  }

  Future<void> resetToDefaults() async {
    await _repo.resetSettings();
    state = const AppSettingsModel();
  }
}
