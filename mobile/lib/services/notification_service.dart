import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _permissionsRequested = false;
  String? _fcmToken;
  bool _isInitialized = false;

  NotificationService._internal();

  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      if (Platform.isIOS) {
        // Request provisional authorization for iOS
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: true,
        );
      }

      // Set foreground notification presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize local notifications
      final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      final initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      // Set up message handlers
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');
        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      return false;
    }
  }

  Future<String?> getFCMToken() async {
    try {
      // Ensure initialization
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Failed to initialize notification service');
        }
      }

      // For iOS, ensure we have proper permissions first
      if (Platform.isIOS) {
        debugPrint('iOS platform detected, checking notification settings...');
        final settings = await _firebaseMessaging.getNotificationSettings();
        debugPrint('Current notification settings: ${settings.authorizationStatus}');

        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          debugPrint('Requesting notification permissions for iOS...');
          final permission = await _firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
            announcement: true,
            carPlay: false,
            criticalAlert: false,
          );
          debugPrint('Permission request result: ${permission.authorizationStatus}');

          if (permission.authorizationStatus != AuthorizationStatus.authorized) {
            throw Exception('Notification permissions not granted: ${permission.authorizationStatus}');
          }
        }
      }

      // Get the token with proper error handling
      debugPrint('Requesting FCM token...');
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken == null) {
        debugPrint('FCM token is null after request');
        throw Exception('Failed to get FCM token - token is null');
      }
      debugPrint('FCM Token obtained successfully: $_fcmToken');
      
      // Set up token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
      });

      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (_permissionsRequested) {
        return await checkPermissions();
      }

      // Request FCM permissions
      final fcmSettings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Request local notification permissions on iOS
      if (Platform.isIOS) {
        final granted = await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ?? false;

        if (!granted) {
          return false;
        }
      }

      _permissionsRequested = true;
      return fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<bool> checkPermissions() async {
    try {
      final fcmSettings = await _firebaseMessaging.getNotificationSettings();
      return fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
      return false;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> scheduleDailyReminder(TimeOfDay reminderTime) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Notification permissions not granted');
    }

    // Cancel any existing notifications first
    await cancelAllNotifications();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        'Daily Reminders',
        channelDescription: 'Channel for daily habit reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      ),
    );

    await _localNotifications.zonedSchedule(
      0,
      'Daily Habit Reminder',
      'Don\'t forget to check your habits for today!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void handleFCMMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap when app is in background
      debugPrint('Notification opened: ${message.data}');
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'push_notifications',
        'Push Notifications',
        channelDescription: 'Channel for push notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  Future<void> sendTestNotification() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Notification permissions not granted');
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_notification',
        'Test Notifications',
        channelDescription: 'Channel for test notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      ),
    );

    await _localNotifications.show(
      999,  // Using a unique ID for test notifications
      'Test Notification',
      'This is a test notification from ContHabit!',
      notificationDetails,
    );
  }
} 