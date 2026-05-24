import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path/path.dart' as p;

import 'wakelock_service.dart';
import 'chat_storage_service.dart';
import 'log_service.dart';

class LlmService extends GetxService {
  LlamaEngine? _engine;
  LlamaBackend? _backend;

  final isLoaded = false.obs;
  final isGenerating = false.obs;
  final loadedModelPath = ''.obs;
  final tokensPerSecond = 0.0.obs;
  final lastGenerationTokens = 0.obs;
  final lastGenerationSpeed = 0.0.obs;

  final isLoadingModel = false.obs;
  final loadingProgress = 0.0.obs;
  final loadingStatusMsg = ''.obs;
  bool _loadingCancelled = false;

  StreamSubscription? _generateSub;

  String get loadedModelFilename {
    final path = loadedModelPath.value;
    if (path.isEmpty) return '';
    return p.basename(path);
  }

  String get publicModelId {
    final filename = loadedModelFilename;
    if (filename.isEmpty) return 'local';
    final stem = filename.toLowerCase().endsWith('.gguf')
        ? filename.substring(0, filename.length - 5)
        : p.basenameWithoutExtension(filename);
    return stem
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<LlmService> init() async {
    return this;
  }

  void cancelLoading() {
    _loadingCancelled = true;
  }

  Future<void> loadModel(String path) async {
    LogService? log;
    try {
      log = Get.find<LogService>();
    } catch (_) {}

    final file = File(path);
    if (!await file.exists()) {
      log?.error('Model file not found: $path', source: 'LLM');
      throw Exception('Model file not found: $path');
    }

    final filename = p.basename(path);
    log?.info('Loading model: $filename', source: 'LLM');

    final header = await file.open(mode: FileMode.read);
    try {
      final magic = await header.read(4);
      if (magic.length < 4 || String.fromCharCodes(magic) != 'GGUF') {
        throw Exception(
          'Model file is not a valid GGUF file. Please re-download the model.',
        );
      }
    } finally {
      await header.close();
    }

    _loadingCancelled = false;
    isLoadingModel.value = true;
    loadingProgress.value = 0.0;
    loadingStatusMsg.value = 'Preparing...';

    WakelockService? wakelockService;
    try {
      wakelockService = Get.find<WakelockService>();
    } catch (_) {}

    if (_engine != null || isLoaded.value) {
      loadingStatusMsg.value = 'Unloading previous model...';
      loadingProgress.value = 0.05;
      await _fullTeardown();

      await Future.delayed(const Duration(milliseconds: 500));
      if (_loadingCancelled) {
        _resetLoadingState();
        return;
      }
    }

    try {
      _backend = LlamaBackend();
      _engine = LlamaEngine(_backend!);
    } catch (e) {
      _backend = null;
      _engine = null;
      _resetLoadingState();
      log?.error('Engine init failed: $e', source: 'LLM');
      throw Exception(
        'Failed to initialize AI engine. '
        'This may be a device compatibility issue. '
        'Error: $e',
      );
    }

    try {
      loadingStatusMsg.value = 'Loading into memory...';
      loadingProgress.value = 0.1;

      final fileSize = await file.length();
      final sizeGb = (fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1);
      loadingStatusMsg.value = 'Loading $sizeGb GB into memory...';

      Timer? progressTimer;
      progressTimer = Timer.periodic(const Duration(milliseconds: 300), (
        timer,
      ) {
        if (_loadingCancelled) {
          timer.cancel();
          return;
        }

        final current = loadingProgress.value;
        if (current < 0.95) {
          loadingProgress.value = current + (0.95 - current) * 0.04;
        }
      });

      if (_loadingCancelled) {
        progressTimer.cancel();
        await _fullTeardown();
        _resetLoadingState();
        return;
      }

      final contextSize = Platform.isAndroid ? 1024 : 2048;

      final storage = Get.find<ChatStorageService>();
      GpuBackend parsedBackend;
      switch (storage.backendType) {
        case 'vulkan':
          parsedBackend = GpuBackend.vulkan;
          break;
        case 'opencl':
          parsedBackend = GpuBackend.opencl;
          break;
        default:
          parsedBackend = GpuBackend.cpu;
      }

      final userGpuLayers = storage.gpuLayers;

      final params = ModelParams(
        contextSize: contextSize,
        gpuLayers: userGpuLayers,
        preferredBackend: parsedBackend,
        numberOfThreads: Platform.numberOfProcessors > 4 ? 4 : 0,
        numberOfThreadsBatch: Platform.numberOfProcessors > 4 ? 4 : 0,
      );

      log?.info(
        'Backend=$parsedBackend, GPU layers=$userGpuLayers, ctx=$contextSize, threads=${Platform.numberOfProcessors > 4 ? 4 : 0}',
        source: 'LLM',
      );

      await _engine!.loadModel(path, modelParams: params);
      progressTimer.cancel();

      if (_loadingCancelled) {
        await _fullTeardown();
        _resetLoadingState();
        return;
      }

      loadingProgress.value = 1.0;
      loadingStatusMsg.value = 'Ready!';
      isLoaded.value = true;
      loadedModelPath.value = path;
      log?.info('Model loaded successfully: $filename', source: 'LLM');

      final modelName = p.basenameWithoutExtension(path);
      await wakelockService?.enableForInference(modelName: modelName);

      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      isLoaded.value = false;
      loadedModelPath.value = '';
      await _fullTeardown();
      log?.error('Model load failed: $e', source: 'LLM');

      if (Platform.isAndroid) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('memory') || errStr.contains('alloc')) {
          throw Exception(
            'Not enough RAM to load this model. '
            'Try a smaller model (e.g. Gemma 2 2B at 1.6 GB).',
          );
        }
      }
      rethrow;
    } finally {
      _resetLoadingState();
    }
  }

  void _resetLoadingState() {
    isLoadingModel.value = false;
    loadingProgress.value = 0.0;
    loadingStatusMsg.value = '';
    _loadingCancelled = false;
  }

  static final _stopPatterns = RegExp(
    r'<\|end\|>'
    r'|<\|eot_id\|>'
    r'|<\|endoftext\|>'
    r'|<\|im_end\|>'
    r'|<\|im_start\|>'
    r'|<end_of_turn>'
    r'|<start_of_turn>'
    r'|<\|assistant\|>'
    r'|<\|user\|>'
    r'|<\|system\|>'
    r'|<\|pad\|>'
    r'|</s>'
    r'|<s>'
    r'|\[INST\]'
    r'|\[/INST\]'
    r'|\[end\]',
  );

  static final _userTurnPattern = RegExp(
    r'<\|user\|>|<\|im_start\|>\s*user|<start_of_turn>\s*user|\[INST\]',
  );

  Stream<String> generate({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double temperature = 0.7,
  }) async* {
    if (_engine == null || !isLoaded.value) {
      throw StateError('No model loaded. Call loadModel() first.');
    }
    if (isGenerating.value) {
      throw StateError('Another generation is already in progress.');
    }

    isGenerating.value = true;
    tokensPerSecond.value = 0.0;
    final stopwatch = Stopwatch()..start();
    int tokenCount = 0;

    String buffer = '';

    try {
      final prompt = _buildPrompt(messages, systemPrompt);

      await for (final token in _engine!.generate(prompt)) {
        tokenCount++;
        if (stopwatch.elapsedMilliseconds > 0) {
          tokensPerSecond.value =
              tokenCount / (stopwatch.elapsedMilliseconds / 1000);
        }

        buffer += token;

        if (_userTurnPattern.hasMatch(buffer)) {
          final cleaned = buffer
              .replaceAll(_stopPatterns, '')
              .replaceAll(_userTurnPattern, '')
              .trim();
          if (cleaned.isNotEmpty) {
            yield cleaned;
          }
          break;
        }

        if (_stopPatterns.hasMatch(buffer)) {
          final cleaned = buffer.replaceAll(_stopPatterns, '').trim();
          if (cleaned.isNotEmpty) {
            yield cleaned;
          }
          break;
        }

        if (buffer.length > 40) {
          final safe = buffer.substring(0, buffer.length - 30);
          buffer = buffer.substring(buffer.length - 30);
          yield safe;
        }
      }

      if (buffer.isNotEmpty) {
        final cleaned = buffer
            .replaceAll(_stopPatterns, '')
            .replaceAll(_userTurnPattern, '')
            .trim();
        if (cleaned.isNotEmpty) {
          yield cleaned;
        }
      }
    } finally {
      stopwatch.stop();
      lastGenerationTokens.value = tokenCount;
      lastGenerationSpeed.value = tokensPerSecond.value;
      isGenerating.value = false;
    }
  }

  Stream<String> generateChatCompletion({
    required List<LlamaChatMessage> messages,
    GenerationParams params = const GenerationParams(),
  }) async* {
    if (_engine == null || !isLoaded.value) {
      throw StateError('No model loaded. Call loadModel() first.');
    }
    if (isGenerating.value) {
      throw StateError('Another generation is already in progress.');
    }

    isGenerating.value = true;
    tokensPerSecond.value = 0.0;
    final stopwatch = Stopwatch()..start();
    int tokenCount = 0;

    try {
      await for (final chunk in _engine!.create(
        messages,
        params: params,
        toolChoice: ToolChoice.none,
      )) {
        final choice = chunk.choices.isNotEmpty ? chunk.choices.first : null;
        final content = choice?.delta.content;
        if (content == null || content.isEmpty) continue;

        tokenCount++;
        if (stopwatch.elapsedMilliseconds > 0) {
          tokensPerSecond.value =
              tokenCount / (stopwatch.elapsedMilliseconds / 1000);
        }
        yield content;
      }
    } finally {
      stopwatch.stop();
      lastGenerationTokens.value = tokenCount;
      lastGenerationSpeed.value = tokensPerSecond.value;
      isGenerating.value = false;
    }
  }

  Future<int> countTokens(String text) async {
    if (_engine == null || !isLoaded.value) return 0;
    try {
      return await _engine!.getTokenCount(text);
    } catch (_) {
      return 0;
    }
  }

  Future<void> stopGeneration() async {
    _generateSub?.cancel();
    _generateSub = null;
    _engine?.cancelGeneration();
    isGenerating.value = false;
  }

  Future<void> _fullTeardown() async {
    if (_engine != null) {
      try {
        await _engine!.dispose();
      } catch (_) {}
      _engine = null;
    }

    _backend = null;
    isLoaded.value = false;
    loadedModelPath.value = '';
    tokensPerSecond.value = 0.0;
  }

  Future<void> unloadModel() async {
    await _fullTeardown();

    try {
      final wakelockService = Get.find<WakelockService>();
      await wakelockService.disable();
    } catch (_) {}
  }

  String _buildPrompt(
    List<Map<String, String>> messages,
    String? systemPrompt,
  ) {
    final buffer = StringBuffer();

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      buffer.writeln('<|system|>');
      buffer.writeln(systemPrompt);
      buffer.writeln('<|end|>');
    }

    for (final msg in messages) {
      final role = msg['role'] ?? 'user';
      final content = msg['content'] ?? '';
      buffer.writeln('<|$role|>');
      buffer.writeln(content);
      buffer.writeln('<|end|>');
    }

    buffer.writeln('<|assistant|>');
    return buffer.toString();
  }

  @override
  void onClose() {
    unloadModel();
    super.onClose();
  }
}
