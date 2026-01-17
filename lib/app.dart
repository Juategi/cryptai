import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'providers/settings_provider.dart';

/// Main application widget
class CryptAIApp extends ConsumerWidget {
  final bool isInitialized;
  final bool isModelDownloaded;

  const CryptAIApp({
    super.key,
    required this.isInitialized,
    required this.isModelDownloaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter(
      isInitialized: isInitialized,
      isModelDownloaded: isModelDownloaded,
    ).router;

    // Only access settings when database is initialized
    final themeMode = isInitialized
        ? ref.watch(settingsProvider).themeMode
        : ThemeMode.system;

    return MaterialApp.router(
      title: 'CryptAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
