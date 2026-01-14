import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/notification_model.dart';
import 'package:gemnest_mobile_app/services/notification_service.dart';

/// Provider for managing buyer-side notifications
class BuyerNotificationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  List<GemNestNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GemNestNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadCountSubscription;

  /// Initialize buyer notifications
  Future<void> initialize() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _setLoading(true);
    try {
      // Subscribe to notifications stream
      _notificationsSubscription =
          _notificationService.getNotificationsStream(userId).listen(
        (notifications) {
          _notifications = notifications;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Failed to load notifications: $e';
          notifyListeners();
        },
      );

      // Subscribe to unread count stream
      _unreadCountSubscription =
          _notificationService.getUnreadNotificationsCount(userId).listen(
        (count) {
          _unreadCount = count;
          notifyListeners();
        },
      );

      _setLoading(false);
    } catch (e) {
      _error = 'Initialization failed: $e';
      _setLoading(false);
    }
  }

  /// Get notifications by type (for filtering)
  List<GemNestNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<GemNestNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Get notifications by category (e.g., "Orders", "Bids", "Approvals")
  List<GemNestNotification> getNotificationsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'orders':
        return _notifications
            .where((n) => [
                  NotificationType.orderCreated,
                  NotificationType.orderConfirmed,
                  NotificationType.orderShipped,
                  NotificationType.orderDelivered,
                  NotificationType.orderCancelled,
                ].contains(n.type))
            .toList();
      case 'bids':
        return _notifications
            .where((n) => [
                  NotificationType.bidPlaced,
                  NotificationType.outbid,
                  NotificationType.auctionWon,
                ].contains(n.type))
            .toList();
      case 'approvals':
        return _notifications
            .where((n) => [
                  NotificationType.productApproved,
                  NotificationType.auctionApproved,
                ].contains(n.type))
            .toList();
      case 'all':
      default:
        return _notifications;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _notificationService.markNotificationAsRead(userId, notificationId);
    } catch (e) {
      _error = 'Failed to mark notification as read: $e';
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _notificationService.markAllNotificationsAsRead(userId);
    } catch (e) {
      _error = 'Failed to mark all notifications as read: $e';
      notifyListeners();
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _notificationService.deleteNotification(userId, notificationId);
    } catch (e) {
      _error = 'Failed to delete notification: $e';
      notifyListeners();
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _notificationService.deleteAllNotifications(userId);
    } catch (e) {
      _error = 'Failed to delete all notifications: $e';
      notifyListeners();
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return NotificationPreferences(userId: '');
    }

    try {
      return await _notificationService.getNotificationPreferences(userId);
    } catch (e) {
      _error = 'Failed to get preferences: $e';
      notifyListeners();
      return NotificationPreferences(userId: userId);
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      await _notificationService.updateNotificationPreferences(preferences);
    } catch (e) {
      _error = 'Failed to update preferences: $e';
      notifyListeners();
    }
  }

  /// Subscribe to topic (e.g., category-based notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _notificationService.subscribeToTopic(topic);
    } catch (e) {
      _error = 'Failed to subscribe to topic: $e';
      notifyListeners();
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _notificationService.unsubscribeFromTopic(topic);
    } catch (e) {
      _error = 'Failed to unsubscribe from topic: $e';
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}
