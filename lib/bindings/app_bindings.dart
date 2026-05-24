import 'package:get/get.dart';

import '../services/llm_service.dart';
import '../services/model_manager.dart';
import '../services/chat_storage_service.dart';
import '../services/local_api_server_service.dart';
import '../services/wakelock_service.dart';
import '../services/log_service.dart';
import '../controllers/chat_controller.dart';
import '../controllers/model_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/update_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LlmService(), fenix: true);
    Get.lazyPut(() => ModelManager(), fenix: true);
    Get.lazyPut(() => ChatStorageService(), fenix: true);
    Get.lazyPut(() => LocalApiServerService(), fenix: true);
    Get.lazyPut(() => WakelockService(), fenix: true);
    Get.lazyPut(() => LogService(), fenix: true);

    Get.put(ThemeController());
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => ModelController(), fenix: true);
    Get.lazyPut(() => UpdateController(), fenix: true);
  }
}
