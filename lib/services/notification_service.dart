import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String defaultTopic = 'general';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Важные уведомления',
    description: 'Этот канал используется для важных уведомлений приложения.',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init() async {
    
    await requestPermission();

    
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            print('Notification clicked with data: $data');
          } catch (e) {
            print('Error parsing payload: $e');
          }
        }
      },
    );

    
    
    if (Platform.isAndroid) {
      const MethodChannel platformChannel = MethodChannel('dexterous.com/flutter/local_notifications');
      try {
        await platformChannel.invokeMethod('createNotificationChannel', {
          'id': channel.id,
          'name': channel.name,
          'description': channel.description,
          'importance': channel.importance.index + 1, 
          'playSound': channel.playSound,
          'enableVibration': true,
          'showBadge': true,
        });
      } catch (e) {
        print('Error creating channel via MethodChannel: $e');
      }
    }

    
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification caused app to open from background: ${message.messageId}');
    });

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state via notification: ${initialMessage.messageId}');
    }
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> subscribeToTopic([String topic = defaultTopic]) async {
    print('Subscribing to topic: $topic');
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic([String topic = defaultTopic]) async {
    print('Unsubscribing from topic: $topic');
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<String?> getToken() async {
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
    return token;
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await flutterLocalNotificationsPlugin.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}