import 'dart:io';

// Core
import 'package:elkitap/core/config/deeplink_service.dart';
import 'package:elkitap/core/init/app_initialize.dart';
import 'package:elkitap/core/init/theme_controller.dart';
import 'package:elkitap/core/init/translation_service.dart';
import 'package:elkitap/core/theme/custom_dark_theme.dart';
import 'package:elkitap/core/theme/custom_light_theme.dart';
import 'package:elkitap/core/widgets/navigation/bottom_nav_bar.dart';
import 'package:elkitap/core/widgets/common/global_safe_are.dart';

// Modules
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/audio_player/views/global_mini_player.dart';

// Packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApplicationInitialize.initialize();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _storage = GetStorage();
  final _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  /// Initialize deep links with delay
  Future<void> _initializeDeepLinks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await _deepLinkService.initialize();
    } catch (e) {
      debugPrint('Deep link initialization error: $e');
    }
  }

  /// Convert language name to language code
  String _getLanguageCode(String languageName) {
    switch (languageName) {
      case 'English':
        return 'en';
      case 'Русский':
        return 'ru';
      case 'Türkmençe':
      default:
        return 'tr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = _storage.read('selectedLanguage') ?? 'Türkmençe';
    final languageCode = _getLanguageCode(selectedLanguage);

    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => GetMaterialApp(
        // Builder for global mini player overlay
        builder: _buildAppWithMiniPlayer,

        // Translations
        translations: TranslationService(),
        locale: Locale(languageCode),
        fallbackLocale: const Locale('tr', 'TR'),

        // Theme
        theme: CustomLightTheme().themeData,
        darkTheme: CustomDarkTheme().themeData,
        themeMode: Get.find<ThemeController>().themeMode,

        // Navigation
        defaultTransition: Transition.fade,
        debugShowCheckedModeBanner: false,

        // Home
        home: UpgradeAlert(
          child: const BottomNavScreen(),
        ),
      ),
    );
  }

  /// Build app with global mini player overlay
  Widget _buildAppWithMiniPlayer(BuildContext context, Widget? child) {
    try {
      final miniPlayerController = Get.find<GlobalMiniPlayerController>();

      return GlobalSafeAreaWrapper(
        top: false,
        bottom: !Platform.isIOS,
        child: Stack(
          children: [
            child ?? const SizedBox.shrink(),
            Obx(() {
              try {
                if (!miniPlayerController.isVisible.value) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: miniPlayerController.top.value,
                  left: miniPlayerController.left.value,
                  child: const GlobalMiniPlayer(),
                );
              } catch (e) {
                // Handle error when controller is disposed
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
      );
    } catch (e) {
      // If controller not found, return child without mini player
      return GlobalSafeAreaWrapper(
        top: false,
        bottom: !Platform.isIOS,
        child: child ?? const SizedBox.shrink(),
      );
    }
  }
}
