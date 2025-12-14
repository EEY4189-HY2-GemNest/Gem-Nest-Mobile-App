# Firebase Firestore Rules for Admin Dashboard

Copy these rules to your Firebase Firestore Security Rules section.

## Rules Version

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    // Only admins can access their own admin record
    match /admins/{adminId} {
      allow read: if request.auth.uid == adminId;
      allow write: if false; // Prevent client-side writes
    }
    
    // Only admins can manage users
    match /users/{userId} {
      allow read: if isAdmin();
      allow update: if isAdmin();
      allow create: if false; // Only created through Flutter app or backend
      allow delete: if false; // Use deactivation instead
    }
    
    // Only admins can manage products
    match /products/{productId} {
      allow read: if isAdmin();
      allow update: if isAdmin();
      allow create: if false;
      allow delete: if false;
    }
    
    // Only admins can read auctions
    match /auctions/{auctionId} {
      allow read: if isAdmin();
      allow write: if false; // Only written by backend/Cloud Functions
    }
    
    // Regular users can read their own profile
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
    }
    
    // Everyone authenticated can read active products
    match /products/{productId} {
      allow read: if request.auth != null && resource.data.isActive == true;
    }
    
    // Everyone authenticated can read active auctions
    match /auctions/{auctionId} {
      allow read: if request.auth != null && resource.data.isActive == true;
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
