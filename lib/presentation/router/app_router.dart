import 'package:go_router/go_router.dart';
import '../screens/onboarding/encryption_setup_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/model_download/model_download_screen.dart';

/// Application router configuration
class AppRouter {
  final bool isInitialized;
  final bool isModelDownloaded;

  AppRouter({
    required this.isInitialized,
    required this.isModelDownloaded,
  });

  late final GoRouter router = GoRouter(
    initialLocation: _getInitialLocation(),
    routes: [
      GoRoute(
        path: '/',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat_with_id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const EncryptionSetupScreen(),
      ),
      GoRoute(
        path: '/download-model',
        name: 'download_model',
        builder: (context, state) => const ModelDownloadScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  String _getInitialLocation() {
    if (!isInitialized) {
      return '/setup';
    }
    if (!isModelDownloaded) {
      return '/download-model';
    }
    return '/';
  }
}
