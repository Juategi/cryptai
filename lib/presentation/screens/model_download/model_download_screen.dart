import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/model_download_provider.dart';

/// Screen for downloading the AI model
class ModelDownloadScreen extends ConsumerWidget {
  const ModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(modelDownloadProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(downloadState.status),
                  size: 60,
                  color: isDark ? AppColors.blueLight : AppColors.turquoise,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                _getTitle(downloadState.status),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _getDescription(downloadState.status),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              // Progress indicator or button
              if (downloadState.status == ModelDownloadStatus.downloading) ...[
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: downloadState.progress,
                          minHeight: 12,
                          backgroundColor: isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.turquoise,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        downloadState.statusMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(downloadState.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (downloadState.status ==
                  ModelDownloadStatus.checking) ...[
                CircularProgressIndicator(color: AppColors.turquoise),
              ] else if (downloadState.status == ModelDownloadStatus.error) ...[
                // Error message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    downloadState.error ?? 'Unknown error',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Retry button
                _buildButton(
                  context: context,
                  label: 'Retry Download',
                  icon: Icons.refresh,
                  onPressed: () {
                    ref.read(modelDownloadProvider.notifier).startDownload();
                  },
                  isDark: isDark,
                ),
              ] else if (downloadState.status ==
                  ModelDownloadStatus.notDownloaded) ...[
                // Download info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Download size: ~640 MB',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Download button
                _buildButton(
                  context: context,
                  label: 'Download AI Model',
                  icon: Icons.download,
                  onPressed: () {
                    ref.read(modelDownloadProvider.notifier).startDownload();
                  },
                  isDark: isDark,
                ),
              ] else if (downloadState.status ==
                  ModelDownloadStatus.downloaded) ...[
                // Success message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        downloadState.statusMessage,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Continue button
                _buildButton(
                  context: context,
                  label: 'Continue to Chat',
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    context.go('/');
                  },
                  isDark: isDark,
                ),
              ],
              const Spacer(),
              // WiFi recommendation
              if (downloadState.status == ModelDownloadStatus.notDownloaded ||
                  downloadState.status == ModelDownloadStatus.downloading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'WiFi recommended for download',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(ModelDownloadStatus status) {
    switch (status) {
      case ModelDownloadStatus.checking:
        return Icons.search;
      case ModelDownloadStatus.notDownloaded:
        return Icons.cloud_download;
      case ModelDownloadStatus.downloading:
        return Icons.downloading;
      case ModelDownloadStatus.downloaded:
        return Icons.check_circle;
      case ModelDownloadStatus.error:
        return Icons.error_outline;
    }
  }

  String _getTitle(ModelDownloadStatus status) {
    switch (status) {
      case ModelDownloadStatus.checking:
        return 'Checking AI Model';
      case ModelDownloadStatus.notDownloaded:
        return 'Download AI Model';
      case ModelDownloadStatus.downloading:
        return 'Downloading...';
      case ModelDownloadStatus.downloaded:
        return 'Ready to Chat!';
      case ModelDownloadStatus.error:
        return 'Download Failed';
    }
  }

  String _getDescription(ModelDownloadStatus status) {
    switch (status) {
      case ModelDownloadStatus.checking:
        return 'Please wait while we check if the AI model is available...';
      case ModelDownloadStatus.notDownloaded:
        return 'To use CryptAI offline, you need to download the AI model. This is a one-time download.';
      case ModelDownloadStatus.downloading:
        return 'Please keep the app open. You can use WiFi to avoid mobile data charges.';
      case ModelDownloadStatus.downloaded:
        return 'The AI model is ready. All your conversations will be private and processed locally.';
      case ModelDownloadStatus.error:
        return 'There was a problem downloading the model. Please check your connection and try again.';
    }
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
