# Approval System - Quick Reference

## 🎯 Quick Summary
Sellers list products/auctions → Status is "pending" → Admin reviews in dashboard → Admin approves → Item appears to customers

## 📊 Status Overview

| Workflow Stage | Status | Seller Sees | Customer Sees |
|---|---|---|---|
| Seller creates listing | `pending` | ✓ In my listings | ✗ Hidden |
| Admin reviews | `pending` | ✓ Awaiting approval | ✗ Hidden |
| Admin clicks Approve | `approved` | ✓ Active | ✓ Public |
| Admin clicks Reject | `rejected` | ✓ Rejected | ✗ Hidden |

## 🔧 Code Changes at a Glance

### When Sellers Upload Products
```dart
// File: lib/seller/product_listing.dart
'approvalStatus': 'pending'  // Products start here
```

### When Sellers Create Auctions
```dart
// File: lib/seller/auction_product.dart
'approvalStatus': 'pending'  // Auctions start here
```

### What Customers See - Products
```dart
// File: lib/home_screen.dart
.where('approvalStatus', isEqualTo: 'approved')  // Only approved
```

### What Customers See - Auctions
```dart
// File: lib/screen/auction_screen/auction_screen.dart
.where('approvalStatus', isEqualTo: 'approved')  // Only approved
```

### Admin Dashboard
```dart
// File: lib/screen/admin_screen/admin_approval_screen.dart
// Shows pending items and approve/reject buttons
```

## 🚀 Getting Started (Admin)

### Step 1: Set Your Admin Role
Go to Firestore > users > {your-uid}
Add this field:
```json
{
  "role": "admin"
}
```

### Step 2: Access Dashboard
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const AdminApprovalScreen(),
));
```

### Step 3: Review & Approve
- See pending products/auctions
- Click Approve ✓ to publish
- Click Reject ✗ to decline

## 📝 Database Fields (NEW)

Every product and auction now has:
- `approvalStatus` (pending/approved/rejected)
- `approvedAt` (when it was approved)
- `approvedBy` (which admin approved it)
- `rejectedAt` (when it was rejected)
- `rejectedBy` (which admin rejected it)

## 🔍 Query Examples

### Get All Pending Products (Admin)
```dart
_firestore
    .collection('products')
    .where('approvalStatus', isEqualTo: 'pending')
    .snapshots()
```

### Get All Approved Products (Customer)
```dart
_firestore
    .collection('products')
    .where('approvalStatus', isEqualTo: 'approved')
    .snapshots()
```

### Get Items Approved by Specific Admin
```dart
_firestore
    .collection('products')
    .where('approvedBy', isEqualTo: adminUid)
    .snapshots()
```

## 🎬 User Flows

### Seller Flow
```
1. Fill product form
2. Click Submit
3. Product created with approvalStatus: 'pending'
4. Product appears in "My Products" (grayed out)
5. Wait for admin approval
6. Once approved, appears publicly
```

### Admin Flow
```
1. Open Admin Dashboard
2. See Products tab (pending items)
3. See Auctions tab (pending items)
4. Click Approve/Reject
5. System updates and records action
```

### Customer Flow
```
1. Browse home page
2. Only see approved products
3. Browse auctions
4. Only see approved auctions
5. Cannot see pending items at all
```

## 🔐 Security Checklist

- [x] Admin role required to access dashboard
- [x] Audit trail (approvedBy/rejectedBy tracked)
- [x] Timestamps recorded
- [x] Products/auctions hidden from customers until approved
- [ ] Optional: Firestore rules to prevent unauthorized updates

## ⚡ Common Tasks

### Approve a Product
1. Open Admin Dashboard
2. Go to Products tab
3. Find the product
4. Click "Approve" button
5. System updates `approvalStatus: 'approved'`

### Reject a Product
1. Open Admin Dashboard
2. Go to Products tab
3. Find the product
4. Click "Reject" button
5. System updates `approvalStatus: 'rejected'`

### Seller Views Their Pending Product
1. Go to "My Products"
2. See product with status badge "Pending Review"
3. Cannot delete while pending
4. Can edit and resubmit if rejected

### Customer Sees Approved Product
1. Go to Home Screen or Auctions
2. Only sees items with `approvalStatus: 'approved'`
3. Can add to cart or bid
4. No indication item was ever pending

## 🐛 Troubleshooting

| Problem | Solution |
|---|---|
| Can't access dashboard | Ensure user has `role: "admin"` in Firestore |
| Don't see pending items | Check internet, try refresh |
| Items still visible before approval | Check query includes `where('approvalStatus', isEqualTo: 'approved')` |
| "Firestore index" error | Click link in error to auto-create index |
| Approval doesn't work | Check Firestore security rules allow admin updates |

## 📈 Metrics You Can Track

```dart
// Count pending products
await _firestore.collection('products')
    .where('approvalStatus', isEqualTo: 'pending')
    .count().get();

// Count approved products
await _firestore.collection('products')
    .where('approvalStatus', isEqualTo: 'approved')
    .count().get();

// Approval rate
approved_count / (approved_count + rejected_count)
```

## 📚 Full Docs

- **APPROVAL_SYSTEM_DOCUMENTATION.md** - Comprehensive guide
- **APPROVAL_SYSTEM_SETUP_GUIDE.md** - Detailed setup steps
- **IMPLEMENTATION_SUMMARY.md** - What was changed

## ✅ Implementation Checklist

- [x] Models updated (Auction)
- [x] Products set to pending on creation
- [x] Auctions set to pending on creation
- [x] Home screen filters approved products only
- [x] Auction screen filters approved auctions only
- [x] Admin dashboard created
- [x] Admin can approve items
- [x] Admin can reject items
- [x] Audit trail recorded
- [ ] Admin role setup (MANUAL - do this first!)
- [ ] Navigation to dashboard added (OPTIONAL)
- [ ] Firestore rules updated (OPTIONAL)
- [ ] Email notifications (FUTURE)

## 🎯 Key Points to Remember

1. **Default Status:** All new products/auctions start as `pending`
2. **Customer View:** Only see `approved` items
3. **Admin Dashboard:** Shows only `pending` items for review
4. **Audit Trail:** System automatically records who approved and when
5. **Scalable:** Works with unlimited items
6. **One-Click:** Simple approve/reject interface

## 🚀 Production Deployment

Before going live:
1. Set up admin users with `role: "admin"`
2. Add navigation to admin dashboard
3. Test with sample seller/admin/customer accounts
4. Set up approval notification system (optional)
5. Brief admins on approval process
6. Monitor first few approvals
7. Adjust as needed

---

**System is ready to use. Start by setting admin roles in Firestore!**

