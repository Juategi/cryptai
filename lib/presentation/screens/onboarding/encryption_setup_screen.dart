import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../../services/encryption/encryption_service.dart';
import '../../../services/storage/secure_storage_service.dart';

/// Setup screen that initializes encryption
class EncryptionSetupScreen extends ConsumerStatefulWidget {
  const EncryptionSetupScreen({super.key});

  @override
  ConsumerState<EncryptionSetupScreen> createState() =>
      _EncryptionSetupScreenState();
}

class _EncryptionSetupScreenState extends ConsumerState<EncryptionSetupScreen> {
  String _status = 'Setting up encryption...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupEncryption();
  }

  Future<void> _setupEncryption() async {
    try {
      setState(() => _status = 'Generating encryption key...');

      final encryptionService = EncryptionService();
      final secureStorage = SecureStorageService();

      // Generate random key (device-protected)
      final databaseKey = encryptionService.generateKey();

      setState(() => _status = 'Securing your data...');

      await secureStorage.storeDatabaseKey(databaseKey);
      await secureStorage.setAppInitialized();

      setState(() => _status = 'Ready!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Restart app to reinitialize with database
        RestartWidget.restartApp(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 100, height: 100),
              const SizedBox(height: 32),
              if (!_hasError) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
              ],
              Text(
                _status,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _hasError ? AppColors.error : AppColors.blueDeep,
                ),
                textAlign: TextAlign.center,
              ),
              if (_hasError) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _status = 'Setting up encryption...';
                    });
                    _setupEncryption();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
