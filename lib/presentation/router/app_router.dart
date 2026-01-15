import 'package:go_router/go_router.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/encryption_setup_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Application router configuration
class AppRouter {
  final bool isInitialized;

  AppRouter({required this.isInitialized});

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => WelcomeScreen(needsSetup: !isInitialized),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const EncryptionSetupScreen(),
      ),
      GoRoute(
        path: '/chat',
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
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
