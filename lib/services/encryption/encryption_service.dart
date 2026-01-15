import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../../core/constants/app_constants.dart';

/// Service for handling encryption and decryption operations
class EncryptionService {
  /// Generate a new secure encryption key
  String generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      AppConstants.encryptionKeyLength,
      (_) => random.nextInt(256),
    );
    return base64Url.encode(bytes);
  }

  /// Encrypt plaintext data using AES-256
  String encryptData(String plaintext, String key) {
    final keyBytes = base64Url.decode(key);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(Uint8List.fromList(keyBytes))),
    );

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    // Prepend IV to ciphertext for later decryption
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt ciphertext data
  String decryptData(String ciphertext, String key) {
    final parts = ciphertext.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid ciphertext format');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    final keyBytes = base64Url.decode(key);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(Uint8List.fromList(keyBytes))),
    );

    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Validate that a key is properly formatted
  bool isValidKey(String key) {
    try {
      final decoded = base64Url.decode(key);
      return decoded.length == AppConstants.encryptionKeyLength;
    } catch (_) {
      return false;
    }
  }
}
