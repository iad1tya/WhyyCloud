import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Manages wake lock (screen stays on) and Android foreground service
/// to prevent the OS from killing downloads and inference.
class WakelockService extends GetxService {
  final isWakeLockActive = false.obs;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  Future<WakelockService> init() async {
    if (_isMobile) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'portable_ai_foreground',
          channelName: 'Whyy Cloud',
          channelDescription: 'Keeps downloads and AI inference running',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
      
      // Request notification permission for Android 13+
      await FlutterForegroundTask.requestNotificationPermission();
    }
    return this;
  }

  /// Enable wake lock + foreground service for model download.
  Future<void> enableForDownload({String modelName = 'model'}) async {
    if (!_isMobile) return;

    try {
      await WakelockPlus.enable();
      isWakeLockActive.value = true;

      await FlutterForegroundTask.startService(
        notificationTitle: 'Downloading $modelName',
        notificationText: 'Download in progress — keep the app open',
        serviceId: 100,
      );
    } catch (e) {
      debugPrint('WakelockService.enableForDownload error: $e');
    }
  }

  /// Update the foreground notification with download progress.
  Future<void> updateDownloadProgress({
    required String modelName,
    required double progress,
    String? speedText,
  }) async {
    if (!_isMobile) return;

    try {
      final pct = (progress * 100).toInt();
      final speed = speedText != null ? ' • $speedText' : '';
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Downloading $modelName — $pct%',
        notificationText: 'Download in progress$speed',
      );
    } catch (_) {}
  }

  /// Enable wake lock + foreground service for AI inference.
  Future<void> enableForInference({String modelName = 'AI model'}) async {
    if (!_isMobile) return;

    try {
      await WakelockPlus.enable();
      isWakeLockActive.value = true;

      await FlutterForegroundTask.startService(
        notificationTitle: 'AI Model Active',
        notificationText: '$modelName is loaded and ready',
        serviceId: 101,
      );
    } catch (e) {
      debugPrint('WakelockService.enableForInference error: $e');
    }
  }

  /// Disable wake lock and stop foreground service.
  Future<void> disable() async {
    if (!_isMobile) return;

    try {
      await WakelockPlus.disable();
      isWakeLockActive.value = false;
    } catch (_) {}

    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }

  @override
  void onClose() {
    disable();
    super.onClose();
  }
}
