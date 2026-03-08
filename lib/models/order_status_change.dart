import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Model to track order status changes over time
class OrderStatusChange {
  final String id; // Unique identifier for this status change
  final String orderId;
  final String previousStatus;
  final String newStatus;
  final DateTime changedAt;
  final String? comment; // Optional comment from seller
  final String changedBy; // User ID who made the change

  OrderStatusChange({
    required this.id,
    required this.orderId,
    required this.previousStatus,
    required this.newStatus,
    required this.changedAt,
    this.comment,
    required this.changedBy,
  });

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'changedAt': Timestamp.fromDate(changedAt),
      'comment': comment,
      'changedBy': changedBy,
    };
  }

  /// Create from Firestore map
  factory OrderStatusChange.fromMap(Map<String, dynamic> map) {
    return OrderStatusChange(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      previousStatus: map['previousStatus'] ?? '',
      newStatus: map['newStatus'] ?? '',
      changedAt: (map['changedAt'] is Timestamp)
          ? (map['changedAt'] as Timestamp).toDate()
          : DateTime.parse(
              map['changedAt'] as String? ?? DateTime.now().toString()),
      comment: map['comment'],
      changedBy: map['changedBy'] ?? '',
    );
  }

  /// Format the change date-time for display
  String getFormattedDateTime() {
    return DateFormat('MMM dd, yyyy HH:mm').format(changedAt);
  }

  /// Get emoji icon for status
  static String getStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏳';
      case 'processing':
        return '⚙️';
      case 'shipped':
        return '📦';
      case 'delivered':
        return '✓';
      case 'cancelled':
        return '✕';
      case 'confirmed':
        return '✓';
      default:
        return '→';
    }
  }
}
