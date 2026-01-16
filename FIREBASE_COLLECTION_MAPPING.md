# Firebase Collection Field Mapping - Complete Reference

## 📋 Overview
This document maps the actual Firebase collection structure as implemented in the mobile app to help the admin dashboard display correct data.

---

## 1. SIGNUP COLLECTIONS

### Buyers Collection (`buyers/{userId}`)
**Location:** Created in `signup_screen.dart` (line 331)

```
buyers/{userId}
├── firebaseUid: string        ✅ Same as document ID
├── email: string              ✅ User email
├── phoneNumber: string        ✅ Contact phone
├── role: string               ✅ Value: "buyer"
└── isActive: boolean          ✅ Value: true (for buyers)
```

**Example:**
```json
{
  "firebaseUid": "uid_xyz",
  "email": "buyer@example.com",
  "phoneNumber": "+94771234567",
  "role": "buyer",
  "isActive": true
}
```

### Sellers Collection (`sellers/{userId}`)
**Location:** Created in `signup_screen.dart` (line 331)

```
sellers/{userId}
├── firebaseUid: string               ✅ Same as document ID
├── email: string                     ✅ User email
├── phoneNumber: string               ✅ Contact phone
├── role: string                      ✅ Value: "seller"
├── isActive: boolean                 ✅ Value: false (awaiting approval)
├── displayName: string               ✅ Business owner name
├── address: string                   ✅ Business address
├── nicNumber: string                 ✅ National ID number
├── businessName: string              ✅ Business name
├── brNumber: string                  ✅ Business registration number
├── businessRegistrationUrl: string   ✅ Document URL in Cloud Storage
└── nicDocumentUrl: string            ✅ Document URL in Cloud Storage
```

**Example:**
```json
{
  "firebaseUid": "seller_uid_abc",
  "email": "seller@gemshop.com",
  "phoneNumber": "+94771234567",
  "role": "seller",
  "isActive": false,
  "displayName": "John Gem Dealer",
  "address": "123 Gem Street, Colombo",
  "nicNumber": "123456789V",
  "businessName": "Precious Gems Ltd",
  "brNumber": "BR12345",
  "businessRegistrationUrl": "gs://bucket/business_registrations/...",
  "nicDocumentUrl": "gs://bucket/nic_documents/..."
}
```

---

## 2. PRODUCT LISTING COLLECTION

### Products Collection (`products/{productId}`)
**Location:** Created in `lib/seller/product_listing.dart`

```
products/{productId}
├── title: string                 ✅ Product name
├── category: string              ✅ Gem category
├── pricing: double               ✅ Price in currency
├── quantity: int                 ✅ Available quantity
├── description: string           ✅ Product details
├── imageUrl: string              ✅ Cloud Storage path (one main image)
├── sellerId: string              ✅ Creator user ID
├── approvalStatus: string        ✅ "pending" | "approved" | "rejected"
├── timestamp: timestamp          ✅ When created
├── deliveryMethods: array        ✅ Available delivery options
├── paymentMethods: array         ✅ Accepted payment types
├── gemCertificates: array        ✅ Certificate documents (if any)
└── certificateVerificationStatus: string ✅ "pending" | "approved" | "none"
```

**Example:**
```json
{
  "title": "Premium Ruby",
  "category": "Ruby",
  "pricing": 5000.00,
  "quantity": 2,
  "description": "High quality burmese ruby",
  "imageUrl": "gs://bucket/products/...",
  "sellerId": "seller_uid_abc",
  "approvalStatus": "approved",
  "timestamp": "2024-01-16T10:30:00Z",
  "deliveryMethods": ["pickup", "courier"],
  "paymentMethods": ["cash", "card"],
  "gemCertificates": [{...}],
  "certificateVerificationStatus": "approved"
}
```

---

## 3. AUCTION LISTING COLLECTION

### Auctions Collection (`auctions/{auctionId}`)
**Location:** Created in `lib/seller/auction_product.dart` (line 247)

```
auctions/{auctionId}
├── title: string                      ✅ Auction name
├── currentBid: double                 ✅ Current highest bid
├── endTime: string (ISO 8601)         ✅ Auction end datetime
├── imagePath: string                  ✅ Cloud Storage image URL
├── lastBidTime: timestamp             ✅ When last bid occurred
├── minimumIncrement: double           ✅ Minimum bid step amount
├── paymentInitiatedAt: timestamp      ✅ null initially
├── paymentStatus: string              ✅ "pending" | "completed"
├── winningUserId: string              ✅ null until auction ends
├── deliveryMethods: array             ✅ Available delivery options
├── paymentMethods: array              ✅ Accepted payment types
├── gemCertificates: array             ✅ Certificate documents
├── certificateVerificationStatus: string ✅ "pending" | "approved" | "none"
├── approvalStatus: string             ✅ "pending" | "approved" | "rejected"
├── sellerId: string                   ✅ Creator user ID
└── timestamp: timestamp               ✅ When created
```

**Example:**
```json
{
  "title": "Diamond Auction - 2 Carat",
  "currentBid": 15000.00,
  "endTime": "2024-01-20T18:00:00Z",
  "imagePath": "gs://bucket/auctions/...",
  "lastBidTime": {...timestamp...},
  "minimumIncrement": 500.00,
  "paymentInitiatedAt": null,
  "paymentStatus": "pending",
  "winningUserId": null,
  "deliveryMethods": ["courier"],
  "paymentMethods": ["card", "bank"],
  "gemCertificates": [{...}],
  "certificateVerificationStatus": "approved",
  "approvalStatus": "pending",
  "sellerId": "seller_uid_abc",
  "timestamp": {...timestamp...}
}
```

---

## 4. ADMIN DASHBOARD QUERY ISSUES

### Current Problem in Dashboard
The admin dashboard is querying `users` collection with `userType` field:

```javascript
// ❌ WRONG - This collection doesn't exist in signup
const sellerQuery = query(usersRef, where('userType', '==', 'seller'));
const buyerQuery = query(usersRef, where('userType', '==', 'buyer'));
```

### Correct Queries
Must query separate collections with `role` field:

```javascript
// ✅ CORRECT - Use separate collections
const sellers = await getDocs(collection(db, 'sellers'));
const buyers = await getDocs(collection(db, 'buyers'));

// Then filter by role if needed
const activeSellers = sellers.docs.filter(doc => doc.data().role === 'seller' && doc.data().isActive);
```

---

## 5. FIELD NAME CORRECTIONS NEEDED

| What Admin Expects | What Mobile App Uses | Collection |
|-------------------|----------------------|------------|
| `userType: 'buyer'` | `role: 'buyer'` | `buyers` |
| `userType: 'seller'` | `role: 'seller'` | `sellers` |
| Single `users` collection | Separate `buyers` + `sellers` | Different |
| `name` field | `displayName` (sellers only) | `sellers` |
| `status` field | `isActive` boolean | `buyers`, `sellers` |
| `pricing` in products | `pricing` (double, not string) | `products` |
| `startingPrice` in auctions | N/A - starts with `currentBid` | `auctions` |

---

## 6. QUERYING TIPS FOR ADMIN DASHBOARD

### Get All Buyers (Correct)
```javascript
const buyersRef = collection(db, 'buyers');
const buyersSnap = await getDocs(buyersRef);
// buyersSnap.docs.length = total buyers
// Each doc has: email, phoneNumber, role, isActive
```

### Get All Sellers (Correct)
```javascript
const sellersRef = collection(db, 'sellers');
const sellersSnap = await getDocs(sellersRef);
// sellersSnap.docs.length = total sellers
// Each doc has: displayName, businessName, isActive, role
```

### Get Active Sellers Only
```javascript
const sellersRef = collection(db, 'sellers');
const activeSellersQuery = query(sellersRef, where('isActive', '==', true));
const activeSellersSnap = await getDocs(activeSellersQuery);
```

### Get All Products (Approved Only - for customers)
```javascript
const productsRef = collection(db, 'products');
const approvedProductsQuery = query(
  productsRef, 
  where('approvalStatus', '==', 'approved')
);
const approvedSnap = await getDocs(approvedProductsQuery);
```

### Get Pending Product Approvals (for admins)
```javascript
const productsRef = collection(db, 'products');
const pendingProductsQuery = query(
  productsRef,
  where('approvalStatus', '==', 'pending')
);
const pendingSnap = await getDocs(pendingProductsQuery);
```

### Get All Auctions
```javascript
const auctionsRef = collection(db, 'auctions');
const auctionsSnap = await getDocs(auctionsRef);
// Filter approved vs pending on client side
```

---

## 7. ADMIN DASHBOARD DATA DISPLAY CHECKLIST

### Users Tab
- [ ] Query from `buyers` collection (not `users` with `userType`)
- [ ] Query from `sellers` collection separately
- [ ] Display `email`, `phoneNumber`, `isActive` for buyers
- [ ] Display `displayName`, `businessName`, `email`, `isActive` for sellers
- [ ] Show seller verification status (admin can approve/reject)

### Products Tab
- [ ] Query from `products` collection
- [ ] Filter by `approvalStatus` = `"approved"` to show published
- [ ] Show pending approvals separately
- [ ] Display: title, category, pricing, sellerId, status
- [ ] Show `certificateVerificationStatus`

### Auctions Tab
- [ ] Query from `auctions` collection
- [ ] Filter by `approvalStatus` = `"approved"` to show published
- [ ] Show pending approvals separately
- [ ] Calculate status: "Active" if now < endTime, "Ended" if now > endTime
- [ ] Display: title, currentBid, endTime, sellerId, status

---

## 8. NEXT STEPS FOR ADMIN DASHBOARD FIX

1. **Update adminService.js**
   - Change `users` collection queries to `buyers` + `sellers`
   - Use `role` field instead of `userType`
   - Use correct collection field names

2. **Update Dashboard.jsx**
   - Query `buyers` and `sellers` separately
   - Update stat calculations
   - Display correct field names

3. **Update UserManagement.jsx**
   - Filter `sellers` vs `buyers` from separate collections
   - Use `role` field for differentiation
   - Query `sellers` for verification workflow

4. **Test with Real Data**
   - Verify buyer count matches `buyers` collection
   - Verify seller count matches `sellers` collection
   - Verify products display correctly with approval status
   - Verify auctions display with status calculation
