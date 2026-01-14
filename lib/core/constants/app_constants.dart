/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'CryptAI';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'cryptai.db';
  static const int databaseVersion = 1;

  // LLM defaults
  static const int defaultMaxTokens = 2048;
  static const double defaultTemperature = 0.7;
  static const double defaultTopP = 0.9;

  // Security
  static const int autoLockTimeoutSeconds = 300; // 5 minutes
  static const int pbkdf2Iterations = 100000;
  static const int encryptionKeyLength = 32; // 256 bits
  static const int saltLength = 16;

  // UI
  static const double defaultFontSize = 16.0;
  static const int messagePreviewLength = 100;
}
