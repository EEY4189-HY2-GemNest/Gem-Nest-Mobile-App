// ignore_for_file: avoid_types_as_parameter_names

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/notification_model.dart';
import 'package:gemnest_mobile_app/services/notification_service.dart';

/// Provider for managing seller-side notifications
class SellerNotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  List<GemNestNotification> _notifications = [];
  List<GemNestNotification> _pendingApprovals = [];
  int _unreadCount = 0;
  int _pendingApprovalsCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GemNestNotification> get notifications => _notifications;
  List<GemNestNotification> get pendingApprovals => _pendingApprovals;
  int get unreadCount => _unreadCount;
  int get pendingApprovalsCount => _pendingApprovalsCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadCountSubscription;
  StreamSubscription? _pendingApprovalsSubscription;

  /// Initialize seller notifications
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

      // Subscribe to pending approvals
      _setupPendingApprovalsListener(userId);

      _setLoading(false);
    } catch (e) {
      _error = 'Initialization failed: $e';
      _setLoading(false);
    }
  }

  /// Setup listener for pending approvals
  void _setupPendingApprovalsListener(String userId) {
    _pendingApprovalsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', whereIn: ['productRejected', 'auctionRejected'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _pendingApprovals = snapshot.docs
                .map((doc) => GemNestNotification.fromMap(doc.data(), doc.id))
                .toList();
            _pendingApprovalsCount = _pendingApprovals.length;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error loading pending approvals: $e');
          },
        );
  }

  /// Get seller-specific notifications (approval, bids, orders)
  List<GemNestNotification> getSellerNotifications() {
    return _notifications
        .where((n) => [
              NotificationType.productApproved,
              NotificationType.productRejected,
              NotificationType.auctionApproved,
              NotificationType.auctionRejected,
              NotificationType.newBidOnAuction,
              NotificationType.auctionEndingsoon,
              NotificationType.orderCreated,
              NotificationType.paymentReceived,
            ].contains(n.type))
        .toList();
  }

  /// Get approval notifications (approvals and rejections)
  List<GemNestNotification> getApprovalNotifications() {
    return _notifications
        .where((n) => [
              NotificationType.productApproved,
              NotificationType.productRejected,
              NotificationType.auctionApproved,
              NotificationType.auctionRejected,
            ].contains(n.type))
        .toList();
  }

  /// Get bid notifications
  List<GemNestNotification> getBidNotifications() {
    return _notifications
        .where((n) => [
              NotificationType.newBidOnAuction,
              NotificationType.auctionEndingsoon,
            ].contains(n.type))
        .toList();
  }

  /// Get order notifications
  List<GemNestNotification> getOrderNotifications() {
    return _notifications
        .where((n) => [
              NotificationType.orderCreated,
              NotificationType.paymentReceived,
            ].contains(n.type))
        .toList();
  }

  /// Get unread notifications
  List<GemNestNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
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

  /// Subscribe to seller-specific topics
  Future<void> subscribeToSellerTopics() async {
    try {
      await _notificationService.subscribeToTopic('sellers');
      await _notificationService.subscribeToTopic('seller-bids');
      await _notificationService.subscribeToTopic('seller-orders');
      await _notificationService.subscribeToTopic('seller-approvals');
    } catch (e) {
      _error = 'Failed to subscribe to topics: $e';
      notifyListeners();
    }
  }

  /// Unsubscribe from seller topics
  Future<void> unsubscribeFromSellerTopics() async {
    try {
      await _notificationService.unsubscribeFromTopic('sellers');
      await _notificationService.unsubscribeFromTopic('seller-bids');
      await _notificationService.unsubscribeFromTopic('seller-orders');
      await _notificationService.unsubscribeFromTopic('seller-approvals');
    } catch (e) {
      _error = 'Failed to unsubscribe from topics: $e';
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
    _pendingApprovalsSubscription?.cancel();
    super.dispose();
  }
}
