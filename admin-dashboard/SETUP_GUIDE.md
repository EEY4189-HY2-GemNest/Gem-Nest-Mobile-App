# Admin Dashboard - Quick Setup Guide

## 📋 Prerequisites

- Node.js 16+ installed
- Firebase project created
- Firestore database set up
- Admin user created in Firebase Authentication

## 🚀 Quick Start (5 minutes)

### Step 1: Install Dependencies
```bash
cd admin-dashboard
npm install
```

### Step 2: Get Firebase Credentials
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your GemNest project
3. Click ⚙️ → Project Settings
4. Scroll to "Your apps" section
5. Find or create a Web app
6. Copy the config object

### Step 3: Create Environment File
```bash
cp .env.example .env.local
```

Edit `.env.local` and paste your Firebase config:
```
VITE_FIREBASE_API_KEY=your_api_key_here
VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
```

### Step 4: Create Admin User

1. **In Firebase Console:**
   - Go to Authentication
   - Create new user (email/password)
   - Copy the User UID

2. **In Firestore:**
   - Create collection: `admins`
   - Create document with UID as ID
   - Add field: `{ email: "admin@gemnest.com" }`

### Step 5: Update Firestore Rules

Copy rules from [FIRESTORE_RULES.md](./FIRESTORE_RULES.md) and paste in Firebase Console → Firestore → Rules

### Step 6: Run Development Server
```bash
npm run dev
```

Visit `http://localhost:3000` and login with admin credentials

## 🎯 Features

| Feature | Location |
|---------|----------|
| 📊 Dashboard Stats | Homepage after login |
| 👥 User Management | Sidebar → Users |
| 📦 Product Management | Sidebar → Products |
| 🔨 Auction Monitor | Sidebar → Auctions |

## 🔑 Key Functions

### User Management
- **Activate Account** - Re-enable deactivated user
- **Deactivate Account** - Suspend user from using app
- **Search** - Find users by email or name

### Product Management
- **View Products** - See all listed products
- **Remove Product** - Deactivate product listing
- **Search** - Find products by name

### Auction Monitoring
- **View Active** - See ongoing auctions
- **Check Status** - Active/Upcoming/Ended
- **Monitor Bids** - Track current highest bid

## 📁 Firestore Collections Required

```
admins/
├── {user_uid}
│   └── email: string

users/
├── {user_id}
│   ├── email: string
│   ├── name: string
│   ├── isActive: boolean

products/
├── {product_id}
│   ├── name: string
│   ├── price: number
│   ├── isActive: boolean

auctions/
├── {auction_id}
│   ├── productName: string
│   ├── startingPrice: number
│   ├── endTime: timestamp
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Login fails | Check admin user exists in `admins` collection |
| No users showing | Verify users exist in Firestore |
| Dark theme not working | Clear browser cache and restart |
| "Not authorized" | Verify Firestore security rules are updated |

## 📦 Deploy to Production

### Firebase Hosting
```bash
npm run build
firebase deploy
```

### Vercel
```bash
npm run build
vercel
```

### Netlify
```bash
npm run build
netlify deploy --prod --dir=dist
```

## 📞 Support

For more detailed information, see [README.md](./README.md)

---

**Built with React + Firebase + Tailwind CSS** 🎨
