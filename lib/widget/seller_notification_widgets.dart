import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gemnest_mobile_app/models/notification_model.dart';
import 'package:gemnest_mobile_app/providers/seller_notification_provider.dart';

/// Seller Notification Tile Widget - displays a single notification
class SellerNotificationTile extends StatelessWidget {
  final GemNestNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SellerNotificationTile({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

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
            color: notification.isRead ? Colors.grey[100] : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey[300]!
                  : Colors.orange[200]!,
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
                        color: Colors.orange,
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

/// Seller Notifications List Widget
class SellerNotificationsList extends StatefulWidget {
  final String? filterCategory;

  const SellerNotificationsList({Key? key, this.filterCategory})
      : super(key: key);

  @override
  State<SellerNotificationsList> createState() =>
      _SellerNotificationsListState();
}

class _SellerNotificationsListState extends State<SellerNotificationsList> {
  @override
  void initState() {
    super.initState();
    // Initialize provider and subscribe to topics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SellerNotificationProvider>();
      provider.initialize();
      provider.subscribeToSellerTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SellerNotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<GemNestNotification> notifications;
        if (widget.filterCategory != null) {
          switch (widget.filterCategory) {
            case 'approvals':
              notifications = provider.getApprovalNotifications();
              break;
            case 'bids':
              notifications = provider.getBidNotifications();
              break;
            case 'orders':
              notifications = provider.getOrderNotifications();
              break;
            case 'unread':
              notifications = provider.getUnreadNotifications();
              break;
            default:
              notifications = provider.getSellerNotifications();
          }
        } else {
          notifications = provider.getSellerNotifications();
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
            return SellerNotificationTile(
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

/// Seller Notification Badge Widget
class SellerNotificationBadge extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final double size;

  const SellerNotificationBadge({
    Key? key,
    this.backgroundColor,
    this.textColor,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SellerNotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        if (count == 0) {
          return SizedBox(width: size, height: size);
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.orange,
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

/// Seller Pending Approvals Widget - Quick access to rejections
class SellerPendingApprovalsCard extends StatelessWidget {
  const SellerPendingApprovalsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SellerNotificationProvider>(
      builder: (context, provider, _) {
        if (provider.pendingApprovalsCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Reviews',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    Text(
                      '${provider.pendingApprovalsCount} item(s) need your attention',
                      style: TextStyle(fontSize: 12, color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate to rejections/pending items
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                ),
                child: const Text('View'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Seller Notification Filter Bar Widget
class SellerNotificationFilterBar extends StatefulWidget {
  final Function(String) onFilterChanged;

  const SellerNotificationFilterBar({
    Key? key,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<SellerNotificationFilterBar> createState() =>
      _SellerNotificationFilterBarState();
}

class _SellerNotificationFilterBarState
    extends State<SellerNotificationFilterBar> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filters = ['all', 'unread', 'approvals', 'bids', 'orders'];

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

/// Seller Notification Actions Bar Widget
class SellerNotificationActionsBar extends StatelessWidget {
  const SellerNotificationActionsBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SellerNotificationProvider>(
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
      BuildContext context, SellerNotificationProvider provider) {
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
