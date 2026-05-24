import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models/chat_model.dart';
import 'models/message_model.dart';
import 'theme/app_theme.dart';
import 'bindings/app_bindings.dart';
import 'controllers/theme_controller.dart';

import 'screens/splash_screen.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exception}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformError: $error\n$stack');
        return true;
      };

      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);

      Hive.registerAdapter(ChatModelAdapter());
      Hive.registerAdapter(MessageModelAdapter());
      Hive.registerAdapter(MessageRoleAdapter());

      await Hive.openBox<ChatModel>('chats');
      await Hive.openBox('settings');
      await Hive.openBox('models_meta');

      final themeController = Get.put(ThemeController());

      runApp(PortableAIApp(themeController: themeController));
    },
    (error, stack) {
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
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
          statusBarColor: theme.colorScheme.surface,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: theme.colorScheme.surface,
          systemNavigationBarDividerColor: theme.colorScheme.surface,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
