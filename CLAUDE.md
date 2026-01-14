# CryptAI - Private Offline Chatbot

## Project Overview

CryptAI is a privacy-focused, 100% offline AI chatbot application for iOS and Android built with Flutter. All conversations are encrypted and stored locally on the device.

## Key Features

- **100% Offline**: No internet connection required
- **Encrypted Storage**: All conversations encrypted with AES-256 (SQLCipher)
- **Local LLM**: Prepared interface for local model integration (placeholder mock service included)
- **Private by Design**: No data ever leaves the device

## Architecture

### Tech Stack
- **Framework**: Flutter 3.9+
- **State Management**: Riverpod
- **Database**: Drift with SQLCipher encryption
- **Navigation**: GoRouter
- **Secure Storage**: flutter_secure_storage

### Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp configuration
├── bootstrap.dart               # App initialization
│
├── core/                        # Core utilities
│   ├── constants/               # App constants
│   │   ├── app_constants.dart
│   │   └── storage_keys.dart
│   └── theme/                   # Theme configuration
│       ├── app_colors.dart
│       └── app_theme.dart
│
├── data/                        # Data layer
│   ├── database/                # Drift database
│   │   ├── app_database.dart    # Main database class
│   │   └── tables/              # Table definitions
│   ├── models/                  # Data models
│   │   ├── conversation_model.dart
│   │   ├── message_model.dart
│   │   └── app_settings_model.dart
│   └── repositories/            # Repository pattern
│       ├── conversation_repository.dart
│       ├── message_repository.dart
│       └── settings_repository.dart
│
├── domain/                      # Domain layer
│   └── enums/
│       ├── message_role.dart
│       └── message_status.dart
│
├── services/                    # Services layer
│   ├── encryption/
│   │   └── encryption_service.dart
│   ├── storage/
│   │   └── secure_storage_service.dart
│   └── llm/                     # LLM service
│       ├── llm_service.dart     # Abstract interface
│       ├── llm_response.dart    # Response model
│       └── mock_llm_service.dart # Mock implementation
│
├── providers/                   # Riverpod providers
│   ├── database_provider.dart
│   ├── conversation_provider.dart
│   ├── chat_provider.dart
│   ├── settings_provider.dart
│   └── llm_provider.dart
│
└── presentation/                # UI layer
    ├── router/
    │   └── app_router.dart
    ├── widgets/
    │   ├── chat/                # Chat-specific widgets
    │   │   ├── message_bubble.dart
    │   │   ├── chat_input_field.dart
    │   │   ├── typing_indicator.dart
    │   │   └── message_list.dart
    │   └── common/              # Shared widgets
    └── screens/
        ├── onboarding/
        │   └── encryption_setup_screen.dart
        ├── chat_list/
        │   └── chat_list_screen.dart
        ├── chat/
        │   └── chat_screen.dart
        └── settings/
            └── settings_screen.dart
```

## Getting Started

### Prerequisites
- Flutter SDK 3.9+
- Dart 3.0+
- Android Studio / Xcode for device deployment

### Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Generate Drift database code:
```bash
dart run build_runner build --delete-conflicting-outputs
```

3. Run the app:
```bash
flutter run
```

## Key Files to Know

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point with provider initialization |
| `lib/data/database/app_database.dart` | Encrypted database setup |
| `lib/services/llm/llm_service.dart` | Abstract LLM interface |
| `lib/services/llm/mock_llm_service.dart` | Mock LLM for testing |
| `lib/providers/chat_provider.dart` | Chat state management |

## LLM Integration

The app is designed with an abstract `LLMService` interface ready for real LLM integration.

### Current: Mock Service
The `MockLLMService` provides placeholder responses for development and testing.

### Future: Local LLM
To integrate a real local LLM (e.g., using fllama):

1. Create a new implementation of `LLMService`
2. Update `llm_provider.dart` to use the new service
3. Handle model loading/downloading UI

Example implementation skeleton:
```dart
class FllamaLLMService implements LLMService {
  // Implement all methods from LLMService
  // Use fllama package for inference
}
```

### Recommended Models for Mobile
- **Phi-2** (2.7B) - ~3GB RAM
- **TinyLlama** (1.1B) - ~1.5GB RAM
- **Gemma 2B** - ~2.5GB RAM

## Database Schema

### Conversations Table
- `id` (TEXT, PK)
- `title` (TEXT)
- `createdAt` (DATETIME)
- `updatedAt` (DATETIME)
- `lastMessagePreview` (TEXT, nullable)
- `messageCount` (INTEGER)
- `systemPrompt` (TEXT, nullable)

### Messages Table
- `id` (TEXT, PK)
- `conversationId` (TEXT, FK)
- `content` (TEXT)
- `role` (TEXT: user/assistant/system)
- `createdAt` (DATETIME)
- `status` (TEXT: pending/sending/sent/error)
- `tokenCount` (INTEGER, nullable)
- `generationTimeMs` (INTEGER, nullable)

## Security Notes

- Database encryption key is stored in platform secure storage
- SQLCipher uses AES-256 encryption
- Optional passphrase can derive encryption key via PBKDF2
- All data remains on-device

## Common Tasks

### Add new screen
1. Create screen file in `lib/presentation/screens/`
2. Add route in `lib/presentation/router/app_router.dart`

### Add new provider
1. Create provider in `lib/providers/`
2. Import in necessary screens

### Modify database schema
1. Update table definition in `lib/data/database/tables/`
2. Increment schema version in `app_database.dart`
3. Add migration logic
4. Regenerate code: `dart run build_runner build`

## Troubleshooting

### Build errors after database changes
```bash
dart run build_runner build --delete-conflicting-outputs
```

### iOS SQLCipher issues
Ensure `sqlcipher_flutter_libs` is properly configured in `ios/Podfile`.

### Android encryption issues
Check that `minSdkVersion` is at least 21 in `android/app/build.gradle`.

## Future Enhancements

- [ ] Integrate real local LLM (fllama)
- [ ] Add biometric authentication
- [ ] Export/import conversations
- [ ] Voice input/output
- [ ] Model download management UI
- [ ] Multiple language support
