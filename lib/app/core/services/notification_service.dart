import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Solicita permissão no iOS / Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Configura notificações locais para quando o app estiver em primeiro plano
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );

      // 3. Ouve mensagens com o App Aberto (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showLocalNotification(
            message.notification!.title ?? 'Power Shape',
            message.notification!.body ?? '',
          );
        }
      });
    }
  }

  /// Retorna o token do dispositivo para salvar no banco de dados
  static Future<String?> getDeviceToken() async {
    return await _fcm.getToken();
  }

  static void _showLocalNotification(String title, String body) {
    const androidDetails = AndroidNotificationDetails(
      'power_shape_channel',
      'Notificações Power Shape',
      importance: Importance.max,
      priority: Priority.high,
    );

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}