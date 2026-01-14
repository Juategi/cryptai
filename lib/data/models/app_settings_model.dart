import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Model representing application settings
class AppSettingsModel extends Equatable {
  final String selectedModelId;
  final int maxTokens;
  final double temperature;
  final double topP;
  final String? customSystemPrompt;
  final ThemeMode themeMode;
  final double fontSize;
  final bool showTimestamps;

  const AppSettingsModel({
    this.selectedModelId = 'mock',
    this.maxTokens = AppConstants.defaultMaxTokens,
    this.temperature = AppConstants.defaultTemperature,
    this.topP = AppConstants.defaultTopP,
    this.customSystemPrompt,
    this.themeMode = ThemeMode.system,
    this.fontSize = AppConstants.defaultFontSize,
    this.showTimestamps = true,
  });

  AppSettingsModel copyWith({
    String? selectedModelId,
    int? maxTokens,
    double? temperature,
    double? topP,
    String? customSystemPrompt,
    ThemeMode? themeMode,
    double? fontSize,
    bool? showTimestamps,
  }) {
    return AppSettingsModel(
      selectedModelId: selectedModelId ?? this.selectedModelId,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      customSystemPrompt: customSystemPrompt ?? this.customSystemPrompt,
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      showTimestamps: showTimestamps ?? this.showTimestamps,
    );
  }

  @override
  List<Object?> get props => [
        selectedModelId,
        maxTokens,
        temperature,
        topP,
        customSystemPrompt,
        themeMode,
        fontSize,
        showTimestamps,
      ];
}
