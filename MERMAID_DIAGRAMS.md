# GemNest Mobile App - Complete Mermaid Diagrams

## 1. CLASS DIAGRAM

```mermaid
classDiagram
    class User {
        +String userId
        +String email
        +String password
        +String userType (buyer/seller)
        +bool isActive
        +DateTime createdAt
        +authenticate()
        +logout()
    }

    class Buyer {
        +String buyerId
        +String name
        +String phone
        +String address
        +List~CartItem~ cart
        +List~Order~ orders
        +addToCart()
        +checkout()
        +placeBid()
    }

    class Seller {
        +String sellerId
        +String businessName
        +String businessRegistration
        +String nicDocument
        +List~Product~ products
        +List~Auction~ auctions
        +bool isVerified
        +bool isActive
        +String verificationStatus
        +createProduct()
        +createAuction()
        +viewAnalytics()
    }

    class Product {
        +String productId
        +String title
        +String description
        +String category
        +double price
        +double discountedPrice
        +String imageUrl
        +int quantity
        +String sellerId
        +List~GemCertificate~ certificates
        +List~String~ deliveryMethods
        +String approvalStatus
        +DateTime createdAt
        +getDetails()
        +updatePrice()
        +getHighestBid()
    }

    class Auction {
        +String auctionId
        +String title
        +String description
        +String category
        +double startingPrice
        +double currentBid
        +String sellerUserId
        +String winningUserId
        +DateTime startTime
        +DateTime endTime
        +List~Bid~ bidHistory
        +String imageUrl
        +List~GemCertificate~ gemCertificates
        +String certificateVerificationStatus
        +String approvalStatus
        +bool isActive
        +Duration timeRemaining
        +getHighestBid()
        +getBidsSortedByAmount()
        +getRecentBids()
        +endAuction()
    }

    class Bid {
        +String bidderId
        +double bidAmount
        +DateTime timestamp
        +String bidderName
        +toMap()
        +fromMap()
    }

    class CartItem {
        +String productId
        +String title
        +double price
        +int quantity
        +String category
        +String sellerId
        +int availableStock
        +bool isSelected
        +bool isDiscounted
        +double discountPercentage
        +Map~String,dynamic~ productData
        +getTotal()
        +updateQuantity()
    }

    class Order {
        +String orderId
        +String buyerId
        +String sellerId
        +List~CartItem~ items
        +double totalAmount
        +double taxAmount
        +double shippingCost
        +String deliveryMethod
        +String status (pending/confirmed/shipped/delivered)
        +DateTime createdAt
        +DateTime deliveredAt
        +String paymentStatus
        +createOrder()
        +confirmOrder()
        +trackOrder()
    }

    class Payment {
        +String paymentId
        +String orderId
        +String buyerId
        +double amount
        +String paymentMethod (stripe/paypal)
        +String status (pending/completed/failed)
        +DateTime timestamp
        +String transactionId
        +processPayment()
        +refund()
    }

    class GemNestNotification {
        +String notificationId
        +String userId
        +String title
        +String body
        +NotificationType type
        +String imageUrl
        +Map~String,dynamic~ data
        +DateTime createdAt
        +DateTime readAt
        +String actionUrl
        +String sellerId
        +String buyerId
        +String auctionId
        +String productId
        +String orderId
        +bool isRead
        +toMap()
        +fromMap()
        +fromRemoteMessage()
    }

    class GemCertificate {
        +String certificateId
        +String productId
        +String certificateNumber
        +String issuer
        +DateTime issueDate
        +String verificationStatus
        +String certificateUrl
        +verifyCertificate()
    }

    class CartProvider {
        -List~CartItem~ _cartItems
        -List~CartItem~ _wishlistItems
        -String _appliedCouponCode
        -double _couponDiscount
        -double _shippingCost
        +addToCart()
        +removeFromCart()
        +updateQuantity()
        +clearCart()
        +applyCoupon()
        +saveCartToLocal()
        +loadCartFromLocal()
        +getCartTotal()
    }

    class NotificationService {
        -FirebaseMessaging _messaging
        +initialize()
        +setupMessageHandlers()
        +sendNotification()
        +handleNotificationTap()
        +getNotificationStream()
    }

    class FirebaseService {
        -FirebaseFirestore _db
        -FirebaseAuth _auth
        +addProduct()
        +getProducts()
        +addAuction()
        +getAuctions()
        +placeBid()
        +updateUserProfile()
        +getOrderHistory()
    }

    class StripeService {
        -Stripe _stripe
        +initialize()
        +processPayment()
        +handlePaymentResult()
        +refundPayment()
    }

    class BannerProvider {
        -List~Banner~ _banners
        +fetchBanners()
        +updateBanner()
    }

    %% Relationships
    User <|-- Buyer
    User <|-- Seller
    Seller "1" --o "*" Product : creates
    Seller "1" --o "*" Auction : creates
    Buyer "1" --o "*" CartItem : contains
    Buyer "1" --o "*" Order : creates
    Buyer "1" --o "*" Bid : places
    Order "1" --o "*" CartItem : contains
    Order "1" -- "1" Payment : has
    Auction "1" --o "*" Bid : contains
    Product "1" --o "*" GemCertificate : has
    Auction "1" --o "*" GemCertificate : has
    GemNestNotification "*" -- "1" Buyer : notifies
    GemNestNotification "*" -- "1" Seller : notifies
    CartProvider "1" --o "*" CartItem : manages
    FirebaseService -- Product
    FirebaseService -- Auction
    FirebaseService -- Order
    NotificationService -- GemNestNotification
    StripeService -- Payment
```

---

## 2. ACTIVITY DIAGRAM

```mermaid
activity
    title GemNest Mobile App - Main User Flows

    start
    fork
        :User Signup/Login;
        if (User Type?) then
            :Is Buyer;
            :Access Buyer Dashboard;
            fork
                :Browse Products;
                :View Product Details;
                :Add to Cart;
                :Proceed to Checkout;
                :Process Payment with Stripe;
                :Create Order;
                :Receive Order Confirmation;
                :Track Delivery;
            and
                :Browse Auctions;
                :View Auction Details;
                :Place Bid;
                :Monitor Auction;
                if (Win Auction?) then
                    :Win Notification;
                    :Complete Payment;
                else
                    :Outbid Notification;
                endif
            and
                :View Notifications;
                :Check Order History;
                :Manage Profile;
            endfork
        else (Is Seller)
            :Access Seller Dashboard;
            fork
                :Create Product Listing;
                :Upload Product Image;
                :Fill Product Details;
                :Add Gem Certificates;
                :Submit for Approval;
                :Wait for Admin Review;
                if (Approved?) then
                    :Product Listed;
                    :Monitor Sales;
                else
                    :Approval Rejected;
                    :View Rejection Reason;
                endif
            and
                :Create Auction;
                :Set Auction Details;
                :Set Start/End Time;
                :Submit for Approval;
                :Monitor Bids;
                if (Auction Ends?) then
                    :Mark Winner;
                    :Process Payment;
                else
                    :View Active Bids;
                endif
            and
                :View Seller Analytics;
                :Manage Orders;
                :Handle Customer Messages;
            endfork
        endif
    and
        :Admin Login;
        :Access Admin Dashboard;
        fork
            :Review Pending Products;
            :Approve/Reject Products;
            :Record Decision;
        and
            :Review Pending Auctions;
            :Approve/Reject Auctions;
            :Record Decision;
        and
            :Manage Users;
            :Verify Sellers;
            :Activate/Deactivate Accounts;
        and
            :View Analytics;
            :Monitor Platform Stats;
        endfork
    endfork

    :Send Notifications;
    :Update Database;
    end

```

---

## 3. ACTIVITY DIAGRAM - PRODUCT PURCHASE FLOW

```mermaid
activity
    title Product Purchase & Order Management Flow

    start
    :Buyer Views Home Screen;
    :Browse 4 Popular Gems;
    :Select Product;
    :View Product Details Screen;
    
    fork
        :View Full Product Info;
        :View Images & Certificates;
        :Check Seller Info;
    and
        :Contact Seller Options;
        fork
            :Call Seller;
        or
            :Message via WhatsApp;
        endfork
    and
        :Add to Cart Actions;
        :Select Quantity;
        :Add Item to Cart;
    endfork
    
    :Proceed to Cart;
    :View Cart Items;
    :Apply Coupon (Optional);
    :Review Order Summary;
    :Confirm Order;
    :Proceed to Checkout;
    :Enter Shipping Address;
    :Select Delivery Method;
    :Process Payment via Stripe;
    
    if (Payment Successful?) then
        :Payment Confirmed;
        :Create Order Record;
        :Save Order to Firestore;
        :Send Order Confirmation;
        :Notify Seller;
        :Clear Cart;
        :Show Order Success Screen;
    else
        :Payment Failed;
        :Show Error Message;
        :Retry Payment Option;
    endif
    
    :Order Created;
    :Seller Prepares Order;
    :Update Order Status to Shipped;
    :Send Shipping Notification;
    :Buyer Receives Tracking Info;
    :Package Delivered;
    :Update Order Status to Delivered;
    :Send Delivery Notification;
    :Order Complete;
    end

```

---

## 4. ACTIVITY DIAGRAM - AUCTION FLOW

```mermaid
activity
    title Auction Lifecycle & Bidding Flow

    start
    :Seller Creates Auction;
    :Fill Auction Details;
    :Set Starting Price;
    :Set End Time;
    :Upload Auction Image;
    :Submit for Approval;
    
    if (Admin Approves?) then
        :Auction Listed;
        :Set Status: Active;
    else
        :Auction Rejected;
        :Notify Seller;
        :End Process;
    endif
    
    :Auction Goes Live;
    :Display Countdown Timer;
    :Show Current Bid;
    :Show Bidding History;
    
    fork
        :Buyer Views Auction;
        :View Auction Details;
        :Check Bid History;
        :Monitor Time Remaining;
    and
        repeat
            :Buyer Places Bid;
            :Validate Bid Amount;
            if (Bid Valid?) then
                :Update Current Bid;
                :Add to Bid History;
                :Notify Previous Bidder;
            else
                :Show Validation Error;
            endif
        repeat
    endfork
    
    :Auction End Time Reached;
    :Close Bidding;
    :Determine Winner;
    :Notify Winning Bidder;
    
    if (Winner Confirms?) then
        :Create Order;
        :Process Payment;
        if (Payment Successful?) then
            :Mark Auction Won;
            :Notify Seller;
            :Initiate Shipping;
        else
            :Payment Failed;
            :Contact Winning Bidder;
        endif
    else
        :Cancel Transaction;
    endif
    
    :Auction Complete;
    end

```

---

## 5. ACTIVITY DIAGRAM - NOTIFICATION FLOW

```mermaid
activity
    title Push Notification & Approval System

    start
    fork
        :Product/Auction Approval Flow;
        :Seller Submits Item;
        :Item Status: Pending;
        :Admin Reviews Item;
        
        if (Admin Decision?) then (Approved)
            :Update Approval Status;
            :Send Approval Notification;
            :List Item Publicly;
        else (Rejected)
            :Update Status: Rejected;
            :Send Rejection Notification;
            :Include Rejection Reason;
        endif
    and
        :Auction Activity Notifications;
        :Bid Placed;
        fork
            :Notify Previous Bidder: Outbid;
        and
            :Notify Seller: New Bid;
        endfork
        :Auction Ending Soon;
        :Notify Active Bidders;
    and
        :Order Status Notifications;
        :Order Confirmed;
        :Notify Buyer & Seller;
        :Order Shipped;
        :Notify Buyer with Tracking;
        :Order Delivered;
        :Notify Buyer;
    and
        :Payment Notifications;
        :Payment Received;
        :Send Receipt;
        :Payment Failed;
        :Send Retry Instructions;
    endfork
    
    :Notification Service;
    :Prepare Notification Object;
    :Send via Firebase Cloud Messaging;
    :Store in Firestore;
    :Display in App Notification Center;
    :User Receives Notification;
    
    if (User Taps Notification?) then
        :Navigate to Relevant Screen;
        :Show Details;
    else
        :Mark as Read;
    endif
    
    end

```

---

## 6. ER DIAGRAM (Entity Relationship Diagram)

```mermaid
erDiagram
    USERS ||--o{ BUYERS : registers
    USERS ||--o{ SELLERS : registers
    USERS ||--o{ ADMINS : registers
    SELLERS ||--o{ PRODUCTS : creates
    SELLERS ||--o{ AUCTIONS : creates
    PRODUCTS ||--o{ GEM_CERTIFICATES : has
    AUCTIONS ||--o{ GEM_CERTIFICATES : has
    PRODUCTS ||--o{ REVIEWS : receives
    BUYERS ||--o{ CART_ITEMS : maintains
    CART_ITEMS }o--|| PRODUCTS : references
    BUYERS ||--o{ ORDERS : places
    ORDERS ||--o{ CART_ITEMS : contains
    ORDERS ||--o{ PAYMENTS : processes
    BUYERS ||--o{ BIDS : places
    BIDS }o--|| AUCTIONS : belongs_to
    AUCTIONS ||--o{ BIDS : contains
    USERS ||--o{ NOTIFICATIONS : receives
    SELLERS ||--o{ SELLER_NOTIFICATIONS : receives
    BUYERS ||--o{ BUYER_NOTIFICATIONS : receives
    PRODUCTS ||--o{ DELIVERY_METHODS : has
    ORDERS ||--o{ DELIVERY_METHODS : uses
    ADMINS ||--o{ APPROVALS : manages

    USERS {
        string userId PK
        string email UK
        string password
        string userType
        boolean isActive
        datetime createdAt
        datetime updatedAt
    }

    BUYERS {
        string buyerId PK
        string userId FK
        string firstName
        string lastName
        string phone
        string address
        string city
        string postalCode
        string country
        datetime createdAt
    }

    SELLERS {
        string sellerId PK
        string userId FK
        string businessName
        string businessRegistration
        string nicDocument
        boolean isVerified
        string verificationStatus
        boolean isActive
        datetime activatedAt
        datetime createdAt
    }

    ADMINS {
        string adminId PK
        string userId FK
        string adminRole
        datetime createdAt
    }

    PRODUCTS {
        string productId PK
        string sellerId FK
        string title
        string description
        string category
        double price
        double discountedPrice
        string imageUrl
        int quantity
        string approvalStatus
        datetime createdAt
        datetime updatedAt
    }

    AUCTIONS {
        string auctionId PK
        string sellerId FK
        string title
        string description
        string category
        double startingPrice
        double currentBid
        datetime startTime
        datetime endTime
        string winningUserId FK
        string imageUrl
        string approvalStatus
        datetime createdAt
        datetime updatedAt
    }

    GEM_CERTIFICATES {
        string certificateId PK
        string productId FK
        string certificateNumber
        string issuer
        datetime issueDate
        string verificationStatus
        string certificateUrl
    }

    BIDS {
        string bidId PK
        string auctionId FK
        string bidderId FK
        double bidAmount
        datetime timestamp
    }

    ORDERS {
        string orderId PK
        string buyerId FK
        string sellerId FK
        double totalAmount
        double taxAmount
        double shippingCost
        string status
        string paymentStatus
        datetime createdAt
        datetime deliveredAt
    }

    CART_ITEMS {
        string cartItemId PK
        string buyerId FK
        string productId FK
        int quantity
        boolean isSelected
        boolean isDiscounted
        double discountPercentage
    }

    PAYMENTS {
        string paymentId PK
        string orderId FK
        double amount
        string paymentMethod
        string status
        string transactionId
        datetime timestamp
    }

    REVIEWS {
        string reviewId PK
        string productId FK
        string buyerId FK
        int rating
        string reviewText
        datetime createdAt
    }

    NOTIFICATIONS {
        string notificationId PK
        string userId FK
        string title
        string body
        string notificationType
        boolean isRead
        datetime createdAt
        datetime readAt
    }

    SELLER_NOTIFICATIONS {
        string notificationId PK
        string sellerId FK
        string title
        string body
        string notificationType
        string auctionId FK
        string productId FK
        boolean isRead
        datetime createdAt
    }

    BUYER_NOTIFICATIONS {
        string notificationId PK
        string buyerId FK
        string title
        string body
        string notificationType
        string auctionId FK
        string productId FK
        string orderId FK
        boolean isRead
        datetime createdAt
    }

    DELIVERY_METHODS {
        string deliveryMethodId PK
        string methodName
        double cost
        int estimatedDays
    }

    APPROVALS {
        string approvalId PK
        string adminId FK
        string itemId
        string itemType
        string decision
        string rejectionReason
        datetime approvedAt
    }
```

---

## Diagram Summary

### 📊 Class Diagram
Shows all core classes and their relationships:
- **User Types**: User, Buyer, Seller
- **Marketplace Entities**: Product, Auction, Bid
- **Transaction Management**: Order, Payment, CartItem
- **System Services**: NotificationService, FirebaseService, StripeService
- **Data Models**: GemNestNotification, GemCertificate

### 🔄 Activity Diagrams
1. **Main User Flows**: Buyer, Seller, and Admin workflows
2. **Product Purchase**: Complete shopping flow from browsing to delivery
3. **Auction Flow**: Auction creation, bidding, and completion
4. **Notification System**: Approval, order, and activity notifications

### 💾 ER Diagram
Complete database schema showing:
- **User Management**: Users, Buyers, Sellers, Admins
- **Product Management**: Products, Auctions, GemCertificates
- **Transaction Management**: Orders, Payments, Carts
- **Activity Tracking**: Bids, Reviews, Notifications
- **System Data**: DeliveryMethods, Approvals

All diagrams are production-ready and represent the complete GemNest Mobile App architecture!
