import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import '../models/ai_model_info.dart';
import '../models/download_state.dart';
import '../services/model_manager.dart';
import '../services/llm_service.dart';
import '../services/chat_storage_service.dart';
import '../services/log_service.dart';

class ModelController extends GetxController {
  final ModelManager _manager = Get.find<ModelManager>();
  final LlmService _llm = Get.find<LlmService>();
  final ChatStorageService _storage = Get.find<ChatStorageService>();

  final selectedModelFilename = RxnString();
  final loadingModelFilename = RxnString();
  final isLoadingModel = false.obs;
  final isImportingModel = false.obs;
  final loadingStatusMsg = ''.obs;
  final loadingProgress = 0.0.obs;
  final loadError = ''.obs;

  List<AiModelInfo> get catalog => _manager.catalog;
  List<String> get downloadedModels => _manager.downloadedModels;
  bool get isModelLoaded => _llm.isLoaded.value;
  double get tokensPerSecond => _llm.tokensPerSecond.value;

  @override
  void onInit() {
    super.onInit();
    final lastId = _storage.lastModelId;
    if (lastId.isNotEmpty) {
      selectedModelFilename.value = lastId;
    }

    ever(_llm.loadingProgress, (double progress) {
      loadingProgress.value = progress;
    });
    ever(_llm.loadingStatusMsg, (String msg) {
      if (msg.isNotEmpty) {
        loadingStatusMsg.value = msg;
      }
    });
  }

  bool isDownloading(String filename) => _manager.isDownloading(filename);

  DownloadState? getDownloadState(String filename) =>
      _manager.getDownloadState(filename);

  Future<void> downloadModel(AiModelInfo model) async {
    final confirmed = await _confirmLargeModel(model.sizeGb);
    if (!confirmed) return;

    LogService? log;
    try {
      log = Get.find<LogService>();
    } catch (_) {}
    log?.info(
      'Starting download: ${model.name} (${model.sizeGb} GB)',
      source: 'Download',
    );
    try {
      await _manager.downloadModel(model);
      log?.info('Download complete: ${model.name}', source: 'Download');
    } catch (e) {
      log?.error('Download failed: ${model.name} — $e', source: 'Download');
    }
  }

  void cancelDownload(String filename) {
    _manager.cancelDownload(filename);
  }

  Future<void> deleteModel(String filename) async {
    await _manager.deleteModel(filename);
    if (selectedModelFilename.value == filename) {
      await _llm.unloadModel();
      selectedModelFilename.value = null;
    }
  }

  Future<void> deleteCustomModel(AiModelInfo model) async {
    await _manager.deleteModel(model.filename);

    _manager.removeCustomModel(model.id);
    if (selectedModelFilename.value == model.filename) {
      await _llm.unloadModel();
      selectedModelFilename.value = null;
    }
  }

  Future<void> loadModel(String filename) async {
    if (isLoadingModel.value) {
      cancelLoadModel();

      await Future.delayed(const Duration(milliseconds: 200));
    }

    loadingModelFilename.value = filename;
    isLoadingModel.value = true;
    loadingStatusMsg.value = 'Preparing...';
    loadingProgress.value = 0.0;
    loadError.value = '';

    try {
      final path = _manager.getModelPathByFilename(filename);
      final file = File(path);

      if (await file.exists()) {
        final sizeGb = (await file.length()) / (1024 * 1024 * 1024);
        final confirmed = await _confirmLargeModel(sizeGb);
        if (!confirmed) {
          cancelLoadModel();
          return;
        }
      }

      await _llm.loadModel(path);

      if (!_llm.isLoaded.value && loadingModelFilename.value == null) {
        return;
      }

      selectedModelFilename.value = filename;
      _storage.lastModelId = filename;
    } catch (e) {
      loadError.value = e.toString();
      LogService? log;
      try {
        log = Get.find<LogService>();
      } catch (_) {}
      log?.error('Load failed: $filename — $e', source: 'Model');
    } finally {
      isLoadingModel.value = false;
      loadingStatusMsg.value = '';
      loadingProgress.value = 0.0;
      loadingModelFilename.value = null;
    }
  }

  void cancelLoadModel() {
    _llm.cancelLoading();
    isLoadingModel.value = false;
    loadingStatusMsg.value = '';
    loadingProgress.value = 0.0;
    loadingModelFilename.value = null;
  }

  void cancelImport() {
    isImportingModel.value = false;
    loadingStatusMsg.value = '';
    loadingProgress.value = 0.0;
    loadingModelFilename.value = null;
  }

  Future<void> unloadCurrentModel() async {
    await _llm.unloadModel();
  }

  Future<void> unloadModel() async {
    await _llm.unloadModel();
    selectedModelFilename.value = null;
  }

  Future<void> clearCache() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (e) {}
  }

  Timer? _pulseTimer;
  final _pulseMessages = [
    'System is caching the file. Please wait...',
    'Android is preparing the model...',
    'Almost there, checking file integrity...',
    'Allocating temporary space...',
    'Wrapping up system preparation...',
  ];
  int _pulseIndex = 0;

  void _startCachingPulse() {
    _stopCachingPulse();
    _pulseIndex = 0;
    loadingStatusMsg.value = _pulseMessages[0];
    _pulseTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _pulseIndex = (_pulseIndex + 1) % _pulseMessages.length;
      loadingStatusMsg.value = _pulseMessages[_pulseIndex];
    });
  }

  void _stopCachingPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }

  Future<bool> _confirmLargeModel(double sizeGb) async {
    if (sizeGb < 3.5) return true;

    final completer = Completer<bool>();
    Get.defaultDialog(
      title: 'Large Model Warning',
      titlePadding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      contentPadding: const EdgeInsets.all(20),
      middleText:
          'This model is ${sizeGb.toStringAsFixed(1)} GB.\n\nDevices with less than 8GB of RAM may crash or run out of storage while processing this model.\n\nAre you sure you want to proceed?',
      textConfirm: 'Proceed',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      cancelTextColor: Colors.orange,
      onConfirm: () {
        Get.back();
        completer.complete(true);
      },
      onCancel: () {
        completer.complete(false);
      },
    );
    return completer.future;
  }

  Future<void> importModelFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        onFileLoading: (FilePickerStatus status) {
          if (status == FilePickerStatus.picking) {
            loadingModelFilename.value = 'Selected File';
            isImportingModel.value = true;
            loadingProgress.value = 0.0;
            _startCachingPulse();
          }
        },
      );

      if (result != null && result.files.isNotEmpty) {
        _stopCachingPulse();
        final file = result.files.single;
        final name = file.name;

        if (!name.endsWith('.gguf')) {
          return;
        }

        final sizeGb = file.size / (1024 * 1024 * 1024);
        final confirmed = await _confirmLargeModel(sizeGb);
        if (!confirmed) return;

        loadingModelFilename.value = name;
        isImportingModel.value = true;
        loadingStatusMsg.value = 'Moving to models folder...';
        loadingProgress.value = 0.0;

        if (file.path != null) {
          await _manager.moveModel(file.path!, name);
        } else if (file.readStream != null) {
          await _manager.importModelFromStream(
            filename: name,
            stream: file.readStream!,
            totalBytes: file.size,
            onProgress: (p) => loadingProgress.value = p,
            checkCancelled: () => !isImportingModel.value,
          );
        }

        if (!isImportingModel.value) return;

        final exists = _manager.catalog.any((m) => m.filename == name);

        if (!exists) {
          final customModel = AiModelInfo(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            name: name.replaceAll('.gguf', ''),
            filename: name,
            url: 'local',
            sizeGb: sizeGb,
            minRamGb: 0,
            label: 'CUSTOM',
            badge: 'LOCAL',
            systemPrompt: 'You are a helpful AI assistant.',
          );
          _manager.addCustomModel(customModel);
        }
      }
    } catch (e) {
    } finally {
      _stopCachingPulse();
      isImportingModel.value = false;
      loadingStatusMsg.value = '';
      loadingProgress.value = 0.0;
      loadingModelFilename.value = null;

      try {
        await FilePicker.platform.clearTemporaryFiles();
      } catch (_) {}
    }
  }

  Future<void> importFromDirectory() async {
    try {
      final dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null) return;

      final dir = Directory(dirPath);
      final ggufFiles = await dir
          .list(recursive: true)
          .where((f) => f is File && f.path.endsWith('.gguf'))
          .toList();

      if (ggufFiles.isEmpty) {
        return;
      }

      int imported = 0;
      for (int i = 0; i < ggufFiles.length; i++) {
        final file = ggufFiles[i] as File;

        final sizeGb = (await file.length()) / (1024 * 1024 * 1024);
        final confirmed = await _confirmLargeModel(sizeGb);
        if (!confirmed) continue;

        loadingModelFilename.value = file.uri.pathSegments.last;
        isImportingModel.value = true;
        loadingStatusMsg.value = 'Importing ${i + 1} of ${ggufFiles.length}...';
        loadingProgress.value = 0.0;

        await _manager.importModel(
          file.path,
          onProgress: (p) => loadingProgress.value = p,
          checkCancelled: () => !isImportingModel.value,
        );

        if (!isImportingModel.value) return;

        final fileName = file.uri.pathSegments.last;
        final exists = _manager.catalog.any((m) => m.filename == fileName);

        if (!exists) {
          final customModel = AiModelInfo(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: fileName.replaceAll('.gguf', ''),
            filename: fileName,
            url: 'local',
            sizeGb: sizeGb,
            minRamGb: 0,
            label: 'CUSTOM',
            badge: 'LOCAL',
            systemPrompt: 'You are a helpful AI assistant.',
          );
          _manager.addCustomModel(customModel);
        }

        imported++;
      }
    } catch (e) {
    } finally {
      isImportingModel.value = false;
      loadingStatusMsg.value = '';
      loadingProgress.value = 0.0;
      loadingModelFilename.value = null;
    }
  }

  bool isModelDownloaded(AiModelInfo model) {
    return _manager.isModelDownloaded(model);
  }

  AiModelInfo? getModelInfo(String filename) {
    try {
      return catalog.firstWhere((m) => m.filename == filename);
    } catch (_) {
      return null;
    }
  }

  Future<void> addCustomUrlModel({
    required String name,
    required String url,
  }) async {
    final uri = Uri.parse(url);
    String filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (!filename.endsWith('.gguf')) {
      filename =
          '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}.gguf';
    }

    double sizeGb = 0;
    try {
      final client = HttpClient();
      final request = await client.headUrl(uri);
      final response = await request.close();
      final contentLength = response.contentLength;
      client.close();
      if (contentLength > 0) {
        sizeGb = double.parse(
          (contentLength / (1024 * 1024 * 1024)).toStringAsFixed(2),
        );
      }
    } catch (_) {}

    int minRam = 4;
    if (sizeGb > 0) {
      minRam = ((sizeGb * 1.2) / 2).ceil() * 2;
      if (minRam < 4) minRam = 4;
    }

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final model = AiModelInfo(
      id: id,
      name: name,
      filename: filename,
      url: url,
      sizeGb: sizeGb,
      minRamGb: minRam,
      label: 'CUSTOM',
      badge: 'USER ADDED',
      systemPrompt: '',
    );

    _manager.addCustomModel(model);

    final sizeStr = sizeGb > 0 ? ' (${sizeGb} GB)' : '';
  }
}
