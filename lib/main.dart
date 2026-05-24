import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models/chat_model.dart';
import 'models/message_model.dart';
import 'theme/app_theme.dart';
import 'bindings/app_bindings.dart';
import 'controllers/theme_controller.dart';
// ignore: unused_import
import 'screens/splash_screen.dart'; // needed in routes/app_routes.dart
import 'routes/app_routes.dart';

Future<void> main() async {
  // Wrap entire app in error zone to catch native/async crashes
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Catch Flutter framework errors (rendering, layout, etc.)
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exception}');
      };

      // Catch unhandled platform errors (native crashes, isolate errors)
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformError: $error\n$stack');
        return true; // Prevent app from crashing
      };

      // Init Hive
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);

      // Register Hive adapters
      Hive.registerAdapter(ChatModelAdapter());
      Hive.registerAdapter(MessageModelAdapter());
      Hive.registerAdapter(MessageRoleAdapter());

      // Open Hive boxes
      await Hive.openBox<ChatModel>('chats');
      await Hive.openBox('settings');
      await Hive.openBox('models_meta');

      // Load theme preference
      final themeController = Get.put(ThemeController());

      runApp(PortableAIApp(themeController: themeController));
    },
    (error, stack) {
      // Last-resort error handler — prevents silent force-close
      debugPrint('Unhandled error: $error\n$stack');
    },
  );
}

class PortableAIApp extends StatelessWidget {
  final ThemeController themeController;

  const PortableAIApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Whyy Cloud',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
    );
  }
}
