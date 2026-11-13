import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification payloads are displayed by Android when the app is backgrounded.
}

abstract interface class PushTokenProvider {
  Future<String?> requestPermissionAndGetToken();
  Future<String?> getToken();
  Future<void> deleteToken();
  void setTokenRefreshHandler(Future<void> Function(String token)? handler);
}

class NotificationService implements PushTokenProvider {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _pendingRefreshedToken;
  Future<void> Function(String token)? _tokenRefreshHandler;
  VoidCallback? _notificationTapHandler;
  bool _pendingNotificationTap = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) => _dispatchNotificationTap(),
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        unawaited(_showLocalNotification(message));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _dispatchNotificationTap();
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _pendingNotificationTap = true;
    }
    _fcm.onTokenRefresh.listen((token) {
      final handler = _tokenRefreshHandler;
      if (handler == null) {
        _pendingRefreshedToken = token;
      } else {
        unawaited(handler(token));
      }
    });
    _initialized = true;
  }

  @override
  Future<String?> requestPermissionAndGetToken() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }

    return getToken();
  }

  @override
  Future<String?> getToken() => _fcm.getToken();

  @override
  Future<void> deleteToken() => _fcm.deleteToken();

  @override
  void setTokenRefreshHandler(Future<void> Function(String token)? handler) {
    _tokenRefreshHandler = handler;
    final pendingToken = _pendingRefreshedToken;
    if (handler != null && pendingToken != null) {
      _pendingRefreshedToken = null;
      unawaited(handler(pendingToken));
    }
  }

  void setNotificationTapHandler(VoidCallback handler) {
    _notificationTapHandler = handler;
    if (_pendingNotificationTap) {
      _pendingNotificationTap = false;
      handler();
    }
  }

  void _dispatchNotificationTap() {
    final handler = _notificationTapHandler;
    if (handler == null) {
      _pendingNotificationTap = true;
    } else {
      handler();
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  // Method buat ngetes gampang dari UI
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    await _localNotifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
