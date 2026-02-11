import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  ThemeMode get themeMode => _box.read(_key) == true ? ThemeMode.dark : ThemeMode.light;

  void _saveThemeMode(bool isDarkMode) => _box.write(_key, isDarkMode);

  void _loadThemeMode() {
    if (_box.hasData(_key)) {
      Get.changeThemeMode(themeMode);
    } else {
      _saveThemeMode(false);
      Get.changeThemeMode(ThemeMode.light);
    }
    update(); // Add this to notify GetBuilder
  }

  void toggleTheme() {
    if (themeMode == ThemeMode.light) {
      _saveThemeMode(true);
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      _saveThemeMode(false);
      Get.changeThemeMode(ThemeMode.light);
    }
    update(); // Add this to notify GetBuilder
  }

  void setTheme(ThemeMode mode) {
    _saveThemeMode(mode == ThemeMode.dark);
    Get.changeThemeMode(mode);
    update(); // Add this to notify GetBuilder
  }
}