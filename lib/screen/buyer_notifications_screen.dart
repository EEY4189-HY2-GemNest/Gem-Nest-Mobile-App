import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/providers/buyer_notification_provider.dart';
import 'package:gemnest_mobile_app/screen/notification_settings_screen.dart';
import 'package:gemnest_mobile_app/widget/buyer_notification_widgets.dart';
import 'package:provider/provider.dart';

/// Buyer Notifications Screen - Full notifications view for buyers
class BuyerNotificationsScreen extends StatefulWidget {
  const BuyerNotificationsScreen({super.key});

  @override
  State<BuyerNotificationsScreen> createState() =>
      _BuyerNotificationsScreenState();
}

class _BuyerNotificationsScreenState extends State<BuyerNotificationsScreen> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const NotificationSettingsScreen(userRole: 'buyer'),
                ),
              );
            },
          ),
        ],
      ),
      body: ChangeNotifierProvider(
        create: (_) => BuyerNotificationProvider()..initialize(),
        child: Column(
          children: [
            // Filter Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BuyerNotificationFilterBar(
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
            ),

            // Notifications List
            Expanded(
              child: Consumer<BuyerNotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<dynamic> notifications;
                  if (_selectedFilter == 'unread') {
                    notifications = provider.getUnreadNotifications();
                  } else if (_selectedFilter != null &&
                      _selectedFilter != 'all') {
                    notifications =
                        provider.getNotificationsByCategory(_selectedFilter!);
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
                            'No notifications',
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
                        },
                        onDelete: () =>
                            provider.deleteNotification(notification.id),
                      );
                    },
                  );
                },
              ),
            ),

            // Actions Bar
            const BuyerNotificationActionsBar(),
          ],
        ),
      ),
    );
  }
}
