import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'bootstrap.dart';
import 'providers/database_provider.dart';
import 'providers/llm_provider.dart';

void main() async {
  // Initialize app
  await bootstrap();

  runApp(const RestartWidget(child: CryptAILoader()));
}

/// Widget that allows restarting the app
class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

/// Loader widget that initializes providers and shows the app
class CryptAILoader extends StatefulWidget {
  const CryptAILoader({super.key});

  @override
  State<CryptAILoader> createState() => _CryptAILoaderState();
}

class _CryptAILoaderState extends State<CryptAILoader> {
  bool _isLoading = true;
  bool _isInitialized = false;
  List<Override> _overrides = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
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

    if (mounted) {
      setState(() {
        _isInitialized = isInitialized;
        _overrides = overrides;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 120, height: 120),
              ],
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: _overrides,
      child: CryptAIApp(isInitialized: _isInitialized),
    );
  }
}
