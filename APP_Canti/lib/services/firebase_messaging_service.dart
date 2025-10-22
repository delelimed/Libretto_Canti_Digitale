import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 🔥 Gestisce sia messaggi FCM che notifiche locali
class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// 🔹 Inizializza tutto
  static Future<void> initNotifications(BuildContext context) async {
    tz.initializeTimeZones();

    // Richiedi permessi
    await _requestPermission();

    // Configura il canale Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null) {
          Navigator.of(context).pushNamed('/celebrazione', arguments: payload);
        }
      },
    );

    // 🔹 Gestione messaggi in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 🔹 Se la notifica viene toccata (app chiusa o in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = message.data['route'];
      if (payload != null) {
        Navigator.of(context).pushNamed('/celebrazione', arguments: payload);
      }
    });

    // 🔹 Stampa token (utile per test console Firebase)
    final token = await _messaging.getToken();
    print('🔥 FCM Token: $token');
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  /// 🔹 Mostra la notifica localmente (foreground)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'celebrazioni_channel',
      'Notifiche Celebrazioni',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['route'],
    );
  }

  /// 🔹 Pianifica notifica locale 5 minuti prima
  static Future<void> scheduleLocalNotification({
    required String id,
    required String titolo,
    required String messaggio,
    required DateTime orario,
  }) async {
    final scheduledTime = orario.subtract(const Duration(minutes: 5));

    await _localNotifications.zonedSchedule(
      id.hashCode,
      titolo,
      messaggio,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'celebrazioni_channel',
          'Notifiche Celebrazioni',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: id,
    );
  }

  /// 🔹 Cancella una notifica programmata
  static Future<void> cancelNotification(String id) async {
    await _localNotifications.cancel(id.hashCode);
  }
}
