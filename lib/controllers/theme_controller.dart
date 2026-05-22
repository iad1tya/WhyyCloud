import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController extends GetxController {
  final _box = Hive.box('settings');
  final _key = 'isDarkMode';

  // Observable state
  final RxBool _isDarkMode = true.obs;

  bool get isDarkMode => _isDarkMode.value;

  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    // Default to dark mode if not set
    _isDarkMode.value = _box.get(_key, defaultValue: true);
  }

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _box.put(_key, _isDarkMode.value);
    Get.changeThemeMode(themeMode);
  }
}
