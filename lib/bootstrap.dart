import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/encryption/encryption_service.dart';
import 'services/storage/secure_storage_service.dart';

/// Initialize the app and handle first-run setup
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
}

/// Check if this is first run (no encryption key exists)
Future<bool> isAppInitialized() async {
  final secureStorage = SecureStorageService();
  return await secureStorage.isAppInitialized();
}

/// Get the database encryption key (returns null if not set up)
Future<String?> getDatabaseKey() async {
  final secureStorage = SecureStorageService();
  return await secureStorage.getDatabaseKey();
}

/// Set up encryption for first-time users
Future<void> setupEncryption({String? passphrase}) async {
  final secureStorage = SecureStorageService();
  final encryptionService = EncryptionService();

  String databaseKey;

  if (passphrase != null && passphrase.isNotEmpty) {
    // Derive key from passphrase
    final salt = encryptionService.generateSalt();
    databaseKey = encryptionService.deriveKeyFromPassphrase(
      passphrase,
      salt,
    );
    await secureStorage.storePassphraseSalt(salt);
  } else {
    // Generate random key (device-protected only)
    databaseKey = encryptionService.generateKey();
  }

  await secureStorage.storeDatabaseKey(databaseKey);
  await secureStorage.setAppInitialized();
}
