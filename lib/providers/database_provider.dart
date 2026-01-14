import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../services/storage/secure_storage_service.dart';

/// Provider for secure storage service
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for the encrypted database
/// Must be initialized after encryption key is set up
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'Database provider must be overridden with an initialized database',
  );
});

/// Creates an initialized database with the encryption key
Future<AppDatabase> createDatabase(String encryptionKey) async {
  final db = AppDatabase(AppDatabase.createEncrypted(encryptionKey));
  return db;
}
