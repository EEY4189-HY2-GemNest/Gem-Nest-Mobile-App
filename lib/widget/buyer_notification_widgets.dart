import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/notification_model.dart';
import 'package:gemnest_mobile_app/providers/buyer_notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Buyer Notification Tile Widget - displays a single notification
class BuyerNotificationTile extends StatelessWidget {
  final GemNestNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BuyerNotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.7),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.grey[100] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  notification.isRead ? Colors.grey[300]! : Colors.blue[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    notification.getIcon(),
                    color: notification.getColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}

/// Buyer Notifications List Widget
class BuyerNotificationsList extends StatefulWidget {
  final String? filterCategory;

  const BuyerNotificationsList({super.key, this.filterCategory});

  @override
  State<BuyerNotificationsList> createState() => _BuyerNotificationsListState();
}

class _BuyerNotificationsListState extends State<BuyerNotificationsList> {
  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuyerNotificationProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerNotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<GemNestNotification> notifications;
        if (widget.filterCategory != null) {
          notifications =
              provider.getNotificationsByCategory(widget.filterCategory!);
        } else {
          notifications = provider.notifications;
        }

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none,
                    size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return BuyerNotificationTile(
              notification: notification,
              onTap: () {
                if (!notification.isRead) {
                  provider.markAsRead(notification.id);
                }
                // Handle navigation if actionUrl exists
                if (notification.actionUrl != null) {
                  _navigateToAction(context, notification.actionUrl!);
                }
              },
              onDelete: () => provider.deleteNotification(notification.id),
            );
          },
        );
      },
    );
  }

  void _navigateToAction(BuildContext context, String actionUrl) {
    // TODO: Implement deep linking based on actionUrl
    print('Navigate to: $actionUrl');
  }
}

/// Buyer Notification Badge Widget
class BuyerNotificationBadge extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final double size;

  const BuyerNotificationBadge({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerNotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        if (count == 0) {
          return SizedBox(width: size, height: size);
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.red,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: Center(
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: size / 2.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Buyer Notification Filter Bar Widget
class BuyerNotificationFilterBar extends StatefulWidget {
  final Function(String) onFilterChanged;

  const BuyerNotificationFilterBar({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<BuyerNotificationFilterBar> createState() =>
      _BuyerNotificationFilterBarState();
}

class _BuyerNotificationFilterBarState
    extends State<BuyerNotificationFilterBar> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filters = ['all', 'unread', 'orders', 'bids', 'approvals'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map((filter) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(filter.toUpperCase()),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      widget.onFilterChanged(filter);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Buyer Notification Actions Bar Widget
class BuyerNotificationActionsBar extends StatelessWidget {
  const BuyerNotificationActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerNotificationProvider>(
      builder: (context, provider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: provider.unreadCount > 0
                  ? () => provider.markAllAsRead()
                  : null,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark All Read'),
            ),
            ElevatedButton.icon(
              onPressed: provider.notifications.isNotEmpty
                  ? () => _showDeleteAllDialog(context, provider)
                  : null,
              icon: const Icon(Icons.delete),
              label: const Text('Delete All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAllDialog(
      BuildContext context, BuyerNotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications?'),
        content: const Text(
            'This action cannot be undone. All notifications will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAllNotifications();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
