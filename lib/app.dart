import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'providers/settings_provider.dart';

/// Main application widget
class CryptAIApp extends ConsumerWidget {
  final bool isInitialized;

  const CryptAIApp({super.key, required this.isInitialized});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = AppRouter(isInitialized: isInitialized).router;

    return MaterialApp.router(
      title: 'CryptAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
