# Product & Auction Approval System Documentation

## Overview
This document describes the admin approval workflow for product and auction listings in GemNest. Sellers can list products and create auctions, but they remain hidden from the public until approved by an admin.

## System Architecture

### Approval Workflow

```
Seller Lists Product/Auction
        ↓
Status: "pending" (not visible to users)
        ↓
Admin Reviews in Dashboard
        ↓
    ┌───┴───┐
    ↓       ↓
 APPROVE  REJECT
    ↓       ↓
visible   archived
(public)
```

## Data Model Changes

### Products Collection
```dart
products/
├── {productId}
│   ├── title: String
│   ├── category: String
│   ├── pricing: double
│   ├── quantity: int
│   ├── description: String
│   ├── imageUrl: String
│   ├── sellerId: String
│   ├── approvalStatus: String  // NEW: 'pending', 'approved', 'rejected'
│   ├── approvedAt: Timestamp?  // NEW
│   ├── approvedBy: String?     // NEW (admin UID)
│   ├── rejectedAt: Timestamp?  // NEW
│   ├── rejectedBy: String?     // NEW (admin UID)
│   ├── timestamp: Timestamp
│   └── [other fields...]
```

### Auctions Collection
```dart
auctions/
├── {auctionId}
│   ├── title: String
│   ├── currentBid: double
│   ├── endTime: String (ISO 8601)
│   ├── imagePath: String
│   ├── sellerId: String
│   ├── approvalStatus: String  // NEW: 'pending', 'approved', 'rejected'
│   ├── approvedAt: Timestamp?  // NEW
│   ├── approvedBy: String?     // NEW (admin UID)
│   ├── rejectedAt: Timestamp?  // NEW
│   ├── rejectedBy: String?     // NEW (admin UID)
│   ├── timestamp: Timestamp
│   └── [other fields...]
```

## Code Changes

### 1. Auction Model Updates
**File:** `lib/models/auction_model.dart`

```dart
class Auction {
  // ... existing fields ...
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  
  Auction({
    // ... existing parameters ...
    this.approvalStatus = 'pending',
  });
  
  // Updated toMap() and fromMap() methods
  Map<String, dynamic> toMap() {
    return {
      // ... existing fields ...
      'approvalStatus': approvalStatus,
    };
  }
  
  factory Auction.fromMap(Map<String, dynamic> map) {
    return Auction(
      // ... existing fields ...
      approvalStatus: map['approvalStatus'] ?? 'pending',
    );
  }
}
```

### 2. Product Listing Updates
**File:** `lib/seller/product_listing.dart`

When sellers upload products:
```dart
await _firestore.collection('products').add({
  'title': _titleController.text,
  'category': _selectedCategory,
  'pricing': double.tryParse(_pricingController.text) ?? 0.0,
  'approvalStatus': 'pending', // NEW
  // ... other fields ...
});
```

### 3. Auction Creation Updates
**File:** `lib/seller/auction_product.dart`

When sellers create auctions:
```dart
await _firestore.collection('auctions').add({
  'title': _titleController.text,
  'currentBid': double.tryParse(_currentBidController.text) ?? 0.0,
  'approvalStatus': 'pending', // NEW
  // ... other fields ...
});
```

### 4. Home Screen Filtering
**File:** `lib/home_screen.dart`

Only approved products are displayed:
```dart
Future<void> _fetchRandomGems() async {
  final productsSnapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('approvalStatus', isEqualTo: 'approved')
      .get();
  // ... rest of code ...
}
```

### 5. Auction Screen Filtering
**File:** `lib/screen/auction_screen/auction_screen.dart`

Only approved auctions are displayed:
```dart
Stream<QuerySnapshot> _getFilteredAuctionsStream() {
  Query query = FirebaseFirestore.instance.collection('auctions')
      .where('approvalStatus', isEqualTo: 'approved');
  // ... rest of code ...
}
```

### 6. Admin Dashboard
**File:** `lib/screen/admin_screen/admin_approval_screen.dart` (NEW)

Complete admin interface with two tabs:
- **Products Tab:** Shows all pending products
- **Auctions Tab:** Shows all pending auctions

Features:
- Image preview
- Product/Auction details
- Approve/Reject buttons
- Real-time updates using Firestore streams
- Admin verification (checks if user has 'admin' role)

## User Flows

### For Sellers

#### Creating a Product Listing
1. Navigate to "Product Listing" screen
2. Fill product details and upload image
3. Submit product
4. Product saved with `approvalStatus: 'pending'`
5. Product appears in "My Listed Products" but NOT visible to customers
6. Receive notification when admin approves/rejects

#### Creating an Auction
1. Navigate to "Auction Product" screen
2. Fill auction details and set end time
3. Submit auction
4. Auction saved with `approvalStatus: 'pending'`
5. Auction appears in "My Auctions" but NOT visible to customers
6. Receive notification when admin approves/rejects

### For Admins

#### Reviewing Products
1. Navigate to "Admin Approval Dashboard"
2. Go to "Products" tab
3. Review pending products
4. Click "Approve" to make visible to customers
5. Click "Reject" if doesn't meet guidelines
6. System records who approved/rejected and when

#### Reviewing Auctions
1. Navigate to "Admin Approval Dashboard"
2. Go to "Auctions" tab
3. Review pending auctions
4. Click "Approve" to make visible to customers
5. Click "Reject" if doesn't meet guidelines

### For Customers

#### Browsing Products
- Only see products with `approvalStatus: 'approved'`
- Pending products are completely hidden
- No indicators of pending items

#### Browsing Auctions
- Only see auctions with `approvalStatus: 'approved'`
- Pending auctions are completely hidden
- Cannot bid on pending auctions

## Approval Statuses

### pending
- **Description:** Waiting for admin review
- **Visibility:** Only to seller and admins
- **Actions:** Can be approved or rejected
- **Duration:** Until admin takes action

### approved
- **Description:** Verified and published
- **Visibility:** Public (all customers)
- **Actions:** Can be deactivated by seller or removed by admin
- **Duration:** Until seller deletes or auction/sale completes

### rejected
- **Description:** Did not meet guidelines
- **Visibility:** Only to seller (grayed out)
- **Actions:** Can be edited and resubmitted, or deleted
- **Duration:** Until seller resubmits or deletes

## Firestore Queries

### Get Pending Products (Admin)
```dart
_firestore
    .collection('products')
    .where('approvalStatus', isEqualTo: 'pending')
    .snapshots()
```

### Get Approved Products (Customer)
```dart
_firestore
    .collection('products')
    .where('approvalStatus', isEqualTo: 'approved')
    .snapshots()
```

### Get Approved Auctions (Customer)
```dart
_firestore
    .collection('auctions')
    .where('approvalStatus', isEqualTo: 'approved')
    .snapshots()
```

### Get Seller's Products (Any Status)
```dart
_firestore
    .collection('products')
    .where('sellerId', isEqualTo: userId)
    .snapshots()
```

## Implementation Checklist

### Backend (Firestore)
- [x] Update products collection schema
- [x] Update auctions collection schema
- [x] Add security rules (optional)

### Frontend - Seller
- [x] Update product_listing.dart to set approvalStatus = 'pending'
- [x] Update auction_product.dart to set approvalStatus = 'pending'
- [ ] Show approval status badge in seller's listings
- [ ] Notify sellers of approval/rejection

### Frontend - Customer
- [x] Update home_screen.dart to filter approved products
- [x] Update auction_screen.dart to filter approved auctions
- [ ] Show "Approved" indicator (optional)

### Frontend - Admin
- [x] Create admin_approval_screen.dart
- [ ] Add navigation to admin dashboard
- [ ] Create approval notification system
- [ ] Add audit log for all approvals/rejections

## Future Enhancements

1. **Batch Approval:** Allow admins to approve multiple items at once
2. **Custom Rejection Reasons:** Admins can specify why an item was rejected
3. **Appeal System:** Sellers can appeal rejections
4. **Auto-Approval:** Set rules for auto-approving items (e.g., from verified sellers)
5. **Approval Metrics:** Dashboard showing approval rate, avg time to approval
6. **Email Notifications:** Notify sellers when their items are approved/rejected
7. **Audit Trail:** Complete log of all approval actions with timestamps
8. **Seller Rating:** Higher-rated sellers get faster approval or auto-approval

## Security Considerations

### Firestore Security Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Products - Read approved only, write by owner
    match /products/{productId} {
      allow read: if resource.data.approvalStatus == 'approved' || 
                     request.auth.uid == resource.data.sellerId;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.sellerId;
    }
    
    // Auctions - Read approved only, write by owner
    match /auctions/{auctionId} {
      allow read: if resource.data.approvalStatus == 'approved' || 
                     request.auth.uid == resource.data.sellerId;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.sellerId;
    }
    
    // Admin only access for approval status updates
    match /products/{productId} {
      allow update: if hasRole('admin') && 
                       (request.resource.data.approvalStatus != null ||
                        request.resource.data.approvedBy != null);
    }
    
    match /auctions/{auctionId} {
      allow update: if hasRole('admin') && 
                       (request.resource.data.approvalStatus != null ||
                        request.resource.data.approvedBy != null);
    }
    
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
  
  function hasRole(role) {
    return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
  }
}
```

## Testing Checklist

- [ ] Sellers can create products with pending status
- [ ] Sellers can create auctions with pending status
- [ ] Pending products don't appear in home screen
- [ ] Pending auctions don't appear in auction screen
- [ ] Admins can see pending items in dashboard
- [ ] Admins can approve products
- [ ] Admins can reject products
- [ ] Admins can approve auctions
- [ ] Admins can reject auctions
- [ ] Approved items appear in public listings
- [ ] Rejected items show in seller's dashboard with rejection status
- [ ] Sellers see their pending items in their listings

## Troubleshooting

### Products/Auctions Not Appearing in Dashboard
- Check that items have `approvalStatus` field
- Verify user has 'admin' role in users collection
- Check Firestore rules aren't blocking reads

### Approved Items Still Not Visible
- Verify `approvalStatus` is exactly 'approved' (case-sensitive)
- Check that WHERE clause is correct in the query
- Clear app cache and restart

### Admin Dashboard Won't Load
- Check internet connection
- Verify Firebase authentication
- Check that user has admin role set in database

