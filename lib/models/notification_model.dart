import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types for the GemNest app
enum NotificationType {
  // Product/Auction Approval
  productApproved,
  productRejected,
  auctionApproved,
  auctionRejected,
  
  // Auction Activity
  bidPlaced,
  outbid,
  auctionEnded,
  auctionWon,
  auctionNotificationBuyerInterested,
  
  // Orders & Payments
  orderCreated,
  paymentReceived,
  paymentFailed,
  orderConfirmed,
  orderShipped,
  orderDelivered,
  orderCancelled,
  
  // Seller Notifications
  newBidOnAuction,
  auctionEndingsoon,
  productListingExpiring,
  lowStockAlert,
  
  // Buyer Notifications
  itemApprovedNotification,
  bidOutbidNotification,
  auctionWonNotification,
  productInStock,
  
  // General
  systemMessage,
  unknown,
}

/// Notification model for storing and managing notifications
class GemNestNotification {
  final String id;
  final String userId; // Recipient
  final String title;
  final String body;
  final NotificationType type;
  final String? imageUrl;
  final Map<String, dynamic>? data; // Additional data (productId, auctionId, etc.)
  final DateTime createdAt;
  final DateTime? readAt;
  final String? actionUrl; // Deep link to navigate
  final String? sellerId; // For seller notifications
  final String? buyerId; // For buyer notifications
  final String? auctionId;
  final String? productId;
  final String? orderId;
  final bool isRead;

  GemNestNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.imageUrl,
    this.data,
    this.readAt,
    this.actionUrl,
    this.sellerId,
    this.buyerId,
    this.auctionId,
    this.productId,
    this.orderId,
    this.isRead = false,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'data': data ?? {},
      'createdAt': createdAt,
      'readAt': readAt,
      'actionUrl': actionUrl,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'auctionId': auctionId,
      'productId': productId,
      'orderId': orderId,
      'isRead': isRead,
    };
  }

  /// Create from Firestore map
  factory GemNestNotification.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return GemNestNotification(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: _parseNotificationType(map['type'] as String?),
      imageUrl: map['imageUrl'] as String?,
      data: map['data'] as Map<String, dynamic>?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      actionUrl: map['actionUrl'] as String?,
      sellerId: map['sellerId'] as String?,
      buyerId: map['buyerId'] as String?,
      auctionId: map['auctionId'] as String?,
      productId: map['productId'] as String?,
      orderId: map['orderId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  /// Create from Firebase Messaging RemoteMessage
  factory GemNestNotification.fromRemoteMessage(RemoteMessage message) {
    return GemNestNotification(
      id: message.messageId ?? '',
      userId: message.data['userId'] ?? '',
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['type']),
      imageUrl: message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      data: message.data,
      createdAt: DateTime.now(),
      actionUrl: message.data['actionUrl'],
      sellerId: message.data['sellerId'],
      buyerId: message.data['buyerId'],
      auctionId: message.data['auctionId'],
      productId: message.data['productId'],
      orderId: message.data['orderId'],
    );
  }

  /// Parse notification type from string
  static NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.unknown;
    
    try {
      return NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
        orElse: () => NotificationType.unknown,
      );
    } catch (e) {
      return NotificationType.unknown;
    }
  }

  /// Get display icon for notification type
  IconData getIcon() {
    switch (type) {
      case NotificationType.productApproved:
      case NotificationType.auctionApproved:
      case NotificationType.itemApprovedNotification:
        return Icons.check_circle;
      case NotificationType.productRejected:
      case NotificationType.auctionRejected:
        return Icons.cancel;
      case NotificationType.bidPlaced:
      case NotificationType.newBidOnAuction:
        return Icons.gavel;
      case NotificationType.outbid:
      case NotificationType.bidOutbidNotification:
        return Icons.trending_up;
      case NotificationType.auctionEnded:
      case NotificationType.auctionWon:
      case NotificationType.auctionWonNotification:
        return Icons.emoji_events;
      case NotificationType.orderCreated:
        return Icons.shopping_bag;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.orderConfirmed:
        return Icons.verified;
      case NotificationType.orderShipped:
        return Icons.local_shipping;
      case NotificationType.orderDelivered:
        return Icons.check_circle;
      case NotificationType.orderCancelled:
        return Icons.cancel;
      case NotificationType.auctionEndingsoon:
      case NotificationType.auctionNotificationBuyerInterested:
        return Icons.schedule;
      case NotificationType.lowStockAlert:
        return Icons.warning;
      case NotificationType.productListingExpiring:
        return Icons.schedule;
      case NotificationType.productInStock:
        return Icons.inventory;
      case NotificationType.systemMessage:
        return Icons.info;
      case NotificationType.unknown:
        return Icons.notifications;
    }
  }

  /// Get color for notification type
  Color getColor() {
    switch (type) {
      case NotificationType.productApproved:
      case NotificationType.auctionApproved:
      case NotificationType.orderConfirmed:
      case NotificationType.orderDelivered:
      case NotificationType.itemApprovedNotification:
        return Colors.green;
      case NotificationType.productRejected:
      case NotificationType.auctionRejected:
      case NotificationType.orderCancelled:
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.bidPlaced:
      case NotificationType.newBidOnAuction:
      case NotificationType.auctionWon:
      case NotificationType.auctionWonNotification:
        return Colors.amber;
      case NotificationType.outbid:
      case NotificationType.bidOutbidNotification:
        return Colors.orange;
      case NotificationType.orderShipped:
        return Colors.blue;
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.lowStockAlert:
      case NotificationType.productListingExpiring:
      case NotificationType.auctionEndingoon:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Copy with method
  GemNestNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
    String? actionUrl,
    String? sellerId,
    String? buyerId,
    String? auctionId,
    String? productId,
    String? orderId,
    bool? isRead,
  }) {
    return GemNestNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      auctionId: auctionId ?? this.auctionId,
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Notification preference model
class NotificationPreferences {
  final String userId;
  final bool productApprovals;
  final bool auctionApprovals;
  final bool bidNotifications;
  final bool orderUpdates;
  final bool promotions;
  final bool systemMessages;
  final bool emailNotifications;
  final bool pushNotifications;

  NotificationPreferences({
    required this.userId,
    this.productApprovals = true,
    this.auctionApprovals = true,
    this.bidNotifications = true,
    this.orderUpdates = true,
    this.promotions = true,
    this.systemMessages = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productApprovals': productApprovals,
      'auctionApprovals': auctionApprovals,
      'bidNotifications': bidNotifications,
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'systemMessages': systemMessages,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      userId: map['userId'] as String? ?? '',
      productApprovals: map['productApprovals'] as bool? ?? true,
      auctionApprovals: map['auctionApprovals'] as bool? ?? true,
      bidNotifications: map['bidNotifications'] as bool? ?? true,
      orderUpdates: map['orderUpdates'] as bool? ?? true,
      promotions: map['promotions'] as bool? ?? true,
      systemMessages: map['systemMessages'] as bool? ?? true,
      emailNotifications: map['emailNotifications'] as bool? ?? true,
      pushNotifications: map['pushNotifications'] as bool? ?? true,
    );
  }
}

/// For compatibility - this import is needed
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
