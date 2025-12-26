import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gemnest_mobile_app/models/notification_model.dart';

/// Service for handling Firebase Cloud Messaging and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize notification service
  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Request FCM permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carryForward: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token and save to Firestore
      await _setupFCMToken();

      // Setup message handlers
      _setupMessageHandlers();
    }
  }

  /// Setup FCM token and save to user document
  Future<void> _setupFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }).catchError((_) {
            // User doc might not exist yet, create it
            return _firestore.collection('users').doc(user.uid).set({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
        }
      }
    } catch (e) {
      print('Error setting up FCM token: $e');
    }
  }

  /// Setup FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Handle background message taps (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      print('FCM Token refreshed: $token');
      _setupFCMToken();
    });
  }

  /// Handle foreground messages with local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'gemnest_channel',
        'GemNest Notifications',
        channelDescription: 'Notifications from GemNest',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentSound: true,
        presentBadge: true,
        presentAlert: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: message.data.toString(),
      );
    }

    // Save notification to Firestore
    await _saveNotificationToFirestore(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(dynamic message) {
    if (message is RemoteMessage) {
      final actionUrl = message.data['actionUrl'];
      if (actionUrl != null) {
        // Handle deep linking here
        print('Navigate to: $actionUrl');
      }
    } else if (message is NotificationResponse) {
      // Handle local notification tap
      print('Local notification tapped: ${message.payload}');
    }
  }

  /// Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final notification = GemNestNotification.fromRemoteMessage(message)
            .copyWith(userId: user.uid);

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(message.messageId)
            .set(notification.toMap());
      }
    } catch (e) {
      print('Error saving notification to Firestore: $e');
    }
  }

  /// Get notification preferences for user
  Future<NotificationPreferences> getNotificationPreferences(
      String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .get();

      if (doc.exists) {
        return NotificationPreferences.fromMap(
            doc.data() as Map<String, dynamic>);
      }
      return NotificationPreferences(userId: userId);
    } catch (e) {
      print('Error getting notification preferences: $e');
      return NotificationPreferences(userId: userId);
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
      NotificationPreferences preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(preferences.userId)
          .collection('preferences')
          .doc('notifications')
          .set(preferences.toMap());
    } catch (e) {
      print('Error updating notification preferences: $e');
    }
  }

  /// Get user notifications stream
  Stream<List<GemNestNotification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GemNestNotification.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // Handle background message if needed
  // You can access Firestore, make API calls, etc. here
}
