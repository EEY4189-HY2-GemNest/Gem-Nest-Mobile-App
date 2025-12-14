# Firebase Firestore Rules for Admin Dashboard

Copy these rules to your Firebase Firestore Security Rules section.

## Rules Version

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ==================== HELPER FUNCTIONS ====================
    
    function isAdmin() {
      return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    function isSeller() {
      return exists(/databases/$(database)/documents/sellers/$(request.auth.uid));
    }

    function isBuyer() {
      return exists(/databases/$(database)/documents/buyers/$(request.auth.uid));
    }

    function isActiveSeller() {
      return isSeller() 
        && get(/databases/$(database)/documents/sellers/$(request.auth.uid)).data.isActive == true;
    }
    
    // ==================== ADMIN RULES ====================
    
    // Only admins can access their own admin record
    match /admins/{adminId} {
      allow read: if request.auth.uid == adminId;
      allow write: if false; // Prevent client-side writes
    }
    
    // ==================== USERS COLLECTION ====================
    
    // Admin can manage all users
    match /users/{userId} {
      allow read: if isAdmin() || request.auth.uid == userId;
      allow update: if isAdmin() || request.auth.uid == userId;
      allow create: if false; // Only created through Flutter app or backend
      allow delete: if false; // Use deactivation instead
    }
    
    // ==================== SELLERS COLLECTION ====================
    
    match /sellers/{userId} {
      // Allow authenticated users to read
      allow read: if request.auth != null;
      // Admin can update seller status
      allow update: if isAdmin();
      // Allow users to create their own seller profile
      allow create: if request.auth != null && request.auth.uid == userId;
      // No delete permission
      allow delete: if false;
    }

    // ==================== BUYERS COLLECTION ====================
    
    match /buyers/{userId} {
      // Allow authenticated users to read their own buyer profile
      allow read: if request.auth != null && request.auth.uid == userId;
      // Allow users to create/update their own buyer profile
      allow create, update: if request.auth != null && request.auth.uid == userId;
      // No delete permission
      allow delete: if false;
    }

    // ==================== PRODUCTS COLLECTION ====================
    
    match /products/{productId} {
      // Admin can read all products
      // Authenticated users can read active products
      allow read: if isAdmin() || (request.auth != null && resource.data.isActive == true);
      
      // Admin can update (deactivate/manage)
      allow update: if isAdmin();
      
      // Only active sellers can create products
      allow create: if request.auth != null 
        && isSeller() 
        && isActiveSeller();
      
      // Allow deletion only by the seller who created it or admin
      allow delete: if isAdmin() || (request.auth != null 
        && isSeller() 
        && isActiveSeller() 
        && resource.data.sellerId == request.auth.uid);
    }

    // ==================== AUCTIONS COLLECTION ====================
    
    match /auctions/{auctionId} {
      // Admin can read all auctions
      // Authenticated users can read active auctions
      allow read: if isAdmin() || (request.auth != null && resource.data.isActive == true);
      
      // Allow authenticated users to update their bids if they are the winning bidder or placing a new bid
      allow update: if request.auth != null &&
                    (resource.data.winningUserId == request.auth.uid ||
                     request.resource.data.currentBid > resource.data.currentBid);
      
      // Prevent unauthorized creation of auctions (only admins or server should create)
      allow create: if false;
      
      // Prevent deletion
      allow delete: if false;
    }

    // ==================== ORDERS COLLECTION ====================
    
    match /orders/{orderId} {
      // Allow authenticated users to read their own orders
      allow read: if request.auth != null 
        && (isAdmin() || resource.data.buyerId == request.auth.uid || resource.data.sellerId == request.auth.uid);
      
      // Allow buyers to create orders
      allow create: if request.auth != null && isBuyer();
      
      // Allow buyers to update their own orders, sellers to update orders they're involved in
      allow update: if request.auth != null 
        && (isAdmin() || (isBuyer() && resource.data.buyerId == request.auth.uid) 
            || (isSeller() && isActiveSeller() && resource.data.sellerId == request.auth.uid));
      
      // Allow deletion only by the buyer who created it
      allow delete: if request.auth != null 
        && isBuyer() 
        && resource.data.buyerId == request.auth.uid;
    }

    // ==================== PAYMENTS COLLECTION ====================
    
    match /payments/{paymentId} {
      // Allow authenticated users to create payment records
      allow create: if request.auth != null;
      
      // Allow read only for the user who initiated the payment or admin
      allow read: if request.auth != null && (isAdmin() || resource.data.userId == request.auth.uid);
      
      // Prevent updates or deletes
      allow update, delete: if false;
    }

    // ==================== DEFAULT DENY ====================
    
    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Implementation Steps

1. **Go to Firebase Console**
   - Select your GemNest project
   - Navigate to Firestore Database
   - Click on "Rules" tab

2. **Replace existing rules** with the code above

3. **Click "Publish"** to apply the rules

## Key Features

✅ **Admin-only access** to user/product management
✅ **Prevents unauthorized writes** to Firestore
✅ **User can read own profile**
✅ **Public read access** to active products/auctions
✅ **Backend operations** protected

## Creating Admin Users

To add a new admin:

1. Go to Firebase Authentication
2. Create new user with email/password
3. Copy the user's UID
4. Go to Firestore
5. Create document in `admins` collection with UID as ID:

```json
{
  "email": "admin@gemnest.com",
  "name": "Admin User",
  "role": "admin",
  "createdAt": "timestamp"
}
```

## Testing Rules

Use Firebase Emulator Suite to test rules locally:

```bash
# Install Firebase Emulator
firebase init emulator

# Start emulator
firebase emulators:start
```

Then run tests against local Firestore.
