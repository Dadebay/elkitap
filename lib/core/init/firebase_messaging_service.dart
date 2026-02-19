// ignore_for_file: avoid_print

import 'package:elkitap/core/init/local_notifications_service.dart';
import 'package:elkitap/modules/fcm/fcm_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._internal();

  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();

  factory FirebaseMessagingService.instance() => _instance;

  LocalNotificationsService? _localNotificationsService;

  Future<void> init({required LocalNotificationsService localNotificationsService}) async {
    _localNotificationsService = localNotificationsService;

    _handlePushNotificationsToken();

    _requestPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    // if (initialMessage != null) {
    //   _onMessageOpenedApp(initialMessage);
    // }
  }

  Future<void> _handlePushNotificationsToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $token");
      if (token != null) {
        Get.find<FcmController>().updateFcmToken(token);
      }
    } catch (e) {
      print("Error fetching FCM token: $e");
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      print("FCM Token Refreshed: $fcmToken");
      Get.find<FcmController>().updateFcmToken(fcmToken);
    }).onError((error) {});
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _incrementNotificationCount();
    final notificationData = message.notification;
    if (notificationData != null) {
      _localNotificationsService?.showNotification(notificationData.title, notificationData.body, message.data.toString());
    }
  }

  // void _onMessageOpenedApp(RemoteMessage message) {
  //   log('Notification caused the app to open: ${message.data.toString()}');
  // }
}

Future<void> _incrementNotificationCount() async {
  await GetStorage.init();
  final box = GetStorage();
  final currentCount = box.read<int>('notification_count') ?? 0;
  await box.write('notification_count', currentCount + 1);

  // if (Get.isRegistered<NotificationController>()) {
  //   Get.find<NotificationController>().increment();
  // }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _incrementNotificationCount();
}
