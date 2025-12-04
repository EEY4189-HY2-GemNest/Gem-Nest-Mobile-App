# 💎 GemNest - Luxury Auction Mobile App

**GemNest** is a sophisticated Flutter-based mobile application that brings the excitement of luxury auctions to your fingertips. Designed to connect buyers and sellers in a premium marketplace, GemNest offers a seamless auction experience with real-time bidding, secure payments, and elegant user interfaces.

## 🌟 Features

### 🛍️ For Buyers
- **Real-time Auction Participation**: Join live auctions with countdown timers and instant bid updates
- **Smart Bidding System**: Place bids with minimum increment validation and automatic updates
- **Secure Payment Gateway**: Complete transactions safely with multiple payment options
- **Auction History**: Track your bidding history and won auctions
- **Profile Management**: Manage your personal information and preferences
- **Category Browsing**: Explore products by categories with detailed views
- **Cart & Wishlist**: Save items for later and manage your purchases

### 🏪 For Sellers
- **Product Listing**: List luxury items with high-quality images and detailed descriptions
- **Auction Management**: Create and manage auctions with custom duration and minimum bids
- **Real-time Monitoring**: Track auction progress and bidder activity
- **Order Management**: Handle order fulfillment and customer communications
- **Analytics Dashboard**: View sales performance and auction statistics
- **Profile Customization**: Build your seller profile with brand information

### 🔧 Technical Features
- **Firebase Integration**: Real-time database, authentication, and cloud storage
- **Offline Capability**: Local data storage with SQLite
- **Push Notifications**: Stay updated on auction activities
- **Image Processing**: Optimized image handling and caching
- **Responsive Design**: Beautiful UI across different device sizes
- **State Management**: Efficient app state handling with Provider pattern

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── firebase_service.dart              # Firebase service wrapper
├── home_screen.dart                   # Main dashboard
├── splash_screen.dart                 # App launch screen
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
│   │   └── auction_payment_screen.dart# Payment processing
│   ├── auth_screens/                  # Authentication flows
│   ├── cart_screen/                   # Shopping cart functionality
│   ├── category_screen/               # Product categories
│   ├── checkout_screen/               # Order checkout
│   ├── order_history_screen/          # Purchase history
│   ├── payment_screen/                # Payment methods
│   ├── product_screen/                # Product details
│   └── profile_screen/                # User profile management
├── 
├── Seller/
│   ├── auction_product.dart           # Auction item creation
│   ├── listed_auction_screen.dart     # Seller's auction list
│   ├── listed_product_screen.dart     # Seller's product list
│   ├── notifications_page.dart        # Seller notifications
│   ├── order_details_screen.dart      # Order management
│   ├── order_history_screen.dart      # Sales history
│   ├── product_listing.dart           # Product creation
│   ├── seller_home_page.dart          # Seller dashboard
│   └── seller_profile_screen.dart     # Seller profile
├── 
└── widget/
    ├── category_card.dart             # Category display components
    └── custom_dialog.dart             # Custom dialog widgets
```

### Technology Stack
- **Framework**: Flutter 3.2.3+
- **State Management**: Provider Pattern
- **Backend**: Firebase (Firestore, Auth, Storage, Database)
- **Local Storage**: SQLite
- **Image Handling**: Image Picker, Cached Network Images
- **UI Components**: Material Design 3, Custom Animations
- **Build System**: Gradle (Android), Xcode (iOS)

## 📱 Screenshots & Demo

### Core Functionality
- **Real-time Bidding**: Live auction participation with countdown timers
- **Payment Processing**: Secure payment gateway with delivery options
- **Seller Dashboard**: Comprehensive tools for auction and product management
- **User Profiles**: Customizable profiles for buyers and sellers
- **Category Navigation**: Intuitive product discovery

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
- Firebase Authentication integration
- Secure user session management
- Multi-factor authentication support

### Data Security
- Encrypted data transmission
- Secure payment processing
- User data privacy protection

### Business Logic Security
```dart
// Bid validation example
bool validateBid(double newBid, double currentBid, double minIncrement) {
  return newBid >= (currentBid + minIncrement);
}
```

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
- [x] Basic payment processing
- [x] Seller dashboard

### Phase 2 - Enhanced Features 🚧
- [ ] Advanced search and filters
- [ ] Push notification system
- [ ] Social sharing features
- [ ] Multi-language support

### Phase 3 - Premium Features 📅
- [ ] Video auction streaming
- [ ] AI-powered recommendations
- [ ] Advanced analytics
- [ ] Enterprise seller tools

## 🐛 Known Issues

### Current Limitations
- Image upload size optimization needed
- Limited offline functionality
- iOS push notification setup pending

### Bug Reports
Please report bugs using GitHub Issues with:
- Device information
- Flutter version
- Steps to reproduce
- Expected vs actual behavior

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
