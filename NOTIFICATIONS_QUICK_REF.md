# Firebase Push Notifications - Developer Quick Reference

## 🚀 Quick Start

### Initialize Notifications (Mobile)
```dart
// Automatically happens in main.dart
await NotificationService().initialize();
```

### Buyer Side
```dart
// Setup in your widget
ChangeNotifierProvider(
  create: (_) => BuyerNotificationProvider()..initialize(),
  child: YourWidget(),
)

// Show notification list
BuyerNotificationsList()

// Show badge
BuyerNotificationBadge()

// Mark as read
context.read<BuyerNotificationProvider>()
  .markAsRead(notificationId);

// Get unread count
provider.unreadCount
```

### Seller Side
```dart
// Setup in your widget
ChangeNotifierProvider(
  create: (_) => SellerNotificationProvider()..initialize(),
  child: YourWidget(),
)

// Show notifications
SellerNotificationsList(filterCategory: 'approvals')

// Get pending approvals
provider.pendingApprovalsCount
provider.pendingApprovals

// Subscribe to seller topics
provider.subscribeToSellerTopics()
```

### Admin Dashboard (Web)
```jsx
// Show notification center
<AdminNotificationCenter adminId={adminId} />

// Show pending approvals
<AdminPendingApprovalsWidget />

// Show system alerts
<AdminSystemAlerts />
```

---

## 📁 File Structure

```
lib/
├── models/
│   └── notification_model.dart          ✅ Models & types
├── services/
│   └── notification_service.dart        ✅ Core FCM service
├── providers/
│   ├── buyer_notification_provider.dart ✅ Buyer logic
│   └── seller_notification_provider.dart ✅ Seller logic
├── widget/
│   ├── buyer_notification_widgets.dart  ✅ Buyer UI
│   ├── seller_notification_widgets.dart ✅ Seller UI
│   └── notification_settings_screen.dart ✅ Settings UI
└── main.dart                            ✅ Init code

admin-dashboard/
├── src/
│   ├── services/
│   │   └── admin_notification_service.js ✅ Admin service
│   └── components/
│       └── AdminNotifications.jsx        ✅ Admin UI
└── public/
    └── firebase-messaging-sw.js          ✅ Service worker

functions/
└── notifications.js                      ✅ Cloud functions
```

---

## 🔔 Notification Types Reference

### Buyer Notifications
```dart
NotificationType.orderCreated
NotificationType.orderConfirmed
NotificationType.orderShipped
NotificationType.orderDelivered
NotificationType.orderCancelled
NotificationType.bidPlaced
NotificationType.outbid
NotificationType.auctionWon
NotificationType.productApproved
NotificationType.paymentFailed
```

### Seller Notifications
```dart
NotificationType.productApproved
NotificationType.productRejected
NotificationType.auctionApproved
NotificationType.auctionRejected
NotificationType.newBidOnAuction
NotificationType.auctionEndingsoon
NotificationType.orderCreated
NotificationType.paymentReceived
NotificationType.productListingExpiring
NotificationType.lowStockAlert
```

---

## 🔧 Common Tasks

### Get All Notifications
```dart
final provider = context.read<BuyerNotificationProvider>();
List<GemNestNotification> all = provider.notifications;
```

### Filter Notifications
```dart
// By category
provider.getNotificationsByCategory('orders')
provider.getNotificationsByCategory('bids')
provider.getNotificationsByCategory('approvals')

// By type
provider.getNotificationsByType(NotificationType.orderCreated)

// Unread only
provider.getUnreadNotifications()
```

### Mark Notifications
```dart
// Single
await provider.markAsRead(notificationId);

// All
await provider.markAllAsRead();
```

### Delete Notifications
```dart
// Single
await provider.deleteNotification(notificationId);

// All
await provider.deleteAllNotifications();
```

### Get Preferences
```dart
final prefs = await provider.getPreferences();
print(prefs.enableNotifications);
print(prefs.quietHoursEnabled);
```

### Update Preferences
```dart
final updated = NotificationPreferences(
  userId: userId,
  enableNotifications: true,
  orderNotifications: true,
  soundEnabled: true,
  // ... other settings
);
await provider.updatePreferences(updated);
```

---

## 🌐 Admin API Endpoints

### Get Pending Items
```javascript
const pending = await getPendingNotifications();
// Returns: [{id, type, title, createdAt, ...}]
```

### Subscribe to Notifications
```javascript
const unsubscribe = subscribeToAdminNotifications(
  adminId,
  (notifications) => {
    console.log('Notifications:', notifications);
  }
);
```

### Mark as Read
```javascript
await markNotificationAsRead(adminId, notificationId);
```

### Get Statistics
```javascript
const stats = await getApprovalStatistics();
// Returns: {pendingProducts, pendingAuctions, total}
```

### System Alerts
```javascript
const unsubscribe = subscribeToSystemAlerts((alerts) => {
  console.log('System alerts:', alerts);
});
```

---

## 🧪 Testing Notifications

### Manual Test - Product Approval
```bash
# Update Firestore
firebase firestore:set \
  "projects/YOUR_PROJECT/databases/(default)/documents/products/TEST_ID" \
  '{"approvalStatus":"approved","title":"Test Product"}'
```

### Manual Test - Order Creation
```bash
firebase firestore:set \
  "projects/YOUR_PROJECT/databases/(default)/documents/orders/TEST_ID" \
  '{"status":"created","userId":"buyer123","sellerId":"seller456"}'
```

### Check FCM Token
```javascript
// In browser console
const token = await firebase.messaging().getToken();
console.log('FCM Token:', token);
```

### Monitor Cloud Functions
```bash
firebase functions:log --region=us-central1
```

---

## ⚙️ Configuration

### Notification Channels (Android)
Default channel ID: `'gemnest_channel'`

Customize in `notification_service.dart`:
```dart
AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
  'gemnest_channel',          // ID
  'GemNest Notifications',    // Name
  importance: Importance.max,
  priority: Priority.high,
);
```

### Quiet Hours (Preferences)
```dart
NotificationPreferences(
  quietHoursEnabled: true,
  quietHoursStart: '22:00',   // 10 PM
  quietHoursEnd: '08:00',     // 8 AM
)
```

### Notification Frequency
```dart
notificationFrequency: 'instant'  // or 'hourly' or 'daily'
```

---

## 🐛 Debugging Tips

### Check if Notifications Initialized
```dart
final service = NotificationService();
// Should be initialized in main.dart
```

### Verify FCM Token
```dart
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

### Check Notification Permissions
```dart
final settings = await FirebaseMessaging.instance
  .requestPermission();
print('Authorization: ${settings.authorizationStatus}');
```

### Monitor Firestore Writes
```dart
// Check if notification saved
db.collection('users')
  .doc(userId)
  .collection('notifications')
  .snapshots()
  .listen((snapshot) {
    print('Notifications: ${snapshot.docs.length}');
  });
```

### View Cloud Function Logs
Firebase Console → Cloud Functions → Logs

---

## 📋 Checklist Before Production

- [ ] Firebase project configured
- [ ] Android app registered with Firebase
- [ ] iOS app registered with Firebase
- [ ] Web app registered with Firebase
- [ ] Cloud Functions deployed
- [ ] Firestore security rules set
- [ ] FCM tokens saved to users
- [ ] Test all notification types
- [ ] Test on real devices
- [ ] Monitor production logs
- [ ] Set up alerting
- [ ] Document custom configurations
- [ ] Train support team

---

## 🔐 Security

### Firestore Rules
```javascript
// Only users can read their notifications
match /users/{userId}/notifications/{doc=**} {
  allow read: if request.auth.uid == userId;
  allow write: if false;
}
```

### Cloud Function Best Practices
- Validate user roles
- Check permissions
- Log sensitive operations
- Use try-catch
- Rate limit if needed

---

## 🚨 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Token is null | Check notification permissions granted |
| Notifications not saved | Verify Firestore rules allow writes |
| Cloud function not triggering | Check Firestore trigger condition |
| Web push not working | Verify service worker registered + HTTPS |
| Duplicates appearing | Add deduplication check |

---

## 📚 Related Files

- `FIREBASE_PUSH_NOTIFICATIONS_COMPLETE.md` - Full guide
- `FIREBASE_PUSH_NOTIFICATIONS_GUIDE.md` - Setup guide
- `functions/notifications.js` - Cloud function implementations
- `lib/services/notification_service.dart` - Core service

---

**Last Updated:** January 15, 2026
**Version:** 2.0 - Complete Implementation
