import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/model/model_download_service.dart';

/// Model download state
enum ModelDownloadStatus {
  checking,
  notDownloaded,
  downloading,
  downloaded,
  error,
}

/// State class for model download
class ModelDownloadState {
  final ModelDownloadStatus status;
  final double progress;
  final String statusMessage;
  final String? error;

  const ModelDownloadState({
    this.status = ModelDownloadStatus.checking,
    this.progress = 0.0,
    this.statusMessage = 'Checking model...',
    this.error,
  });

  ModelDownloadState copyWith({
    ModelDownloadStatus? status,
    double? progress,
    String? statusMessage,
    String? error,
  }) {
    return ModelDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      error: error,
    );
  }
}

/// Provider for model download service
final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  return ModelDownloadService();
});

/// Provider for model download state
final modelDownloadProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>((ref) {
  final service = ref.watch(modelDownloadServiceProvider);
  return ModelDownloadNotifier(service);
});

/// Notifier for managing model download state
class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  final ModelDownloadService _service;

  ModelDownloadNotifier(this._service) : super(const ModelDownloadState()) {
    checkModelStatus();
  }

  /// Check if model is already downloaded
  Future<void> checkModelStatus() async {
    state = state.copyWith(
      status: ModelDownloadStatus.checking,
      statusMessage: 'Checking model...',
    );

    final isDownloaded = await _service.isModelDownloaded();

    if (isDownloaded) {
      final sizeMB = await _service.getModelSizeMB();
      state = state.copyWith(
        status: ModelDownloadStatus.downloaded,
        progress: 1.0,
        statusMessage: 'Model ready (${sizeMB.toStringAsFixed(0)} MB)',
      );
    } else {
      state = state.copyWith(
        status: ModelDownloadStatus.notDownloaded,
        progress: 0.0,
        statusMessage: 'Model not downloaded',
      );
    }
  }

  /// Start downloading the model
  Future<bool> startDownload() async {
    if (state.status == ModelDownloadStatus.downloading) {
      return false;
    }

    state = state.copyWith(
      status: ModelDownloadStatus.downloading,
      progress: 0.0,
      statusMessage: 'Starting download...',
      error: null,
    );

    final success = await _service.downloadModel(
      onProgress: (progress, status) {
        state = state.copyWith(
          progress: progress,
          statusMessage: status,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: ModelDownloadStatus.error,
          error: error,
          statusMessage: 'Download failed',
        );
      },
    );

    if (success) {
      final sizeMB = await _service.getModelSizeMB();
      state = state.copyWith(
        status: ModelDownloadStatus.downloaded,
        progress: 1.0,
        statusMessage: 'Model ready (${sizeMB.toStringAsFixed(0)} MB)',
      );
    }

    return success;
  }

  /// Delete the downloaded model
  Future<void> deleteModel() async {
    await _service.deleteModel();
    state = state.copyWith(
      status: ModelDownloadStatus.notDownloaded,
      progress: 0.0,
      statusMessage: 'Model deleted',
    );
  }

  /// Get the model path
  Future<String> getModelPath() async {
    return await _service.getModelPath();
  }
}

/// Provider to check if model is ready
final isModelReadyProvider = Provider<bool>((ref) {
  final downloadState = ref.watch(modelDownloadProvider);
  return downloadState.status == ModelDownloadStatus.downloaded;
});
