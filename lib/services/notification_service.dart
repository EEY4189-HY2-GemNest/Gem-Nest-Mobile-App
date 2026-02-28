import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gemnest_mobile_app/models/notification_model.dart';

/// Global navigator key for handling notification taps from background/terminated
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Service for handling Firebase Cloud Messaging and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications plugin
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _createNotificationChannel();

    // Request FCM permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('FCM permission granted');

      // Get FCM token and save to Firestore
      await _setupFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Check if app was opened from a terminated state notification
      await _handleInitialMessage();
    } else {
      debugPrint('FCM permission denied');
    }

    _isInitialized = true;
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'gemnest_channel',
      'GemNest Notifications',
      description: 'Notifications from GemNest app',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Setup FCM token and save to user document + role-based collections
  Future<void> _setupFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          // Save to users collection
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Also save to buyers/sellers collection if exists
          final buyerDoc =
              await _firestore.collection('buyers').doc(user.uid).get();
          if (buyerDoc.exists) {
            await _firestore.collection('buyers').doc(user.uid).update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
          }

          final sellerDoc =
              await _firestore.collection('sellers').doc(user.uid).get();
          if (sellerDoc.exists) {
            await _firestore.collection('sellers').doc(user.uid).update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
          }

          debugPrint('FCM token saved: ${token.substring(0, 20)}...');
        }
      }
    } catch (e) {
      debugPrint('Error setting up FCM token: $e');
    }
  }

  /// Update FCM token (call after login/signup)
  Future<void> updateFCMToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Subscribe user to role-based topics
  Future<void> subscribeToRoleTopics(String role) async {
    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic(role);
      if (role == 'seller') {
        await _firebaseMessaging.subscribeToTopic('sellers');
        await _firebaseMessaging.subscribeToTopic('seller-bids');
        await _firebaseMessaging.subscribeToTopic('seller-orders');
        await _firebaseMessaging.subscribeToTopic('seller-approvals');
      } else if (role == 'buyer') {
        await _firebaseMessaging.subscribeToTopic('buyers');
        await _firebaseMessaging.subscribeToTopic('buyer-auctions');
        await _firebaseMessaging.subscribeToTopic('buyer-orders');
      } else if (role == 'admin') {
        await _firebaseMessaging.subscribeToTopic('admins');
        await _firebaseMessaging.subscribeToTopic('admin-approvals');
        await _firebaseMessaging.subscribeToTopic('admin-reports');
      }
      debugPrint('Subscribed to $role topics');
    } catch (e) {
      debugPrint('Error subscribing to role topics: $e');
    }
  }

  /// Setup FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Handle background message taps (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.notification?.title}');
      _handleMessageOpenedApp(message);
    });

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      debugPrint('FCM Token refreshed');
      _setupFCMToken();
    });
  }

  /// Handle initial message (app opened from terminated state via notification)
  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          'App opened from terminated state via notification: ${initialMessage.notification?.title}');
      // Delay navigation to ensure the app is fully loaded
      Future.delayed(const Duration(seconds: 2), () {
        _handleMessageOpenedApp(initialMessage);
      });
    }
  }

  /// Handle foreground messages with local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'gemnest_channel',
        'GemNest Notifications',
        channelDescription: 'Notifications from GemNest app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
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
        payload: jsonEncode(message.data),
      );
    }

    // Save notification to Firestore
    await _saveNotificationToFirestore(message);
  }

  /// Handle notification tap when app opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    debugPrint('Notification tapped - type: $type, data: $data');

    // Navigation will be handled by the notification screen
    // The notification is already saved in Firestore by cloud functions
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        debugPrint('Notification payload: $data');
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
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
            .doc(message.messageId ??
                DateTime.now().millisecondsSinceEpoch.toString())
            .set(notification.toMap());
      }
    } catch (e) {
      debugPrint('Error saving notification to Firestore: $e');
    }
  }

  // ========================================================================
  // CREATE NOTIFICATION (from Flutter app side - saves to Firestore)
  // This triggers cloud functions to send FCM push notifications
  // ========================================================================

  /// Create and save a notification for a user
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? imageUrl,
    String? actionUrl,
    String? sellerId,
    String? buyerId,
    String? auctionId,
    String? productId,
    String? orderId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
        'sellerId': sellerId,
        'buyerId': buyerId,
        'auctionId': auctionId,
        'productId': productId,
        'orderId': orderId,
        'data': extraData ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notificationData);

      debugPrint('Notification created for user $userId: $title');
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Send notification to all admins
  Future<void> notifyAdmins({
    required String title,
    required String body,
    required String type,
    String? actionUrl,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in adminsSnapshot.docs) {
        await createNotification(
          userId: adminDoc.id,
          title: title,
          body: body,
          type: type,
          actionUrl: actionUrl,
          extraData: extraData,
        );
      }
    } catch (e) {
      debugPrint('Error notifying admins: $e');
    }
  }

  // ========================================================================
  // NOTIFICATION PREFERENCES & MANAGEMENT
  // ========================================================================

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
      debugPrint('Error getting notification preferences: $e');
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
      debugPrint('Error updating notification preferences: $e');
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
      debugPrint('Error marking notification as read: $e');
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
      debugPrint('Error marking all notifications as read: $e');
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
      debugPrint('Error deleting notification: $e');
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
      debugPrint('Error deleting all notifications: $e');
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }
}

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handler
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Background message title: ${message.notification?.title}');
  debugPrint('Background message data: ${message.data}');

  // Save notification to Firestore in background
  try {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'userId': user.uid,
        'title': message.notification?.title ?? 'Notification',
        'body': message.notification?.body ?? '',
        'type': message.data['type'] ?? 'unknown',
        'data': message.data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'actionUrl': message.data['actionUrl'],
        'auctionId': message.data['auctionId'],
        'productId': message.data['productId'],
        'orderId': message.data['orderId'],
      });
    }
  } catch (e) {
    debugPrint('Error saving background notification: $e');
  }
}
