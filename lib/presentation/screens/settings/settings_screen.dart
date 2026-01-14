import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/llm_provider.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentModel = ref.watch(currentModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // AI Model Section
          _SectionHeader(title: 'AI Model'),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Current Model'),
            subtitle: Text(currentModel?.name ?? 'Mock Fast'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showModelSelection(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Max Tokens'),
            subtitle: Text('${settings.maxTokens}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMaxTokensDialog(context, ref, settings.maxTokens),
          ),
          ListTile(
            leading: const Icon(Icons.thermostat_outlined),
            title: const Text('Temperature'),
            subtitle: Text('${settings.temperature.toStringAsFixed(1)} (${_temperatureLabel(settings.temperature)})'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTemperatureDialog(context, ref, settings.temperature),
          ),
          const Divider(),

          // Appearance Section
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, settings.themeMode),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.access_time_outlined),
            title: const Text('Show Timestamps'),
            subtitle: const Text('Display time on each message'),
            value: settings.showTimestamps,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTimestamps(value);
            },
          ),
          const Divider(),

          // Privacy Section
          _SectionHeader(title: 'Privacy & Security'),
          ListTile(
            leading: Icon(Icons.lock_outline, color: AppColors.success),
            title: const Text('Encryption Status'),
            subtitle: const Text('AES-256 encryption active'),
            trailing: Icon(Icons.check_circle, color: AppColors.success),
          ),
          ListTile(
            leading: Icon(Icons.wifi_off_outlined, color: AppColors.success),
            title: const Text('Offline Mode'),
            subtitle: const Text('All data stays on device'),
            trailing: Icon(Icons.check_circle, color: AppColors.success),
          ),
          const Divider(),

          // Data Section
          _SectionHeader(title: 'Data Management'),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all conversations and settings'),
            onTap: () => _showClearDataDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: const Text('Reset Settings'),
            subtitle: const Text('Restore default settings'),
            onTap: () => _showResetSettingsDialog(context, ref),
          ),
          const Divider(),

          // About Section
          _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Your data never leaves your device'),
            onTap: () => _showPrivacyInfo(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _temperatureLabel(double temp) {
    if (temp < 0.3) return 'Focused';
    if (temp < 0.7) return 'Balanced';
    return 'Creative';
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _showModelSelection(BuildContext context, WidgetRef ref) async {
    final modelsAsync = ref.read(availableModelsProvider);
    final models = modelsAsync.valueOrNull ?? [];

    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Model',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...models.map((model) => ListTile(
                  leading: Icon(
                    model.isDownloaded
                        ? Icons.check_circle
                        : Icons.download_outlined,
                    color: model.isDownloaded ? AppColors.success : null,
                  ),
                  title: Text(model.name),
                  subtitle: Text(model.description ?? ''),
                  enabled: model.isDownloaded,
                  onTap: model.isDownloaded
                      ? () {
                          ref
                              .read(settingsProvider.notifier)
                              .updateSelectedModel(model.id);
                          Navigator.pop(context);
                        }
                      : null,
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showMaxTokensDialog(
    BuildContext context,
    WidgetRef ref,
    int currentValue,
  ) async {
    double value = currentValue.toDouble();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Max Tokens'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Maximum number of tokens in AI response',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text(
                '${value.round()}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Slider(
                value: value,
                min: 256,
                max: 4096,
                divisions: 15,
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .updateMaxTokens(value.round());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTemperatureDialog(
    BuildContext context,
    WidgetRef ref,
    double currentValue,
  ) async {
    double value = currentValue;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Temperature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Higher values = more creative, lower = more focused',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text(
                value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                _temperatureLabel(value),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).updateTemperature(value);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_themeModeLabel(mode)),
              value: mode,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showClearDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all conversations, messages, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been cleared'),
        ),
      );
    }
  }

  Future<void> _showResetSettingsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will restore all settings to their default values. Your conversations will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings have been reset'),
          ),
        );
      }
    }
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CryptAI is designed with privacy as the top priority:'),
            SizedBox(height: 16),
            _PrivacyItem(
              icon: Icons.wifi_off,
              text: '100% offline - no internet required',
            ),
            _PrivacyItem(
              icon: Icons.lock,
              text: 'AES-256 encrypted storage',
            ),
            _PrivacyItem(
              icon: Icons.phone_android,
              text: 'All data stays on your device',
            ),
            _PrivacyItem(
              icon: Icons.visibility_off,
              text: 'No analytics or tracking',
            ),
            _PrivacyItem(
              icon: Icons.cloud_off,
              text: 'No cloud sync or backups',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrivacyItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
