import 'dart:convert';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/app_settings_model.dart';

/// Repository for managing app settings
class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  static const String _settingsKey = 'app_settings';

  /// Get current settings
  Future<AppSettingsModel> getSettings() async {
    final json = await _db.getSetting(_settingsKey);
    if (json == null) {
      return const AppSettingsModel();
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppSettingsModel(
        selectedModelId: map['selectedModelId'] as String? ?? 'mock',
        maxTokens: map['maxTokens'] as int? ?? 2048,
        temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
        topP: (map['topP'] as num?)?.toDouble() ?? 0.9,
        customSystemPrompt: map['customSystemPrompt'] as String?,
        themeMode: _parseThemeMode(map['themeMode'] as String?),
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 16.0,
        showTimestamps: map['showTimestamps'] as bool? ?? true,
      );
    } catch (_) {
      return const AppSettingsModel();
    }
  }

  /// Save settings
  Future<void> saveSettings(AppSettingsModel settings) async {
    final map = {
      'selectedModelId': settings.selectedModelId,
      'maxTokens': settings.maxTokens,
      'temperature': settings.temperature,
      'topP': settings.topP,
      'customSystemPrompt': settings.customSystemPrompt,
      'themeMode': settings.themeMode.name,
      'fontSize': settings.fontSize,
      'showTimestamps': settings.showTimestamps,
    };
    await _db.setSetting(_settingsKey, jsonEncode(map));
  }

  /// Update a single setting
  Future<void> updateSetting<T>(String key, T value) async {
    final settings = await getSettings();
    AppSettingsModel updated;

    switch (key) {
      case 'selectedModelId':
        updated = settings.copyWith(selectedModelId: value as String);
        break;
      case 'maxTokens':
        updated = settings.copyWith(maxTokens: value as int);
        break;
      case 'temperature':
        updated = settings.copyWith(temperature: value as double);
        break;
      case 'topP':
        updated = settings.copyWith(topP: value as double);
        break;
      case 'customSystemPrompt':
        updated = settings.copyWith(customSystemPrompt: value as String?);
        break;
      case 'themeMode':
        updated = settings.copyWith(themeMode: value as ThemeMode);
        break;
      case 'fontSize':
        updated = settings.copyWith(fontSize: value as double);
        break;
      case 'showTimestamps':
        updated = settings.copyWith(showTimestamps: value as bool);
        break;
      default:
        return;
    }

    await saveSettings(updated);
  }

  /// Reset settings to defaults
  Future<void> resetSettings() async {
    await _db.deleteSetting(_settingsKey);
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
