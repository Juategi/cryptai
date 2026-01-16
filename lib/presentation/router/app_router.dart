import 'package:go_router/go_router.dart';
import '../screens/onboarding/encryption_setup_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Application router configuration
class AppRouter {
  final bool isInitialized;

  AppRouter({required this.isInitialized});

  late final GoRouter router = GoRouter(
    initialLocation: isInitialized ? '/' : '/setup',
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
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
