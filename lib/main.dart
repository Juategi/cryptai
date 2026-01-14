import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'bootstrap.dart';
import 'providers/database_provider.dart';
import 'providers/llm_provider.dart';

void main() async {
  // Initialize app
  await bootstrap();

  // Check if app has been initialized (encryption set up)
  final isInitialized = await isAppInitialized();

  // If initialized, set up database and services
  List<Override> overrides = [];

  if (isInitialized) {
    final dbKey = await getDatabaseKey();
    if (dbKey != null) {
      // Create encrypted database
      final database = await createDatabase(dbKey);
      overrides.add(databaseProvider.overrideWithValue(database));

      // Create LLM service
      final llmService = await createLLMService();
      overrides.add(llmServiceProvider.overrideWithValue(llmService));
    }
  }

  runApp(
    ProviderScope(
      overrides: overrides,
      child: CryptAIApp(isInitialized: isInitialized),
    ),
  );
}
