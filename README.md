# 💎 GemNest - Luxury Auction Mobile App

**GemNest** is a sophisticated Flutter-based mobile application that brings the excitement of luxury auctions to your fingertips. Designed to connect buyers and sellers in a premium marketplace, GemNest offers a seamless auction experience with real-time bidding, secure payments, and elegant user interfaces.

## 🌟 Features

### 🛍️ For Buyers
- **Real-time Auction Participation**: Join live auctions with countdown timers and instant bid updates
- **Smart Bidding System**: Place bids with minimum increment validation and automatic updates
- **Secure Payment Gateway**: Complete transactions safely with multiple payment options via Stripe
- **Auction History**: Track your bidding history and won auctions
- **Profile Management**: Manage your personal information and preferences
- **Category Browsing**: Explore products by categories with detailed views
- **Cart & Wishlist**: Save items for later and manage your purchases
- **Enhanced Product Details**: View comprehensive product information with certificates and seller contact options
- **Direct Seller Communication**: One-click phone call and WhatsApp messaging to sellers
- **Real-time Notifications**: Receive instant push notifications for auction updates and bids

### 🏪 For Sellers
- **Product Listing**: List luxury items with high-quality images and detailed descriptions
- **Auction Management**: Create and manage auctions with custom duration and minimum bids
- **Real-time Monitoring**: Track auction progress and bidder activity with live updates
- **Order Management**: Handle order fulfillment and customer communications
- **Analytics Dashboard**: View sales performance and auction statistics
- **Profile Customization**: Build your seller profile with brand information
- **Seller Notifications**: Real-time alerts for new bids, orders, and important activities
- **Order History Tracking**: Monitor all past orders and sales

### 🛡️ Admin Dashboard Features
- **Secure Admin Authentication**: Firebase-backed email/password login with role-based access
- **User Management**: View all users, activate/deactivate accounts, and manage user status
- **Product Management**: Monitor product listings, remove inappropriate items
- **Auction Monitoring**: Track active auctions, bidding activity, and auction status
- **Real-time Analytics**: Dashboard with comprehensive statistics and metrics
- **Responsive Interface**: Works seamlessly on desktop and tablet devices
- **Firestore Integration**: Secure data management with proper security rules

### 🔧 Technical Features
- **Firebase Integration**: Real-time database, authentication, cloud storage, and cloud functions
- **Push Notifications**: Firebase Cloud Messaging (FCM) for real-time alerts across mobile and web
- **Offline Capability**: Local data storage with SQLite for seamless offline experience
- **Image Processing**: Optimized image handling and caching with error management
- **Responsive Design**: Beautiful UI across different device sizes and platforms
- **State Management**: Efficient app state handling with Provider pattern
- **Payment Integration**: Stripe integration for secure payment processing
- **Multi-platform Support**: Native Android, iOS, and web admin dashboard

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── firebase_service.dart              # Firebase service wrapper
├── home_screen.dart                   # Main dashboard
├── splash_screen.dart                 # App launch screen
├── checkout_service.dart              # Checkout service
├── stripe_service.dart                # Stripe payment integration
├── stripe_config.dart                 # Stripe configuration
├── 
├── Database/
│   └── db_helper.dart                 # SQLite database helper
├── 
├── providers/
│   └── banner_provider.dart           # State management for banners
├── 
├── screen/
│   ├── auction_screen/
│   │   ├── auction_screen.dart        # Main auction interface
│   │   ├── auction_details_screen.dart# Detailed auction view
│   │   └── auction_payment_screen.dart# Payment processing
│   ├── auth_screens/                  # Authentication flows
│   ├── cart_screen/                   # Shopping cart functionality
│   ├── category_screen/               # Product categories
│   ├── checkout_screen/               # Order checkout
│   ├── order_history_screen/          # Purchase history
│   ├── payment_screen/                # Payment methods
│   ├── product_screen/
│   │   ├── product_details_screen.dart# Detailed product view with seller info
│   │   └── product_screen.dart        # Product listing
│   └── profile_screen/                # User profile management
├── 
├── Seller/
│   ├── auction_product.dart           # Auction item creation
│   ├── listed_auction_screen.dart     # Seller's auction list
│   ├── listed_product_screen.dart     # Seller's product list
│   ├── notifications_page.dart        # Seller push notifications
│   ├── order_details_screen.dart      # Order management
│   ├── order_history_screen.dart      # Sales history
│   ├── product_listing.dart           # Product creation
│   ├── seller_home_page.dart          # Seller dashboard
│   └── seller_profile_screen.dart     # Seller profile
├── 
└── widget/
    ├── category_card.dart             # Category display components
    └── custom_dialog.dart             # Custom dialog widgets

admin-dashboard/
├── src/
│   ├── components/
│   │   ├── Dashboard.jsx              # Main dashboard with analytics
│   │   ├── UserManagement.jsx         # User management interface
│   │   ├── ProductManagement.jsx      # Product management interface
│   │   └── AuctionManagement.jsx      # Auction monitoring interface
│   ├── pages/
│   │   ├── LoginPage.jsx              # Admin login page
│   │   └── DashboardPage.jsx          # Main dashboard layout
│   ├── services/
│   │   ├── firebase.js                # Firebase initialization
│   │   └── adminService.js            # Admin API functions
│   ├── App.jsx                        # Main app component
│   ├── main.jsx                       # React entry point
│   └── index.css                      # Global styles
├── public/                            # Static assets
├── index.html                         # HTML entry point
├── package.json                       # Dependencies
├── vite.config.js                     # Vite configuration
├── tailwind.config.js                 # Tailwind CSS config
└── SETUP_GUIDE.md                     # Admin dashboard setup guide
```

### Technology Stack
- **Framework**: 
  - Mobile: Flutter 3.2.3+
  - Admin: React with Vite, Tailwind CSS
- **State Management**: Provider Pattern (Flutter)
- **Backend**: Firebase (Firestore, Auth, Storage, Database, Cloud Functions, Cloud Messaging)
- **Local Storage**: SQLite
- **Image Handling**: Image Picker, Cached Network Images
- **UI Components**: Material Design 3, Custom Animations
- **Payment Integration**: Stripe for secure transactions
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Build System**: Gradle (Android), Xcode (iOS), Vite (Admin Dashboard)

## 📱 Screenshots & Demo

### Core Functionality
- **Real-time Bidding**: Live auction participation with countdown timers
- **Payment Processing**: Secure payment gateway with delivery options via Stripe
- **Seller Dashboard**: Comprehensive tools for auction and product management
- **User Profiles**: Customizable profiles for buyers and sellers
- **Category Navigation**: Intuitive product discovery
- **Product Details**: Enhanced product view with seller contact information
- **Auction Details**: Detailed auction information with real-time countdown and bidding stats
- **Push Notifications**: Real-time alerts for bids, orders, and auction updates

## 🆕 New Features

### Enhanced Product & Auction Details
- **Detailed Product Information**: View comprehensive product specifications with images, price, stock, and detailed descriptions
- **Seller Contact Integration**: Direct phone and WhatsApp communication buttons with seller contact details
- **Gem Certificates**: View and access gem authentication certificates with direct links
- **Auction Timer**: Real-time countdown timer for active auctions with live status updates
- **Bidding Information**: View current bid, starting bid, and total bid count
- **Enhanced Navigation**: Seamless navigation from product lists to detailed views

### Push Notification System
- **Real-time Alerts**: Instant notifications for new bids, orders, and auction updates
- **Multi-platform Support**: Notifications across mobile (buyer/seller) and admin dashboard
- **Firebase Cloud Functions**: Automated notification triggers for auction events
- **Notification History**: Persistent storage of notifications for user review
- **Local Notifications**: Display notifications with proper handling on Android and iOS

### Admin Dashboard Web Application
- **Complete Management Interface**: Professional React-based admin dashboard
- **User Management**: Activate/deactivate user accounts, search users
- **Product Oversight**: Monitor and remove product listings
- **Auction Tracking**: Real-time auction monitoring and statistics
- **Analytics Dashboard**: View platform statistics and key metrics
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Secure Authentication**: Firebase-backed admin authentication
- **Firestore Integration**: Secure database rules and data management

## 🚀 Installation & Setup

### Prerequisites
- Flutter SDK (3.2.3 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Android/iOS device or emulator

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-repo/gem-nest-mobile-app.git
cd gem-nest-mobile-app
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Firebase Configuration
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication, Firestore, and Storage
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place configuration files in their respective platform folders:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### Step 4: Configure Firebase Services
```dart
// Firestore Collections Structure:
- users/               # User profiles
- sellers/             # Seller profiles  
- auctions/            # Auction listings
- products/            # Product catalog
- orders/              # Purchase orders
- notifications/       # Push notifications
```

### Step 5: Run the Application
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

## 🛡️ Admin Dashboard Setup

The GemNest Admin Dashboard is a professional web-based management interface built with React and Vite for managing users, products, and auctions.

### Prerequisites for Admin Dashboard
- Node.js 16+ and npm
- Firebase project with Firestore enabled
- Admin account set up in Firebase

### Quick Start

#### Step 1: Navigate to Admin Dashboard
```bash
cd admin-dashboard
npm install
```

#### Step 2: Configure Firebase
1. Create `.env.local` file:
   ```bash
   cp .env.example .env.local
   ```

2. Add your Firebase credentials (from Firebase Console → Project Settings):
   ```
   VITE_FIREBASE_API_KEY=your_api_key_here
   VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=your_project_id
   VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
   VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   VITE_FIREBASE_APP_ID=your_app_id
   ```

#### Step 3: Set Up Admin User in Firebase
1. Go to Firebase Console → Authentication → Create new user (email/password)
2. Copy the User UID
3. In Firestore, create collection `admins`
4. Create document with UID as ID and add field: `{ email: "admin@gemnest.com" }`

#### Step 4: Update Firestore Security Rules
Copy security rules from [admin-dashboard/FIRESTORE_RULES.md](admin-dashboard/FIRESTORE_RULES.md) and apply in Firebase Console

#### Step 5: Run Admin Dashboard
```bash
npm run dev
```
Access at `http://localhost:3000` and login with admin credentials

### Admin Dashboard Features
| Feature | Location |
|---------|----------|
| 📊 Dashboard Analytics | Homepage after login |
| 👥 User Management | Sidebar → Users |
| 📦 Product Management | Sidebar → Products |
| 🔨 Auction Monitor | Sidebar → Auctions |

For detailed admin dashboard documentation, see [admin-dashboard/SETUP_GUIDE.md](admin-dashboard/SETUP_GUIDE.md)

## 🔧 Configuration

### Environment Setup
Create environment-specific configuration files:

```yaml
# pubspec.yaml - Key dependencies
dependencies:
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1
  cloud_firestore: ^5.6.5
  firebase_storage: ^12.4.4
  provider: ^6.1.2
  image_picker: ^1.0.8
  sqflite: ^2.3.3+1
  cached_network_image: ^3.4.1
```

### Firebase Security Rules
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /auctions/{auctionId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /sellers/{sellerId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == sellerId;
    }
  }
}
```

## 🎯 Usage Guide

### For Buyers

#### 1. Account Registration
- Sign up using email/password
- Complete profile setup
- Verify account credentials

#### 2. Browsing & Bidding
```dart
// Navigate to auctions
Navigator.push(context, 
  MaterialPageRoute(builder: (context) => AuctionScreen())
);

// Place a bid
await _placeBid(auctionId, bidAmount);
```

#### 3. Payment Processing
- Select winning auctions
- Choose delivery options (pickup/delivery)
- Complete secure payment

### For Sellers

#### 1. Seller Registration
- Create seller account
- Complete business profile
- Upload verification documents

#### 2. Product Management
```dart
// Create auction
await FirebaseFirestore.instance
    .collection('auctions')
    .add({
      'title': title,
      'currentBid': startingBid,
      'endTime': endTime,
      'sellerId': currentUser.uid,
    });
```

#### 3. Order Fulfillment
- Monitor auction progress
- Process winning bids
- Handle shipping/delivery

## 🔒 Security Features

### Authentication
- Firebase Authentication integration with email/password
- Secure user session management
- Admin role-based access control
- Multi-factor authentication support

### Data Security
- Encrypted data transmission over HTTPS
- Secure payment processing with Stripe
- User data privacy protection with Firestore security rules
- Sensitive credentials stored in environment variables

### Business Logic Security
```dart
// Bid validation example
bool validateBid(double newBid, double currentBid, double minIncrement) {
  return newBid >= (currentBid + minIncrement);
}

// User authorization for seller operations
bool isSellerAuthorized(String userId, String sellerId) {
  return userId == sellerId;
}
```

## 📬 Push Notifications System

### Overview
GemNest uses Firebase Cloud Messaging (FCM) for real-time push notifications across:
- **Mobile App**: Buyer and Seller notifications
- **Admin Dashboard**: Management alerts and updates

### Notification Types

#### Buyer Notifications
- Auction bid placed by another user
- Auction won notification
- Order status updates
- Payment confirmations
- Seller messages

#### Seller Notifications
- New bid on auction
- Product approved/rejected
- Order received
- Order shipped
- New product review

#### Admin Notifications
- Suspicious activity alerts
- High-value transaction alerts
- System status updates

### Setup Instructions

1. **Enable Firebase Cloud Messaging**:
   - Go to Firebase Console → Project Settings
   - Download and configure `google-services.json` (Android)
   - Download and configure `GoogleService-Info.plist` (iOS)

2. **Create Firestore Collections**:
   ```
   users/{userId}
   ├── fcmToken (string)
   ├── fcmTokenUpdatedAt (timestamp)
   └── notifications (subcollection)
       ├── {notificationId}
       ├── title
       ├── body
       ├── type
       ├── createdAt
       ├── isRead
   ```

3. **Deploy Cloud Functions**:
   - Located in `functions/` directory
   - Deploy using: `firebase deploy --only functions`

For complete push notification setup, see [documents/FIREBASE_PUSH_NOTIFICATIONS_COMPLETE.md](documents/FIREBASE_PUSH_NOTIFICATIONS_COMPLETE.md)

## 🧪 Testing

### Unit Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Integration Testing
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Testing Structure
```
test/
├── unit/
│   ├── models/
│   ├── services/
│   └── utils/
├── widget/
│   └── widget_test.dart
└── integration/
    └── app_test.dart
```

## 📦 Build & Deployment

### Android Build
```bash
# Generate APK
flutter build apk --release

# Generate App Bundle
flutter build appbundle --release
```

### iOS Build
```bash
# Build for iOS
flutter build ios --release

# Archive for App Store
flutter build ipa
```

### Deployment Checklist
- [ ] Update version numbers
- [ ] Configure app signing
- [ ] Test on multiple devices
- [ ] Verify Firebase configuration
- [ ] Update app store metadata

## 🤝 Contributing

We welcome contributions to GemNest! Please follow these guidelines:

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow Flutter/Dart style guidelines
- Add documentation for public APIs
- Include unit tests for new features
- Maintain consistent formatting

### Commit Message Format
```
type(scope): brief description

detailed explanation if needed
```

## 📋 Roadmap

### Phase 1 - Core Features ✅
- [x] User authentication system
- [x] Real-time auction functionality
- [x] Basic payment processing with Stripe
- [x] Seller dashboard
- [x] Product and auction details screens
- [x] Admin dashboard for platform management

### Phase 2 - Enhanced Features ✅
- [x] Push notification system (Firebase Cloud Messaging)
- [x] Real-time seller notifications
- [x] Buyer notification system
- [x] Detailed product views with seller contact info
- [x] Auction details with countdown timers
- [x] Admin user and product management

### Phase 3 - Premium Features 🚧
- [ ] Advanced search and filters with AI
- [ ] Social sharing features
- [ ] Multi-language support
- [ ] Video auction streaming
- [ ] AI-powered recommendation engine
- [ ] Advanced seller analytics
- [ ] Enterprise seller tools
- [ ] Mobile app dark mode

## 🐛 Known Issues

### Current Limitations
- Image upload size optimization in progress
- Offline product caching features in development
- Web notifications on iOS require PWA setup
- Admin dashboard mobile responsiveness enhancements pending

### Resolved Issues
- ✅ Push notifications now working on both Android and iOS
- ✅ Product details screen fully implemented with seller contact
- ✅ Auction details with real-time countdown timers complete
- ✅ Admin dashboard authentication and management features complete

### Bug Reports
Please report bugs using GitHub Issues with:
- Device information (OS, device model)
- Flutter/Node version
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots or logs if applicable

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support & Contact

### Development Team
- **Project Lead**: GemNest Development Team
- **Email**: support@gemnest.com
- **GitHub**: [EEY4189-HY2-GemNest](https://github.com/EEY4189-HY2-GemNest)

### Community
- **Discord**: [Join our community](https://discord.gg/gemnest)
- **Documentation**: [Wiki Pages](https://github.com/EEY4189-HY2-GemNest/gem-nest-mobile-app/wiki)
- **Issues**: [Report bugs](https://github.com/EEY4189-HY2-GemNest/gem-nest-mobile-app/issues)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design team for UI guidelines
- Open source community for valuable packages

---

**Made with ❤️ by the GemNest Team**

*Transform the way luxury items are bought and sold through premium mobile auctions.*
