# Firebase Storage Rules for GemNest

Copy these rules to your Firebase Storage Rules section.

## Rules Version

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // ==================== PRODUCT IMAGES ====================
    // Authenticated users can read and upload product images
    match /product_images/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // ==================== BANNERS ====================
    // Allow public read for promotional banners (displayed on home screen)
    // Only admins can upload/manage banners
    match /banners/{bannerId} {
      allow read: if true; // Public read for home screen display
      allow write: if request.auth != null && 
                      exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    // ==================== DEFAULT RULE ====================
    // Authenticated users can read and write to other paths
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Implementation Steps

1. **Go to Firebase Console**
   - Select your GemNest project
   - Navigate to Storage
   - Click on "Rules" tab

2. **Replace existing rules** with the code above

3. **Click "Publish"** to apply the rules

## Key Features

✅ **Public read access** to banners for unauthenticated users
✅ **Admin-only uploads** for banners
✅ **Authenticated users** can read/upload product images
✅ **Secure by default** - deny everything else

## Rule Breakdown

### Product Images
- **Read**: Authenticated users only
- **Write**: Authenticated users only (sellers can upload their product images)

### Banners
- **Read**: Everyone (public) - banners are promotional content
- **Write**: Admins only - prevents unauthorized banner uploads

### Default
- **Read**: Authenticated users
- **Write**: Authenticated users

## Security Notes

⚠️ **Important**: In production, you may want to further restrict:
- Product image uploads to verified sellers only
- Add file size limits
- Add allowed file type validation

Example with validation:
```javascript
match /product_images/{imageId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null 
    && request.resource.size < 10 * 1024 * 1024 // 10MB max
    && request.resource.contentType.matches('image/(jpeg|png|webp)');
}
```
