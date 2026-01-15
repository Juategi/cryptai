import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/storage_keys.dart';

/// Service for securely storing sensitive data like encryption keys
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Store the database encryption key
  Future<void> storeDatabaseKey(String key) async {
    await _storage.write(
      key: StorageKeys.databaseEncryptionKey,
      value: key,
    );
  }

  /// Retrieve the database encryption key
  Future<String?> getDatabaseKey() async {
    return await _storage.read(key: StorageKeys.databaseEncryptionKey);
  }

  /// Check if encryption key exists (app has been set up)
  Future<bool> hasEncryptionKey() async {
    final key = await getDatabaseKey();
    return key != null && key.isNotEmpty;
  }

  /// Mark app as initialized
  Future<void> setAppInitialized() async {
    await _storage.write(
      key: StorageKeys.appInitialized,
      value: 'true',
    );
  }

  /// Check if app has been initialized
  Future<bool> isAppInitialized() async {
    final value = await _storage.read(key: StorageKeys.appInitialized);
    return value == 'true';
  }

  /// Clear all secure storage (for complete reset)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
