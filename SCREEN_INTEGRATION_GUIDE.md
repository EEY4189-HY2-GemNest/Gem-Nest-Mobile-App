# Firebase Push Notifications - Screen Integration Guide

## How to Integrate Notifications into Your App Screens

This guide shows you exactly how to add notification support to your existing screens.

---

## 🎯 For Buyer Screens

### 1. Add to Buyer Home/Dashboard

```dart
import 'package:gemnest_mobile_app/providers/buyer_notification_provider.dart';
import 'package:gemnest_mobile_app/widget/buyer_notification_widgets.dart';

class BuyerHomeScreen extends StatefulWidget {
  @override
  _BuyerHomeScreenState createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BuyerNotificationProvider()..initialize(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('GemNest'),
          actions: [
            // Add notification bell with badge
            Consumer<BuyerNotificationProvider>(
              builder: (context, provider, _) => Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BuyerNotificationsPage(),
                      ),
                    ),
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: BuyerNotificationBadge(size: 20),
                    ),
                ],
              ),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Your existing home screen content
    return SingleChildScrollView(
      child: Column(
        children: [
          // ... your existing widgets ...
        ],
      ),
    );
  }
}
```

### 2. Create Buyer Notifications Page

```dart
import 'package:gemnest_mobile_app/providers/buyer_notification_provider.dart';
import 'package:gemnest_mobile_app/widget/buyer_notification_widgets.dart';

class BuyerNotificationsPage extends StatefulWidget {
  @override
  _BuyerNotificationsPageState createState() => _BuyerNotificationsPageState();
}

class _BuyerNotificationsPageState extends State<BuyerNotificationsPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BuyerNotificationProvider()..initialize(),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<BuyerNotificationProvider>(
            builder: (context, provider, _) => Text(
              'Notifications (${provider.unreadCount} unread)',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationSettingsScreen(
                    userRole: 'buyer',
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter bar
            Padding(
              padding: EdgeInsets.all(8),
              child: BuyerNotificationFilterBar(
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
            ),
            // Notifications list
            Expanded(
              child: BuyerNotificationsList(
                filterCategory: _selectedFilter == 'all' ? null : _selectedFilter,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.all(16),
          child: BuyerNotificationActionsBar(),
        ),
      ),
    );
  }
}
```

### 3. Add to Buyer Bottom Navigation

```dart
class BuyerMainScreen extends StatefulWidget {
  @override
  _BuyerMainScreenState createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    BuyerHomeScreen(),
    SearchScreen(),
    BuyerNotificationsPage(),  // Add notifications page
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.notifications),
                // Add badge if needed
              ],
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
```

---

## 🎯 For Seller Screens

### 1. Add to Seller Dashboard

```dart
import 'package:gemnest_mobile_app/providers/seller_notification_provider.dart';
import 'package:gemnest_mobile_app/widget/seller_notification_widgets.dart';

class SellerDashboardScreen extends StatefulWidget {
  @override
  _SellerDashboardScreenState createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SellerNotificationProvider()..initialize(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Seller Dashboard'),
          actions: [
            // Notification bell
            Consumer<SellerNotificationProvider>(
              builder: (context, provider, _) => Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerNotificationsPage(),
                      ),
                    ),
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: SellerNotificationBadge(size: 20),
                    ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Pending approvals alert
              SellerPendingApprovalsCard(),
              
              // Dashboard stats
              SizedBox(height: 20),
              _buildDashboardStats(),
              
              SizedBox(height: 20),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Consumer<SellerNotificationProvider>(
      builder: (context, provider, _) => Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Unread Notifications'),
                    Text('${provider.unreadCount}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Pending Reviews'),
                    Text('${provider.pendingApprovalsCount}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SellerNotificationsPage(),
              ),
            ),
            child: Text('View All Notifications'),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationSettingsScreen(
                  userRole: 'seller',
                ),
              ),
            ),
            child: Text('Notification Settings'),
          ),
        ],
      ),
    );
  }
}
```

### 2. Create Seller Notifications Page

```dart
class SellerNotificationsPage extends StatefulWidget {
  @override
  _SellerNotificationsPageState createState() => _SellerNotificationsPageState();
}

class _SellerNotificationsPageState extends State<SellerNotificationsPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SellerNotificationProvider()..initialize(),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<SellerNotificationProvider>(
            builder: (context, provider, _) => Text(
              'Notifications (${provider.unreadCount})',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationSettingsScreen(
                    userRole: 'seller',
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Pending approvals card
            SellerPendingApprovalsCard(),
            
            // Filter bar
            Padding(
              padding: EdgeInsets.all(8),
              child: SellerNotificationFilterBar(
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
            ),
            
            // Notifications list
            Expanded(
              child: SellerNotificationsList(
                filterCategory: _selectedFilter == 'all' ? null : _selectedFilter,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.all(16),
          child: SellerNotificationActionsBar(),
        ),
      ),
    );
  }
}
```

---

## 🎯 For Admin Dashboard (React)

### 1. Add Notification Center to Header

```jsx
import { AdminNotificationCenter } from './components/AdminNotifications';
import { useAuth } from './hooks/useAuth';

export function AdminHeader() {
  const { user } = useAuth();

  return (
    <header className="bg-white border-b">
      <div className="flex items-center justify-between px-6 py-4">
        <h1 className="text-2xl font-bold">GemNest Admin</h1>
        
        <div className="flex items-center gap-4">
          {/* Notification Center */}
          <AdminNotificationCenter adminId={user?.id} />
          
          {/* Profile Menu */}
          <ProfileMenu />
        </div>
      </div>
    </header>
  );
}
```

### 2. Add Pending Approvals Widget to Dashboard

```jsx
import {
  AdminPendingApprovalsWidget,
  AdminSystemAlerts,
} from './components/AdminNotifications';

export function AdminDashboard() {
  return (
    <div className="p-6">
      <h2 className="text-3xl font-bold mb-6">Dashboard</h2>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        {/* System Alerts */}
        <div className="lg:col-span-3">
          <AdminSystemAlerts />
        </div>

        {/* Pending Approvals */}
        <div className="lg:col-span-1">
          <AdminPendingApprovalsWidget />
        </div>

        {/* Other dashboard widgets */}
        <div className="lg:col-span-2">
          {/* Your existing dashboard content */}
        </div>
      </div>
    </div>
  );
}
```

### 3. Create Full Notifications Page

```jsx
import {
  subscribeToAdminNotifications,
  subscribeToUnreadCount,
  markAllNotificationsAsRead,
  deleteAllNotifications,
} from './services/admin_notification_service';
import { AdminNotificationItem } from './components/AdminNotifications';
import { Bell, CheckCheck, Trash2 } from 'lucide-react';

export function AdminNotificationsPage({ adminId }) {
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [selectedFilter, setSelectedFilter] = useState('all');

  useEffect(() => {
    // Subscribe to notifications
    const unsubscribeNotifications = subscribeToAdminNotifications(
      adminId,
      setNotifications
    );

    // Subscribe to unread count
    const unsubscribeCount = subscribeToUnreadCount(
      adminId,
      setUnreadCount
    );

    return () => {
      unsubscribeNotifications?.();
      unsubscribeCount?.();
    };
  }, [adminId]);

  const filteredNotifications = notifications.filter((notif) => {
    if (selectedFilter === 'unread') return !notif.isRead;
    if (selectedFilter === 'approvals')
      return ['approval', 'rejection'].includes(notif.type);
    return true;
  });

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Bell size={28} />
          <h1 className="text-3xl font-bold">Notifications</h1>
          {unreadCount > 0 && (
            <span className="bg-red-500 text-white px-3 py-1 rounded-full text-sm font-bold">
              {unreadCount}
            </span>
          )}
        </div>

        <div className="flex gap-2">
          <button
            onClick={() => markAllNotificationsAsRead(adminId)}
            disabled={unreadCount === 0}
            className="flex items-center gap-2 px-4 py-2 bg-blue-100 text-blue-600 rounded hover:bg-blue-200 disabled:opacity-50"
          >
            <CheckCheck size={18} />
            Mark All Read
          </button>

          <button
            onClick={async () => {
              if (confirm('Delete all notifications?')) {
                await deleteAllNotifications(adminId);
              }
            }}
            className="flex items-center gap-2 px-4 py-2 bg-red-100 text-red-600 rounded hover:bg-red-200"
          >
            <Trash2 size={18} />
            Delete All
          </button>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 mb-6">
        {['all', 'unread', 'approvals'].map((filter) => (
          <button
            key={filter}
            onClick={() => setSelectedFilter(filter)}
            className={`px-4 py-2 rounded capitalize ${
              selectedFilter === filter
                ? 'bg-blue-500 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            {filter}
          </button>
        ))}
      </div>

      {/* Notifications List */}
      <div className="space-y-2">
        {filteredNotifications.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            <Bell size={48} className="mx-auto mb-4 opacity-30" />
            <p>No notifications</p>
          </div>
        ) : (
          filteredNotifications.map((notification) => (
            <AdminNotificationItem
              key={notification.id}
              notification={notification}
            />
          ))
        )}
      </div>
    </div>
  );
}
```

---

## 🔧 Complete Integration Example

Here's a minimal complete example integrating notifications:

### Flutter - Buyer Home with Notifications

```dart
class BuyerHomeScreen extends StatefulWidget {
  @override
  _BuyerHomeScreenState createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BuyerNotificationProvider()..initialize(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('GemNest'),
          actions: [
            Consumer<BuyerNotificationProvider>(
              builder: (_, provider, __) => Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      // Navigate to notifications page
                    },
                  ),
                  BuyerNotificationBadge(),
                ],
              ),
            ),
          ],
        ),
        body: ListView(
          children: [
            // Your home screen content
          ],
        ),
      ),
    );
  }
}
```

---

## 📝 Best Practices

1. **Wrap at appropriate level** - Wrap providers at the screen/route level
2. **Use Consumer for updates** - Only rebuild necessary widgets
3. **Initialize early** - Call provider.initialize() in initState
4. **Handle navigation** - Deep link to related items when notification tapped
5. **Test thoroughly** - Test all notification types and scenarios

---

## 🆘 Troubleshooting Integration

### Notifications not showing up?
- Ensure NotificationService is initialized in main.dart
- Check that user has granted notification permissions
- Verify FCM token is saved in Firestore

### Badge not updating?
- Wrap in Consumer widget
- Check that provider is initialized
- Verify Firestore listener is connected

### Settings not saving?
- Check Firestore rules allow writes
- Verify user ID is correct
- Check for errors in console

---

## ✅ Checklist Before Going Live

- [ ] Notifications integrated into all relevant screens
- [ ] Badge updates in real-time
- [ ] Notification settings accessible
- [ ] Deep linking works for notification taps
- [ ] Tested on actual devices
- [ ] Performance acceptable
- [ ] No memory leaks with providers
- [ ] Firestore rules configured

---

**Last Updated:** January 15, 2026
