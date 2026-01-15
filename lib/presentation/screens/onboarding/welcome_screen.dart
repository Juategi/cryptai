import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Welcome screen shown on every app launch
class WelcomeScreen extends StatefulWidget {
  final bool needsSetup;

  const WelcomeScreen({super.key, required this.needsSetup});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Logo
              Center(
                child: Image.asset('assets/logo.png', width: 120, height: 120),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Welcome to CryptAI',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blueDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your private, offline AI assistant',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.blueDeep,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Privacy features
              _buildFeatureCard(
                icon: Icons.wifi_off_rounded,
                title: '100% Offline',
                description: 'No internet required. All processing on-device.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.security_rounded,
                title: 'Encrypted Storage',
                description: 'All conversations encrypted with AES-256.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.visibility_off_rounded,
                title: 'Complete Privacy',
                description: 'Your data never leaves your device.',
              ),
              const SizedBox(height: 48),
              // Continue button
              FilledButton(
                onPressed: _continue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(widget.needsSetup ? 'Get Started' : 'Continue'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your data stays on this device only.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() {
    if (widget.needsSetup) {
      context.go('/setup');
    } else {
      context.go('/chat');
    }
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.turquoise.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.turquoise, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.blueDark,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.blueDeep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
