import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;
  bool _initDone = false;
  bool _permissionDone = false;
  bool _localNotifReady = false;

  FirebaseMessaging get _msg {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  Future<void> init() async {
    if (_initDone) return;
    _initDone = true;

    try {
      // 1. Permission
      if (!_permissionDone) {
        final settings = await _msg.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionDone = true;
        debugPrint('[Push] Permission: ${settings.authorizationStatus}');
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('[Push] Denied — push disabled');
          return;
        }
      }

      // 2. iOS foreground
      await _msg.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Local notifications (Android foreground)
      await _initLocalNotifications();

      // 4. Foreground message listener
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      // 5. Token refresh
      _msg.onTokenRefresh.listen((newToken) async {
        debugPrint('[Push] Token refreshed');
        _currentToken = newToken;
        await _registerWithBackend(newToken);
      });

      debugPrint('[Push] ✅ Service initialized ($_platform)');
    } catch (e, st) {
      debugPrint('[Push] Init failed: $e\n$st');
    }
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotifReady) return;

    //  BARE resource name — no @drawable/ prefix
    const android = AndroidInitializationSettings('ic_notification');

    // iOS permission is already requested via FCM above
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: android, iOS: ios);

    final initialized = await _localNotif.initialize(
      settings: settings,

      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[Push] Notification tapped: ${response.payload}');
        // TODO: navigate to offer using response.payload as offerId
      },
    );

    debugPrint('[Push] localNotif init: $initialized');

    // Android 8+ requires a notification channel
    final androidPlugin = _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        'barter_notifications',
        'Barter Notifications',
        description: 'Barter offers, messages, and updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
      debugPrint('[Push] Notification channel created');
    }

    _localNotifReady = true;
  }

  void _showForegroundNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
    if (!_localNotifReady) return;

    debugPrint('[Push] Foreground: ${notif.title}');

    //  BARE resource names — no @drawable/ or @mipmap/ prefix
   final androidDetails = AndroidNotificationDetails(
  'barter_notifications',
  'Barter Notifications',
  channelDescription: 'Barter offers, messages, and updates',
  importance: Importance.high,
  priority: Priority.high,
  icon: 'ic_notification',
  largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
  styleInformation: BigTextStyleInformation(
    notif.body ?? '',
    contentTitle: notif.title,
  ),
  color: const Color(0xFF00A86B),
  colorized: false,                    // ← ADD THIS LINE
);

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotif.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notif.title,
      body: notif.body,
      notificationDetails: details,
      payload: message.data['offerId']?.toString(),
    );
  }

  Future<void> saveTokenForUser() async {
    try {
      final token = await _msg.getToken();
      if (token == null) {
        debugPrint('[Push] No token yet');
        return;
      }
      _currentToken = token;
      debugPrint('[Push] Token: ${token.substring(0, 30)}...');
      await _registerWithBackend(token);
    } catch (e) {
      debugPrint('[Push] saveTokenForUser failed: $e');
    }
  }

  Future<void> removeTokenForUser() async {
    if (_currentToken == null) return;
    try {
      await ApiService().unregisterDeviceToken(_currentToken!);
      debugPrint('[Push] Token unregistered');
    } catch (e) {
      debugPrint('[Push] Unregister failed: $e');
    }
    _currentToken = null;
  }

  Future<void> _registerWithBackend(String token) async {
    if (!ApiService().isLoggedIn) return;
    try {
      await ApiService().registerDeviceToken(token, platform: _platform);
      debugPrint('[Push] ✅ Token saved to backend ($_platform)');
    } catch (e) {
      debugPrint('[Push] Register failed: $e');
    }
  }

  String? get currentToken => _currentToken;
}
