import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service for downloading and managing the LLM model
class ModelDownloadService {
  static const String modelFileName = 'llama.gguf';

  // TinyLlama 1.1B Chat model from Hugging Face
  static const String modelUrl =
      'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';

  static const int expectedModelSizeBytes = 669000000; // ~638MB approximate

  /// Get the local path where the model should be stored
  Future<String> getModelPath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return p.join(documentsDir.path, modelFileName);
  }

  /// Check if the model is already downloaded
  Future<bool> isModelDownloaded() async {
    final modelPath = await getModelPath();
    final file = File(modelPath);
    if (await file.exists()) {
      final size = await file.length();
      // Consider downloaded if file exists and has reasonable size (> 100MB)
      return size > 100 * 1024 * 1024;
    }
    return false;
  }

  /// Get the current downloaded file size (for resuming)
  Future<int> getDownloadedSize() async {
    final modelPath = await getModelPath();
    final file = File(modelPath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Download the model with progress callback
  /// Returns true if download was successful
  Future<bool> downloadModel({
    required void Function(double progress, String status) onProgress,
    required void Function(String error) onError,
  }) async {
    final modelPath = await getModelPath();
    final tempFile = File('$modelPath.tmp');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      // Check for existing partial download
      int downloadedBytes = 0;
      if (await tempFile.exists()) {
        downloadedBytes = await tempFile.length();
        debugPrint('Resuming download from $downloadedBytes bytes');
      }

      final request = await client.getUrl(Uri.parse(modelUrl));

      // Add range header for resume support
      if (downloadedBytes > 0) {
        request.headers.add('Range', 'bytes=$downloadedBytes-');
      }

      final response = await request.close();

      // Check response status
      if (response.statusCode != 200 && response.statusCode != 206) {
        onError('Download failed: HTTP ${response.statusCode}');
        return false;
      }

      // Get total size
      final contentLength = response.contentLength;
      final totalSize = downloadedBytes + (contentLength > 0 ? contentLength : expectedModelSizeBytes);

      // Open file for writing (append if resuming)
      final sink = tempFile.openWrite(mode: downloadedBytes > 0 ? FileMode.append : FileMode.write);

      int receivedBytes = downloadedBytes;

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final progress = receivedBytes / totalSize;
        final downloadedMB = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
        final totalMB = (totalSize / (1024 * 1024)).toStringAsFixed(0);

        onProgress(progress.clamp(0.0, 1.0), 'Downloading: $downloadedMB MB / $totalMB MB');
      }

      await sink.close();
      client.close();

      // Rename temp file to final name
      onProgress(1.0, 'Finalizing...');
      await tempFile.rename(modelPath);

      debugPrint('Model download complete: $modelPath');
      return true;
    } catch (e) {
      debugPrint('Download error: $e');
      onError('Download failed: $e');
      return false;
    }
  }

  /// Delete the downloaded model
  Future<void> deleteModel() async {
    final modelPath = await getModelPath();
    final file = File(modelPath);
    final tempFile = File('$modelPath.tmp');

    if (await file.exists()) {
      await file.delete();
    }
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  /// Get model file size in MB
  Future<double> getModelSizeMB() async {
    final modelPath = await getModelPath();
    final file = File(modelPath);
    if (await file.exists()) {
      final size = await file.length();
      return size / (1024 * 1024);
    }
    return 0;
  }
}
