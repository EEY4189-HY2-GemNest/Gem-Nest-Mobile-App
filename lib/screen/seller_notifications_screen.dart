import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/providers/seller_notification_provider.dart';
import 'package:gemnest_mobile_app/screen/notification_settings_screen.dart';
import 'package:gemnest_mobile_app/widget/seller_notification_widgets.dart';
import 'package:provider/provider.dart';

/// Seller Notifications Screen - Full notifications view for sellers
class SellerNotificationsScreen extends StatefulWidget {
  const SellerNotificationsScreen({super.key});

  @override
  State<SellerNotificationsScreen> createState() =>
      _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState extends State<SellerNotificationsScreen> {
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
                      const NotificationSettingsScreen(userRole: 'seller'),
                ),
              );
            },
          ),
        ],
      ),
      body: ChangeNotifierProvider(
        create: (_) => SellerNotificationProvider()..initialize(),
        child: Column(
          children: [
            // Pending Approvals Card
            const SellerPendingApprovalsCard(),

            // Filter Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SellerNotificationFilterBar(
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
            ),

            // Notifications List
            Expanded(
              child: Consumer<SellerNotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<dynamic> notifications;
                  if (_selectedFilter == 'unread') {
                    notifications = provider.getUnreadNotifications();
                  } else if (_selectedFilter == 'approvals') {
                    notifications = provider.getApprovalNotifications();
                  } else if (_selectedFilter == 'bids') {
                    notifications = provider.getBidNotifications();
                  } else if (_selectedFilter == 'orders') {
                    notifications = provider.getOrderNotifications();
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
                      return SellerNotificationTile(
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
            const SellerNotificationActionsBar(),
          ],
        ),
      ),
    );
  }
}
