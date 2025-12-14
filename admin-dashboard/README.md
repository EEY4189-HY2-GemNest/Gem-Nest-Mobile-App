# GemNest Admin Dashboard

A professional Firebase-backed admin dashboard for managing GemNest users, products, and auctions.

## Features

✅ **Admin Authentication** - Secure Firebase email/password login
✅ **User Management** - View all users, activate/deactivate accounts
✅ **Product Management** - View and remove product listings
✅ **Auction Management** - Monitor active auctions and bidding
✅ **Dashboard Analytics** - Real-time statistics and metrics
✅ **Responsive Design** - Works on desktop and tablets

## Project Structure

```
admin-dashboard/
├── src/
│   ├── components/
│   │   ├── Dashboard.jsx          # Main dashboard with stats
│   │   ├── UserManagement.jsx     # User activation/deactivation
│   │   ├── ProductManagement.jsx  # Product listing management
│   │   └── AuctionManagement.jsx  # Auction monitoring
│   ├── pages/
│   │   ├── LoginPage.jsx          # Admin login
│   │   └── DashboardPage.jsx      # Main dashboard layout
│   ├── services/
│   │   ├── firebase.js            # Firebase initialization
│   │   └── adminService.js        # Admin API functions
│   ├── App.jsx                    # Main app component
│   ├── main.jsx                   # React entry point
│   └── index.css                  # Global styles
├── public/                        # Static assets
├── index.html                     # HTML entry point
├── package.json                   # Dependencies
├── vite.config.js                 # Vite configuration
├── tailwind.config.js             # Tailwind CSS config
└── .env.example                   # Environment variables template
```

## Getting Started

### Prerequisites

- Node.js 16+ and npm
- Firebase project with Firestore enabled
- Admin account set up in Firebase

### Installation

1. **Navigate to the admin-dashboard directory:**
   ```bash
   cd admin-dashboard
   npm install
   ```

2. **Create `.env.local` file** (copy from `.env.example`):
   ```bash
   cp .env.example .env.local
   ```

3. **Fill in Firebase credentials** in `.env.local`:
   - Get these from Firebase Console → Project Settings
   - Find your config in the "Your apps" section

4. **Set up admin user in Firestore:**
   - Go to Firebase Console → Firestore Database
   - Create collection: `admins`
   - Create document with user UID as ID
   - Add any fields (example: `{ name: "Admin", email: "admin@gemnest.com" }`)

### Running the Development Server

```bash
npm run dev
```

Server will start at `http://localhost:3000`

### Building for Production

```bash
npm run build
```

Output files will be in `dist/` folder

## Usage

### Admin Login

1. Navigate to `http://localhost:3000/login`
2. Enter admin email and password (set up in Firebase Authentication)
3. Must have admin record in `admins` collection in Firestore

### Managing Users

- **View Users**: Click "Users" in sidebar
- **Activate Account**: Click "Activate" button (for deactivated users)
- **Deactivate Account**: Click "Deactivate" button (for active users)
- **Search**: Filter users by email or name

### Managing Products

- **View Products**: Click "Products" in sidebar
- **Remove Product**: Click "Remove" button on product card
- **Search**: Filter products by name

### Monitoring Auctions

- **View Auctions**: Click "Auctions" in sidebar
- **Status Types**:
  - 🟢 Active: Auction currently running
  - 🔵 Upcoming: Auction hasn't started
  - ⚫ Ended: Auction has finished

## Firebase Setup

### Firestore Collections Structure

```
users/
├── {userId}
│   ├── email: string
│   ├── name: string
│   ├── isActive: boolean
│   ├── status: string (active, deactivated)
│   └── userType: string (buyer, seller)

products/
├── {productId}
│   ├── name: string
│   ├── description: string
│   ├── price: number
│   ├── imageUrl: string
│   ├── sellerId: string
│   └── isActive: boolean

auctions/
├── {auctionId}
│   ├── productName: string
│   ├── startingPrice: number
│   ├── currentBid: number
│   ├── totalBids: number
│   ├── startTime: timestamp
│   ├── endTime: timestamp
│   └── description: string

admins/
├── {adminUserId}
│   ├── email: string
│   ├── name: string
│   └── role: string (admin)
```

### Security Rules (Firestore)

Add these rules to restrict admin access:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admins can only read from admins collection
    match /admins/{document=**} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/admins/$(request.auth.uid)).data;
      allow write: if false; // Prevent writes via client
    }
    
    // Users collection - Admins can manage
    match /users/{userId} {
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
    
    // Products collection - Admins can manage
    match /products/{productId} {
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
    
    // Auctions collection - Admins can read
    match /auctions/{auctionId} {
      allow read: if isAdmin();
    }
    
    // Helper function
    function isAdmin() {
      return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
  }
}
```

## Environment Variables

Create a `.env.local` file in the `admin-dashboard` directory:

```
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
```

## Deployment

### Firebase Hosting

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize Firebase:**
   ```bash
   firebase init
   ```
   - Select "Hosting"
   - Set public directory to `dist`
   - Configure as SPA (rewrite all URLs to index.html)

3. **Build and Deploy:**
   ```bash
   npm run build
   firebase deploy
   ```

### Vercel

1. Push code to GitHub
2. Connect to Vercel at vercel.com
3. Select the `admin-dashboard` folder as root
4. Add environment variables in Vercel dashboard
5. Deploy!

### Netlify

1. Connect GitHub repo to Netlify
2. Set build command: `npm run build`
3. Set publish directory: `dist`
4. Add environment variables
5. Deploy!

## Troubleshooting

### "Not authorized as admin" Error
- Check admin record exists in Firestore `admins` collection
- Ensure document ID matches user's Firebase UID

### Firestore Data Not Loading
- Check Firestore security rules allow admin access
- Verify collections exist with correct names
- Check browser console for Firebase errors

### Environment Variables Not Loading
- Ensure `.env.local` file exists (not `.env`)
- Restart dev server after changing `.env.local`
- Variables must start with `VITE_` to be accessible

### Styling Issues (Dark Theme)
- Clear browser cache
- Check Tailwind CSS is compiled properly
- Verify dark theme colors in `tailwind.config.js`

## Technologies Used

- **React 18** - UI framework
- **Vite** - Build tool
- **Firebase** - Backend (Auth, Firestore, Storage)
- **Tailwind CSS** - Styling
- **React Router** - Navigation
- **Lucide Icons** - Icons

## Support

For issues or questions:
1. Check Firestore security rules
2. Review Firebase Console logs
3. Check browser developer console for errors
4. Verify admin credentials and permissions

## License

GemNest © 2025
