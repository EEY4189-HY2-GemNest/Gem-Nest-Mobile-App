# Firebase Push Notifications - Complete Integration Guide

## Overview
This guide covers the complete Firebase push notification system for GemNest, including mobile (buyer & seller) and web (admin) implementations.

## Table of Contents
1. [Architecture](#architecture)
2. [Setup Instructions](#setup-instructions)
3. [Mobile App Integration (Flutter)](#mobile-app-integration)
4. [Admin Dashboard Integration (React)](#admin-dashboard-integration)
5. [Cloud Functions](#cloud-functions)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────┐
│         Firebase Cloud Messaging (FCM)          │
└────────────┬───────────────────────────────────┘
             │
    ┌────────┴─────────┬──────────────┐
    │                  │              │
    v                  v              v
┌─────────┐      ┌─────────┐    ┌──────────┐
│  Mobile │      │  Mobile │    │   Admin  │
│  Buyer  │      │  Seller │    │ Dashboard│
│  App    │      │  App    │    │  (Web)   │
└─────────┘      └─────────┘    └──────────┘
```

### Notification Flow

1. **Trigger Event**: Product approval, order created, bid placed, etc.
2. **Cloud Function**: Firebase Cloud Function detects the change
3. **Token Retrieval**: Gets user's FCM token from Firestore
4. **Message Sending**: Sends push notification via FCM
5. **Display**: Device displays notification with local notifications library
6. **Storage**: Notification saved to user's notifications collection for history

---

## Setup Instructions

### 1. Firebase Project Setup

#### Enable Required Services
```
1. Go to Firebase Console
2. Enable the following:
   - Cloud Firestore
   - Cloud Functions
   - Cloud Messaging
   - Authentication
   - Storage
3. Create Android, iOS, and Web apps in your Firebase project
```

#### Create Firestore Collections

Create these collections with appropriate permissions:

```
├── users/{userId}
│   ├── fcmToken (string)
│   ├── fcmTokenUpdatedAt (timestamp)
│   ├── role (string): 'buyer', 'seller', 'admin'
│   └── notifications (subcollection)
│       ├── {notificationId}
│       ├── title
│       ├── body
│       ├── type
│       ├── createdAt
│       ├── isRead
│       └── ...
│
├── admins/{adminId}
│   ├── fcmToken (string)
│   └── notifications (subcollection)
│
├── products/{productId}
│   ├── approvalStatus
│   └── ...
│
├── auctions/{auctionId}
│   ├── approvalStatus
│   └── ...
│
├── orders/{orderId}
│   ├── status
│   └── ...
│
└── payments/{paymentId}
    ├── paymentStatus
    └── ...
```

### 2. Environment Variables

#### Flutter App (.env)
```
FIREBASE_API_KEY=YOUR_API_KEY
FIREBASE_AUTH_DOMAIN=YOUR_AUTH_DOMAIN
FIREBASE_PROJECT_ID=YOUR_PROJECT_ID
FIREBASE_STORAGE_BUCKET=YOUR_STORAGE_BUCKET
FIREBASE_MESSAGING_SENDER_ID=YOUR_MESSAGING_SENDER_ID
FIREBASE_APP_ID=YOUR_APP_ID
```

#### React Admin Dashboard (.env)
```
VITE_FIREBASE_API_KEY=YOUR_API_KEY
VITE_FIREBASE_AUTH_DOMAIN=YOUR_AUTH_DOMAIN
VITE_FIREBASE_PROJECT_ID=YOUR_PROJECT_ID
VITE_FIREBASE_STORAGE_BUCKET=YOUR_STORAGE_BUCKET
VITE_FIREBASE_MESSAGING_SENDER_ID=YOUR_MESSAGING_SENDER_ID
VITE_FIREBASE_APP_ID=YOUR_APP_ID
VITE_FIREBASE_VAPID_KEY=YOUR_VAPID_KEY
```

### 3. Android Configuration

Edit `android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.google.firebase:firebase-messaging'
}
```

### 4. iOS Configuration

Follow Firebase iOS setup for:
- APNs certificate upload
- Configure iOS capabilities

---

## Mobile App Integration (Flutter)

### 1. Initialization

The notification service is automatically initialized in `main.dart`:

```dart
await NotificationService().initialize();
```

### 2. Buyer Implementation

#### Using Buyer Notification Provider

```dart
// In your widget
class BuyerNotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BuyerNotificationProvider()..initialize(),
      child: Consumer<BuyerNotificationProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Notifications (${provider.unreadCount})'),
            ),
            body: BuyerNotificationsList(),
          );
        },
      ),
    );
  }
}
```

#### Show Notification Badge

```dart
// In AppBar or navigation
Stack(
  children: [
    Icon(Icons.notifications),
    BuyerNotificationBadge(),
  ],
)
```

### 3. Seller Implementation

#### Using Seller Notification Provider

```dart
class SellerNotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SellerNotificationProvider()..initialize(),
      child: Consumer<SellerNotificationProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(title: Text('Notifications')),
            body: Column(
              children: [
                SellerPendingApprovalsCard(),
                Expanded(child: SellerNotificationsList()),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### 4. Notification Settings

```dart
// Navigate to settings
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NotificationSettingsScreen(
      userRole: 'buyer', // or 'seller'
    ),
  ),
);
```

---

## Admin Dashboard Integration (React)

### 1. Register FCM Token

```javascript
import { registerAdminFCMToken } from './services/admin_notification_service';

// On admin login
useEffect(() => {
  if (adminId) {
    registerAdminFCMToken(adminId);
  }
}, [adminId]);
```

### 2. Add Notification Center to Layout

```jsx
import { AdminNotificationCenter } from './components/AdminNotifications';

export function AdminLayout({ adminId }) {
  return (
    <header>
      <nav>
        {/* ... other nav items ... */}
        <AdminNotificationCenter adminId={adminId} />
      </nav>
    </header>
  );
}
```

### 3. Display Pending Approvals Dashboard

```jsx
import { AdminPendingApprovalsWidget } from './components/AdminNotifications';

export function AdminDashboard() {
  return (
    <div className="grid gap-4">
      <AdminPendingApprovalsWidget />
      {/* ... other dashboard widgets ... */}
    </div>
  );
}
```

### 4. Service Worker Setup

The service worker is located at:
```
admin-dashboard/public/firebase-messaging-sw.js
```

Update the Firebase config in the service worker with your credentials.

---

## Cloud Functions

### 1. Deploy Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. Available Functions

#### Product Approval Notifications
- `onProductApproved`: Notifies seller when product is approved
- `onProductRejected`: Notifies seller when product is rejected

#### Auction Approval Notifications
- `onAuctionApproved`: Notifies seller when auction is approved
- `onAuctionRejected`: Notifies seller when auction is rejected

#### Bid Notifications
- `onNewBid`: Notifies seller of new bid, notifies previous bidder they were outbid

#### Order Notifications
- `onOrderCreated`: Notifies buyer and seller
- `onOrderStatusChanged`: Notifies buyer of status updates
- `onPaymentReceived`: Notifies seller of payment received

#### Auction Events
- `notifyAuctionEnded`: Notifies winner and seller when auction ends
- `notifyAuctionEndingSoon`: Notifies current bidder 30 minutes before end

#### Admin Notifications
- `notifyAdminsNewApprovalNeeded`: Notifies all admins of new products/auctions needing review

#### Broadcast
- `broadcastProductApprovedByCategory`: Notifies interested users of new approved products

### 3. Function Triggers

All functions are automatically triggered by Firestore changes:

```javascript
// Example: Product approval trigger
exports.onProductApproved = functions.firestore
    .document('products/{productId}')
    .onUpdate(async (change, context) => {
        // Function logic
    });
```

---

## Testing

### 1. Test Notifications in Development

#### Enable Emulator (Optional)
```bash
firebase emulators:start
```

#### Manual Testing
1. Open your app
2. Grant notification permissions
3. Create test events (product, order, auction)
4. Verify notifications appear

### 2. Test Specific Notification Types

#### Test Product Approval
```bash
# Using Firebase CLI
firebase firestore:set projects/YOUR_PROJECT/databases/(default)/documents/products/TEST_PRODUCT '{"approvalStatus":"approved"}'
```

#### Test Order Creation
```bash
firebase firestore:set projects/YOUR_PROJECT/databases/(default)/documents/orders/TEST_ORDER '{"status":"created"}'
```

### 3. Check FCM Tokens

In Firebase Console:
1. Go to Firestore Database
2. Navigate to `users/{userId}`
3. Verify `fcmToken` exists

### 4. Monitor Cloud Functions

In Firebase Console:
1. Go to Cloud Functions
2. Check Logs and Performance
3. Verify functions are executing successfully

---

## Notification Types

### For Buyers
```
- orderCreated: New order placed
- orderConfirmed: Order confirmed by seller
- orderShipped: Order is shipped
- orderDelivered: Order delivered
- orderCancelled: Order cancelled
- paymentFailed: Payment processing failed
- bidPlaced: Bid placed in auction
- outbid: Outbid by another user
- auctionWon: Won an auction
- productApproved: Product in interested category approved
- itemApprovedNotification: New item in category approved
```

### For Sellers
```
- productApproved: Product approved
- productRejected: Product rejected
- auctionApproved: Auction approved
- auctionRejected: Auction rejected
- newBidOnAuction: New bid on their auction
- auctionEndingSoon: Auction ending in 30 minutes
- orderCreated: New order from buyer
- paymentReceived: Payment received
- productListingExpiring: Product listing expiring soon
- lowStockAlert: Stock running low
```

### For Admins
```
- approvalNotification: New item needs approval
- systemMessage: System alerts and updates
```

---

## Customization

### 1. Modify Notification Content

Edit `lib/services/notification_service.dart` to customize:
- Notification channel settings
- Sound/vibration patterns
- Display formatting

### 2. Add Custom Notification Types

1. Add to `NotificationType` enum in `notification_model.dart`
2. Add icon/color mapping in `getIcon()` and `getColor()`
3. Update cloud functions to send new type

### 3. Change Notification Display

Modify `BuyerNotificationTile` and `SellerNotificationTile` widgets for custom styling.

---

## Best Practices

1. **Token Management**
   - FCM tokens refresh automatically
   - Always have a valid token before sending notifications

2. **Notification Preferences**
   - Let users control notification types
   - Respect quiet hours
   - Support notification frequency (instant/digest)

3. **Error Handling**
   - Log failed notification sends
   - Implement retry logic
   - Monitor cloud function logs

4. **Performance**
   - Use topic subscriptions for broadcast notifications
   - Batch API calls when possible
   - Cache notification preferences

5. **Security**
   - Validate user roles before sending sensitive notifications
   - Encrypt sensitive data in notifications
   - Use Firestore security rules to control access

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only read their own notifications
    match /users/{userId}/notifications/{document=**} {
      allow read: if request.auth.uid == userId;
      allow write: if false; // Only Firebase can write
    }
    
    // Admins can read admin notifications
    match /admins/{adminId}/notifications/{document=**} {
      allow read: if request.auth.uid == adminId;
      allow write: if false; // Only Firebase can write
    }
    
  }
}
```

---

## Troubleshooting

### Issue: Notifications Not Received
**Solutions:**
1. Verify FCM token is saved in Firestore
2. Check app has notification permissions
3. Review Cloud Function logs for errors
4. Test with Firebase Console Messaging tab

### Issue: Duplicate Notifications
**Solutions:**
1. Add idempotency check to cloud functions
2. Use messageId to track duplicates
3. Implement deduplication logic

### Issue: Web Push Not Working
**Solutions:**
1. Verify service worker is registered
2. Check VAPID key is correct
3. Ensure site is HTTPS
4. Check browser notification permissions

### Issue: Android Foreground Notifications Not Showing
**Solutions:**
1. Create notification channel properly
2. Verify channel ID in gradle
3. Check notification importance level

---

## Next Steps

1. ✅ Deploy cloud functions
2. ✅ Configure Firebase project
3. ✅ Test all notification types
4. ✅ Set up monitoring/logging
5. ✅ Train team on maintenance
6. ✅ Monitor in production

---

## Support & Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter firebase_messaging](https://pub.dev/packages/firebase_messaging)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [GemNest Documentation](./README.md)

---

**Last Updated:** January 15, 2026
**Status:** ✅ Complete Implementation
