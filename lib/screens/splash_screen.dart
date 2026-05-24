import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../services/llm_service.dart';
import '../services/model_manager.dart';
import '../services/chat_storage_service.dart';
import '../services/local_api_server_service.dart';
import '../services/wakelock_service.dart';
import '../services/log_service.dart';
import '../services/background_optimizer_service.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final log = Get.find<LogService>()..init();

      setState(() => _status = 'Setting up storage...');
      log.info('Initializing storage...', source: 'Splash');
      await Get.find<ChatStorageService>().init();

      setState(() => _status = 'Loading model catalog...');
      log.info('Loading model catalog...', source: 'Splash');
      await Get.find<ModelManager>().init();

      setState(() => _status = 'Preparing AI engine...');
      log.info('Preparing AI engine...', source: 'Splash');
      await Get.find<LlmService>().init();

      setState(() => _status = 'Preparing local API...');
      log.info('Preparing local API...', source: 'Splash');
      await Get.find<LocalApiServerService>().init();

      setState(() => _status = 'Setting up background services...');
      log.info('Setting up background services...', source: 'Splash');
      await Get.find<WakelockService>().init();

      setState(() => _status = 'Ready!');
      log.info('All services initialized successfully', source: 'Splash');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await BackgroundOptimizerService.checkAndPrompt(context);
      }

      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      setState(() => _status = 'Error: $e');
      try {
        Get.find<LogService>().error('Init failed: $e', source: 'Splash');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Text(
              'Whyy Cloud',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: context.text,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              'Run uncensored LLMs natively on any device',
              style: TextStyle(fontSize: 13, color: context.textM),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            const SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(context.accent),
              ),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(fontSize: 12, color: context.textD),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
