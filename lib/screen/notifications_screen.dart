import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gemnest_mobile_app/models/notification_model.dart';
import 'package:gemnest_mobile_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationService _notificationService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _filterType = 'all'; // all, unread, approvals, orders, bids

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(userId),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _buildNotificationsList(userId),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String userId) {
    return AppBar(
      title: const Text(
        'Notifications',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.blue[700],
      elevation: 0,
      centerTitle: true,
      actions: [
        StreamBuilder<int>(
          stream: _notificationService.getUnreadNotificationsCount(userId),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.done_all, color: Colors.white, size: 24),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _markAllAsRead(userId),
              tooltip: 'Mark all as read',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: () => _showDeleteAllDialog(userId),
          tooltip: 'Delete all',
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Unread', 'unread'),
            const SizedBox(width: 8),
            _buildFilterChip('Approvals', 'approvals'),
            const SizedBox(width: 8),
            _buildFilterChip('Orders', 'orders'),
            const SizedBox(width: 8),
            _buildFilterChip('Bids', 'bids'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filterType == value,
      onSelected: (selected) {
        setState(() => _filterType = value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(
        color: _filterType == value ? Colors.blue[700] : Colors.grey[700],
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: _filterType == value ? Colors.blue[700]! : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildNotificationsList(String userId) {
    return StreamBuilder<List<GemNestNotification>>(
      stream: _notificationService.getNotificationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data!;
        final filteredNotifications = _filterNotifications(notifications);

        return ListView.separated(
          padding: const EdgeInsets.all(8.0),
          itemCount: filteredNotifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final notification = filteredNotifications[index];
            return _buildNotificationCard(notification, userId);
          },
        );
      },
    );
  }

  List<GemNestNotification> _filterNotifications(
      List<GemNestNotification> notifications) {
    switch (_filterType) {
      case 'unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'approvals':
        return notifications
            .where((n) =>
                n.type == NotificationType.productApproved ||
                n.type == NotificationType.productRejected ||
                n.type == NotificationType.auctionApproved ||
                n.type == NotificationType.auctionRejected)
            .toList();
      case 'orders':
        return notifications
            .where((n) =>
                n.type == NotificationType.orderCreated ||
                n.type == NotificationType.orderConfirmed ||
                n.type == NotificationType.orderShipped ||
                n.type == NotificationType.orderDelivered)
            .toList();
      case 'bids':
        return notifications
            .where((n) =>
                n.type == NotificationType.bidPlaced ||
                n.type == NotificationType.outbid ||
                n.type == NotificationType.auctionWon)
            .toList();
      default:
        return notifications;
    }
  }

  Widget _buildNotificationCard(GemNestNotification notification, String userId) {
    final backgroundColor =
        notification.isRead ? Colors.white : Colors.blue[50];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: backgroundColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: notification.getColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            notification.getIcon(),
            color: notification.getColor(),
            size: 28,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!notification.isRead)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(height: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Delete'),
                  onTap: () => _deleteNotification(notification.id, userId),
                ),
              ],
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification, userId),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  void _handleNotificationTap(GemNestNotification notification, String userId) {
    // Mark as read
    _notificationService.markNotificationAsRead(userId, notification.id);

    // Handle deep linking based on actionUrl
    if (notification.actionUrl != null) {
      // TODO: Implement deep linking based on actionUrl
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigate to: ${notification.actionUrl}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    await _notificationService.markAllNotificationsAsRead(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteNotification(String notificationId, String userId) async {
    await _notificationService.deleteNotification(userId, notificationId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteAllDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _notificationService.deleteAllNotifications(userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
