import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';
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

  /// Derive a key from a user passphrase using PBKDF2
  String deriveKeyFromPassphrase(String passphrase, String salt) {
    final saltBytes = base64Url.decode(salt);
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(
      Uint8List.fromList(saltBytes),
      AppConstants.pbkdf2Iterations,
      AppConstants.encryptionKeyLength,
    ));

    final key = pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
    return base64Url.encode(key);
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

  /// Generate a secure random salt
  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      AppConstants.saltLength,
      (_) => random.nextInt(256),
    );
    return base64Url.encode(bytes);
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
