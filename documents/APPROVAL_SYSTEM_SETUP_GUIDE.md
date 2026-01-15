# Admin Approval System - Quick Setup Guide

## 1. Set Up Admin Role in Firestore

Navigate to Firestore Console and update the users collection:

```javascript
// For each admin user, set the 'role' field:
users/{adminUserId}
{
  name: "Admin Name",
  email: "admin@gemnest.com",
  role: "admin",  // ADD THIS FIELD
  // ... other fields ...
}
```

## 2. Navigation Integration

### Option A: Add Admin Button to Seller Dashboard

Add this to the seller home page navigation:

```dart
// In your seller navigation, add:
if (userRole == 'admin')
  ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminApprovalScreen(),
        ),
      );
    },
    child: const Text('Admin Dashboard'),
  )
```

### Option B: Add Menu Item

```dart
ListTile(
  leading: const Icon(Icons.admin_panel_settings),
  title: const Text('Admin Dashboard'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AdminApprovalScreen(),
    ),
  ),
)
```

### Option C: Add to App Drawer

```dart
if (hasAdminRole)
  DrawerHeader(
    child: ListTile(
      title: const Text('Admin Panel'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminApprovalScreen(),
        ),
      ),
    ),
  )
```

## 3. Import Statement

In any file where you want to navigate to the admin dashboard:

```dart
import 'package:gemnest_mobile_app/screen/admin_screen/admin_approval_screen.dart';
```

## 4. Verify File Structure

Ensure this file exists:
```
lib/
├── screen/
│   ├── admin_screen/
│   │   └── admin_approval_screen.dart  ✓ Created
```

## 5. Create users/admin Test Account

In your Firebase Console:

```
Email: admin@test.com
Password: AdminTest123!
Firestore Document:
{
  name: "Admin User",
  email: "admin@test.com",
  role: "admin",
  isActive: true
}
```

## 6. Test the System

### As a Seller:
1. Log in with seller account
2. Create a product → Status should be "pending"
3. Create an auction → Status should be "pending"
4. Check home screen → Product should NOT appear
5. Check auction screen → Auction should NOT appear

### As an Admin:
1. Log in with admin account (role: "admin")
2. Navigate to "Admin Approval Dashboard"
3. You should see pending products and auctions
4. Click "Approve" button
5. Log in as a customer
6. Now you should see the approved items

## 7. Expected Behavior

### Before Approval:
```
Seller's Dashboard          Customer's View
┌─────────────────────┐    ┌──────────────┐
│ Product (PENDING)   │    │ (EMPTY)      │
│ Status: Pending ⏳  │    │ No products  │
│ Only visible to     │    │              │
│ seller & admin      │    │              │
└─────────────────────┘    └──────────────┘
```

### After Approval:
```
Seller's Dashboard          Customer's View
┌─────────────────────┐    ┌──────────────────┐
│ Product (APPROVED)  │    │ Product          │
│ Status: Approved ✓  │    │ - Can view       │
│ Visible to all      │    │ - Can add to cart│
│                     │    │ - Can purchase   │
└─────────────────────┘    └──────────────────┘
```

## 8. Firebase Composite Indexes

If you get a Firestore error about composite indexes, go to Firestore Console:

**Collections > auctions > Create Composite Index**

Add these indexes:

### Index 1: Category + Approval
```
Collection: auctions
Field: category (Ascending)
Field: approvalStatus (Ascending)
```

### Index 2: CurrentBid + Approval
```
Collection: auctions
Field: currentBid (Ascending)
Field: approvalStatus (Ascending)
```

## 9. Security Rules Update (Optional but Recommended)

Update your Firestore security rules to prevent unauthorized approval:

```javascript
// In Firestore Rules:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow admins to approve/reject
    match /products/{productId} {
      allow update: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
                       request.resource.data.approvalStatus in ['approved', 'rejected'];
    }
    
    match /auctions/{auctionId} {
      allow update: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
                       request.resource.data.approvalStatus in ['approved', 'rejected'];
    }
  }
}
```

## 10. Monitoring Approvals

Create a dashboard to track approval metrics:

```dart
// Count pending products
await _firestore
    .collection('products')
    .where('approvalStatus', isEqualTo: 'pending')
    .count()
    .get();

// Count approved products
await _firestore
    .collection('products')
    .where('approvalStatus', isEqualTo: 'approved')
    .count()
    .get();
```

## 11. Notifications (Future Enhancement)

Consider adding notifications when:
- [ ] Seller uploads a product
- [ ] Admin approves a listing
- [ ] Admin rejects a listing

Example implementation:
```dart
// Notify admins of pending approvals
await _firestore
    .collection('notifications')
    .add({
      'type': 'product_pending_approval',
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
      'sendTo': 'all_admins',
    });
```

## 12. Troubleshooting

### Issue: "You do not have admin access" message
**Solution:** 
1. Check that user has `role: "admin"` in Firestore
2. Ensure you're logged in with correct admin account
3. Try logging out and back in

### Issue: Pending items still visible to customers
**Solution:**
1. Check that WHERE clause includes `approvalStatus == 'approved'`
2. Verify the field name is exactly "approvalStatus" (case-sensitive)
3. Clear app cache: `flutter clean && flutter pub get`

### Issue: Composite Index Error
**Solution:**
1. Follow Step 8 above to create missing indexes
2. Click the link in the Firestore error message
3. Firestore will auto-create the index

### Issue: Admin Dashboard Won't Load
**Solution:**
1. Verify Firebase is initialized
2. Check internet connection
3. Ensure user has 'admin' role
4. Check Firestore rules aren't blocking reads

## 13. Production Checklist

Before going live:

- [ ] Set up admin users in Firestore
- [ ] Configure Firebase security rules
- [ ] Create composite indexes
- [ ] Test seller → pending → approval flow
- [ ] Test customer visibility
- [ ] Set up approval notification system
- [ ] Train admins on approval process
- [ ] Create audit logs
- [ ] Set SLA for approval time (e.g., 24 hours)
- [ ] Document approval guidelines

