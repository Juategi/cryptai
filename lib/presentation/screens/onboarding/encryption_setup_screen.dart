import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../../services/encryption/encryption_service.dart';
import '../../../services/storage/secure_storage_service.dart';

/// Initial setup screen for configuring encryption
class EncryptionSetupScreen extends ConsumerStatefulWidget {
  const EncryptionSetupScreen({super.key});

  @override
  ConsumerState<EncryptionSetupScreen> createState() =>
      _EncryptionSetupScreenState();
}

class _EncryptionSetupScreenState extends ConsumerState<EncryptionSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _usePassphrase = false;
  bool _isLoading = false;
  bool _obscurePassphrase = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _setupEncryption() async {
    if (_usePassphrase && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final encryptionService = EncryptionService();
      final secureStorage = SecureStorageService();

      String databaseKey;

      if (_usePassphrase && _passphraseController.text.isNotEmpty) {
        // Derive key from passphrase
        final salt = encryptionService.generateSalt();
        databaseKey = encryptionService.deriveKeyFromPassphrase(
          _passphraseController.text,
          salt,
        );
        await secureStorage.storePassphraseSalt(salt);
      } else {
        // Generate random key (device-protected only)
        databaseKey = encryptionService.generateKey();
      }

      await secureStorage.storeDatabaseKey(databaseKey);
      await secureStorage.setAppInitialized();

      if (mounted) {
        // Restart app to reinitialize with database
        RestartWidget.restartApp(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up encryption: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                child: Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                ),
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
              const SizedBox(height: 32),
              // Passphrase option
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: _usePassphrase,
                            onChanged: (value) {
                              setState(() => _usePassphrase = value);
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Use custom passphrase',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (_usePassphrase) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Your passphrase adds extra protection. You\'ll need it if you reinstall the app.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _passphraseController,
                                obscureText: _obscurePassphrase,
                                decoration: InputDecoration(
                                  labelText: 'Passphrase',
                                  prefixIcon: const Icon(Icons.key_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassphrase
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded),
                                    onPressed: () {
                                      setState(() => _obscurePassphrase =
                                          !_obscurePassphrase);
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 8) {
                                    return 'Passphrase must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscureConfirm,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Passphrase',
                                  prefixIcon:
                                      const Icon(Icons.key_off_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirm
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded),
                                    onPressed: () {
                                      setState(() =>
                                          _obscureConfirm = !_obscureConfirm);
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value != _passphraseController.text) {
                                    return 'Passphrases do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Encryption will use device-protected storage. Recommended for most users.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Continue button
              FilledButton(
                onPressed: _isLoading ? null : _setupEncryption,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By continuing, you agree to keep your data on this device only.',
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
          child: Icon(
            icon,
            color: AppColors.turquoise,
            size: 24,
          ),
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
