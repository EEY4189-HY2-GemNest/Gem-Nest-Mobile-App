# Firebase Push Notifications - Complete Setup Guide

## Overview
Complete Firebase Cloud Messaging (FCM) implementation for GemNest with notifications for:
- **Sellers:** Product/Auction approvals, bids, order updates
- **Buyers:** Approvals, outbid alerts, auction wins, order status
- **Admins:** New approvals needed notifications

---

## 📋 Files Created

### Flutter App Files
1. **lib/models/notification_model.dart** - Notification data models
2. **lib/services/notification_service.dart** - FCM service & local notifications
3. **lib/screen/notifications_screen.dart** - Notifications history UI
4. **functions/notifications.js** - Cloud Functions for sending notifications

---

## 🔧 Setup Steps

### Step 1: Update pubspec.yaml

Add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_messaging: ^14.6.0
  flutter_local_notifications: ^17.0.0
  cloud_firestore: ^4.13.0
  firebase_auth: ^4.11.0
  intl: ^0.19.0
  # ... other dependencies

dev_dependencies:
  flutter_test:
    sdk: flutter
```

Then run:
```bash
flutter pub get
```

### Step 2: Android Configuration

#### AndroidManifest.xml
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application>
        <!-- Firebase messaging service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- Notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="gemnest_channel" />

        <!-- Main activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop" />
    </application>
</manifest>
```

#### build.gradle (Project Level)
```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
  }
}
```

#### build.gradle (App Level)
```gradle
apply plugin: 'com.google.gms.google-services'

android {
  compileSdkVersion 33
  targetSdkVersion 33
}

dependencies {
  implementation 'com.google.firebase:firebase-messaging:23.2.1'
}
```

### Step 3: iOS Configuration

#### ios/Podfile
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_ios_podfile_setup_target target
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_NOTIFICATIONS=1',
      ]
    end
  end
end
```

#### Enable Push Notifications
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project
3. Select Runner target
4. Go to Signing & Capabilities
5. Click "+ Capability"
6. Add "Push Notifications"

#### ios/Runner/GeneratedPluginRegistrant.m
Ensure FirebaseMessaging is registered (usually automatic)

### Step 4: Create Notification Channel (Android)

The notification service creates the channel automatically, but you can customize it in **AndroidManifest.xml**:

```xml
<!-- Add inside <application> tag -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="gemnest_channel" />
```

### Step 5: Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gemnest_mobile_app/services/notification_service.dart';
import 'firebase_options.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}
```

### Step 6: Deploy Cloud Functions

Install dependencies:

```bash
cd functions
npm install firebase-functions firebase-admin axios
```

Deploy functions:

```bash
firebase deploy --only functions
```

This deploys all notification functions:
- `onProductApproved` - Triggers when product approved
- `onProductRejected` - Triggers when product rejected
- `onAuctionApproved` - Triggers when auction approved
- `onAuctionRejected` - Triggers when auction rejected
- `onNewBid` - Triggers when new bid placed
- `notifyAuctionEnded` - Scheduled function for auction ending notifications
- `onOrderCreated` - Triggers on new orders
- `onOrderStatusChanged` - Triggers on order status updates
- `onPaymentReceived` - Triggers on payment completion
- `broadcastProductApprovedByCategory` - Broadcasts to interested users
- `notifyAuctionEndingSoon` - Scheduled function for ending soon alerts
- `notifyAdminsNewApprovalNeeded` - Notifies admins of new submissions

### Step 7: Add Navigation to Notifications Screen

In your main navigation (e.g., home screen or app drawer):

```dart
import 'package:gemnest_mobile_app/screen/notifications_screen.dart';

// In your navigation:
ListTile(
  leading: const Icon(Icons.notifications),
  title: const Text('Notifications'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
  ),
)
```

---

## 🔔 Notification Flow Diagrams

### Product Approval Flow
```
Seller Creates Product
        ↓
Product saved with approvalStatus: 'pending'
        ↓
Admin Approves in Dashboard
        ↓
onProductApproved Cloud Function Triggers
        ↓
SendNotification to Seller
        ↓
Notification saved to users/{sellerId}/notifications
        ↓
Foreground: Local notification shown
Background: Push notification sent
        ↓
Seller receives notification
```

### Auction Bid Flow
```
Buyer Places Bid
        ↓
currentBid updated in Firestore
        ↓
onNewBid Cloud Function Triggers
        ↓
├─ Notify Seller (New Bid!)
├─ Notify Previous Bidder (You were outbid)
└─ Save notifications to Firestore
        ↓
Notifications delivered
```

### Order Status Flow
```
Order Status Changes
        ↓
onOrderStatusChanged Trigger
        ↓
Status-specific notification
        ↓
├─ confirmed → "Order Confirmed"
├─ shipped → "Order Shipped"  
├─ delivered → "Order Delivered"
└─ cancelled → "Order Cancelled"
        ↓
Buyer receives notification
```

---

## 📱 Testing Notifications

### Test in Firebase Console

1. Go to Firebase Console > Cloud Messaging
2. Create a test message:
   - Title: "Test Notification"
   - Body: "This is a test"
   - Target: User by UID or condition

3. Send to your device

### Test from Cloud Functions

```bash
# Test product approval
firebase functions:shell
> onProductApproved({
    before: { approvalStatus: 'pending' },
    after: { 
      approvalStatus: 'approved',
      title: 'Test Product',
      sellerId: 'user123'
    }
  }, {
    params: { productId: 'prod123' }
  })
```

### Manual Testing in App

```dart
// In your debug build, add this to test:
ElevatedButton(
  onPressed: () async {
    final service = NotificationService();
    final token = await service.getFCMToken();
    print('FCM Token: $token');
  },
  child: const Text('Get FCM Token'),
)
```

---

## 🔐 Security & Permissions

### Android Permissions

The notification service requests:
- `android.permission.INTERNET`
- `android.permission.POST_NOTIFICATIONS`

### iOS Permissions

The notification service requests:
- Alert permission
- Badge permission
- Sound permission

Users will be prompted on first app launch.

### Firestore Security Rules

Ensure notifications collection is secure:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only read their own notifications
    match /users/{userId}/notifications/{notificationId} {
      allow read: if request.auth.uid == userId;
      allow write: if false; // Cloud Functions only
    }
    
    // Notification preferences
    match /users/{userId}/preferences/notifications {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## 📊 Notification Database Schema

### Notifications Collection

```
users/{userId}/notifications/{notificationId}
{
  id: string,
  title: string,
  body: string,
  type: string ('productApproved', 'bidPlaced', etc),
  imageUrl: string (optional),
  data: {
    productId?: string,
    auctionId?: string,
    orderId?: string,
    bidAmount?: number,
    actionUrl?: string,
    // ... custom data
  },
  createdAt: timestamp,
  readAt: timestamp (optional),
  isRead: boolean,
  actionUrl: string (optional - for deep linking)
}
```

### User Document (Updated)

```
users/{userId}
{
  // ... existing fields ...
  fcmToken: string,
  fcmTokenUpdatedAt: timestamp,
  interests?: array (categories user follows),
  // notification preferences stored separately in:
  // users/{userId}/preferences/notifications
}
```

---

## 🎯 Notification Types

### For Sellers
| Type | Trigger | Message |
|------|---------|---------|
| `productApproved` | Admin approves product | "Your product has been approved!" |
| `productRejected` | Admin rejects product | "Your product was rejected" |
| `auctionApproved` | Admin approves auction | "Your auction is now live!" |
| `auctionRejected` | Admin rejects auction | "Your auction was rejected" |
| `newBidOnAuction` | Buyer places bid | "New bid of Rs. X placed" |
| `paymentReceived` | Order payment received | "Payment received for order" |

### For Buyers
| Type | Trigger | Message |
|------|---------|---------|
| `itemApprovedNotification` | Product in interest category approved | "New item available in X category" |
| `outbid` | Placed higher bid | "You were outbid!" |
| `auctionWon` | Won auction | "Congratulations! You won!" |
| `orderConfirmed` | Seller confirms order | "Your order has been confirmed" |
| `orderShipped` | Order shipped | "Your order is on the way" |
| `orderDelivered` | Order delivered | "Order delivered" |

### System
| Type | Trigger | Message |
|------|---------|---------|
| `systemMessage` | System notifications | Various system updates |

---

## 🔗 Deep Linking Examples

The `actionUrl` field enables navigation:

```
product/{productId}          → Product detail screen
auction/{auctionId}          → Auction detail screen
order/{orderId}              → Order detail screen
admin/approvals/products     → Admin dashboard products tab
admin/approvals/auctions     → Admin dashboard auctions tab
```

Implement in notification tap handler:

```dart
void _handleNotificationTap(GemNestNotification notification, String userId) {
  if (notification.actionUrl != null) {
    _navigateToDeepLink(notification.actionUrl!);
  }
}

void _navigateToDeepLink(String url) {
  if (url.startsWith('product/')) {
    final productId = url.split('/')[1];
    Navigator.push(/* ProductDetailScreen */);
  } else if (url.startsWith('auction/')) {
    final auctionId = url.split('/')[1];
    Navigator.push(/* AuctionDetailScreen */);
  }
  // ... etc
}
```

---

## ⚙️ Configuration Options

### Customize Notification Channels (Android)

Edit in `notification_service.dart`:

```dart
const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
  'gemnest_channel',          // Channel ID
  'GemNest Notifications',     // Channel name
  channelDescription: 'Notifications from GemNest',
  importance: Importance.max,
  priority: Priority.high,
  enableVibration: true,
  enableLights: true,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('notification_sound'),
  color: Color.fromARGB(255, 66, 133, 244), // Blue color
);
```

### Custom Notification Sound

1. Add sound file to `android/app/src/main/res/raw/notification_sound.mp3`
2. Update `androidNotificationDetails` (above)

---

## 🐛 Troubleshooting

### Issue: Notifications not received
**Solutions:**
1. Verify FCM token is saved: Check Firestore `users/{uid}` for `fcmToken`
2. Check internet connection
3. Verify app has notification permission granted
4. Check Cloud Function logs in Firebase Console
5. Ensure authentication is working

### Issue: Cloud Function not triggering
**Solutions:**
1. Check function logs: `firebase functions:log`
2. Verify Firestore document structure matches function expectations
3. Check if document changes are actually being detected
4. Verify Firestore rules allow function to read/write

### Issue: FCM Token is null
**Solutions:**
1. Ensure app has requested notification permission
2. Check Firebase initialization
3. Verify google-services.json is in place
4. Try uninstalling and reinstalling app

### Issue: Notifications appear in console but not on device
**Solutions:**
1. Check device notification settings - app must be enabled
2. Verify FCM token is valid and current
3. Check device has internet connection
4. For iOS: Verify Push Notifications capability is enabled

---

## 📈 Monitoring & Analytics

### Check Notification Delivery

In Firebase Console:

1. Go to Cloud Messaging
2. View "Messages" tab
3. See delivery statistics

### Monitor Cloud Functions

```bash
firebase functions:log --follow
```

### Query Notification Stats

```dart
// Count sent notifications
final count = await _firestore
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .count()
    .get();

// Count unread
final unread = await _firestore
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .where('isRead', isEqualTo: false)
    .count()
    .get();
```

---

## 🚀 Production Deployment Checklist

- [ ] All dependencies added to pubspec.yaml
- [ ] Android permissions configured
- [ ] iOS capabilities configured
- [ ] Firebase initialized in main.dart
- [ ] NotificationService initialized
- [ ] Cloud Functions deployed
- [ ] Firestore rules updated for security
- [ ] Test notifications in production
- [ ] Notification sounds configured
- [ ] Deep linking implemented
- [ ] Error handling for notification taps
- [ ] FCM token refresh handled
- [ ] Notifications permission requested

---

## 📚 API Reference

### NotificationService Methods

```dart
// Initialize
Future<void> initialize()

// Get notifications stream
Stream<List<GemNestNotification>> getNotificationsStream(String userId)

// Get unread count
Stream<int> getUnreadNotificationsCount(String userId)

// Mark as read
Future<void> markNotificationAsRead(String userId, String notificationId)

// Mark all as read
Future<void> markAllNotificationsAsRead(String userId)

// Delete notification
Future<void> deleteNotification(String userId, String notificationId)

// Delete all
Future<void> deleteAllNotifications(String userId)

// Get FCM token
Future<String?> getFCMToken()

// Subscribe to topic
Future<void> subscribeToTopic(String topic)

// Unsubscribe from topic
Future<void> unsubscribeFromTopic(String topic)

// Get preferences
Future<NotificationPreferences> getNotificationPreferences(String userId)

// Update preferences
Future<void> updateNotificationPreferences(NotificationPreferences prefs)
```

---

## 🎉 You're All Set!

Your push notification system is now ready. Notifications will be:
- Sent automatically based on events
- Stored in Firestore for history
- Displayable in the NotificationsScreen
- Customizable per user preferences

