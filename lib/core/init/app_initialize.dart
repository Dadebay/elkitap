import 'dart:async';

// import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:elkitap/core/config/secure_file_storage_service.dart';
import 'package:elkitap/core/init/firebase_messaging_service.dart';
import 'package:elkitap/core/init/local_notifications_service.dart';
import 'package:elkitap/core/init/theme_controller.dart';
import 'package:elkitap/core/init/translation_service.dart';
import 'package:elkitap/data/controller/connection_controller.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/core/utils/time_helper.dart';
import 'package:elkitap/firebase_options.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:elkitap/modules/fcm/fcm_controller.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/controllers/library_main_controller.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/paymant/controller/promo_code_controller.dart';
import 'package:elkitap/modules/profile/controllers/contacts_controller.dart';
import 'package:elkitap/modules/reader/controllers/reader_controller.dart';
import 'package:elkitap/modules/search/controllers/search_controller.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/authors_controller.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/controllers/collections_controller.dart';
import 'package:elkitap/modules/library/controllers/suggestion_controller.dart';
import 'package:elkitap/modules/store/controllers/pro_readers_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

@immutable
final class ApplicationInitialize {
  const ApplicationInitialize._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    //    await JustAudioBackground.init(
    //   androidNotificationChannelId: 'com.elkitap.audio.channel',
    //   androidNotificationChannelName: 'Audiobook Playback',
    //   androidNotificationOngoing: true,
    // );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    await runZonedGuarded<Future<void>>(_initialize, (error, stack) {
      // Logger().e(error.toString());
    });
  }

  static Future<void> _initialize() async {
    try {
      // Core services - permanent
      await GetStorage.init();
      Get.put(TokenManager(), permanent: true);
      Get.put(NetworkManager(), permanent: true);
      Get.put(SecureFileStorageService(), permanent: true);
      Get.put(TranslationService(), permanent: true);
      Get.put(ThemeController(), permanent: true);
      Get.put(FcmController(), permanent: true);

      // Audio controllers - permanent (needed across app lifecycle)
      Get.put(AudioPlayerController(), permanent: true);
      Get.put(GlobalMiniPlayerController(), permanent: true);
      Get.put(EpubController(), permanent: true);

      // User session dependent controllers - NOT permanent, will be recreated on login
      Get.put(AuthController(), permanent: true); // Keep permanent for auth state
      Get.put(AllGenresController());
      Get.put(AuthorController());
      Get.put(SearchResultsController());
      Get.put(BooksDetailController());
      Get.put(GetAllBooksController());
      Get.put(ProfessionalReadsController());
      Get.put(DownloadController());
      Get.put(BookCollectionController());
      Get.put(LibraryMainController());
      Get.put(NotesController());
      Get.put(ConnectionController(), permanent: true);
      Get.put(ContactsController());
      Get.put(PromoCodeController());
      Get.put(PaymentController());
      Get.put(SuggestionController());

      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Initialize valid generic services
      final localNotificationsService = LocalNotificationsService.instance();
      await localNotificationsService.init();

      // Initialize network-dependent services in background
      // This ensures the app starts up even if offline
      _initNetworkServices(localNotificationsService);
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  static Future<void> _initNetworkServices(LocalNotificationsService localNotificationsService) async {
    try {
      final firebaseMessagingService = FirebaseMessagingService.instance();
      await firebaseMessagingService.init(localNotificationsService: localNotificationsService);

      // Initialize TimeHelper
      await TimeHelper.init();

      await FirebaseMessaging.instance.subscribeToTopic('EVENT');

      // Get and print Firebase FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔥 Firebase FCM Token: $fcmToken');

      // Get and print APNS token (iOS only)
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      debugPrint('🍎 APNS Token: $apnsToken');

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 Firebase Token Refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('Network service initialization failed (likely offline): $e');
    }
  }
}
