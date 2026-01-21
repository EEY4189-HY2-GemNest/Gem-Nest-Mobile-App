# GemNest - Complete Use Case Diagram

## Overview
This document contains the complete and corrected use case diagram for the GemNest Mobile App system with all three actors: **Buyer**, **Seller**, and **Admin**.

---

## Complete Use Case Diagram (Mermaid)

```mermaid
graph TB
    subgraph Actors
        Buyer["👤 Buyer"]
        Seller["🏪 Seller"]
        Admin["👨‍💼 Admin"]
    end

    subgraph "Authentication & Account Management"
        Register["Register Account"]
        Login["Login"]
        UpdateProfile["Update Profile"]
        UpdatePaymentInfo["Update Payment Method"]
        ViewAccount["View Account Details"]
        TwoFactorAuth["Enable 2FA"]
        ResetPassword["Reset Password"]
        Logout["Logout"]
    end

    subgraph "Buyer Use Cases"
        BrowseProducts["Browse Products"]
        BrowseAuctions["Browse Auctions"]
        SearchFilter["Search & Filter"]
        ViewProductDetails["View Product Details"]
        ViewAuctionDetails["View Auction Details"]
        AddToCart["Add to Cart"]
        RemoveFromCart["Remove from Cart"]
        ViewCart["View Cart"]
        PlaceBid["Place Bid on Auction"]
        ViewBidHistory["View Bid History"]
        DirectCheckout["Direct Purchase (Checkout)"]
        AuctionCheckout["Win Auction & Checkout"]
        ProcessPayment["Process Payment"]
        TrackOrder["Track Order"]
        ViewOrders["View Order History"]
        LeaveReview["Leave Review & Rating"]
        ViewReviews["View Seller Reviews"]
        ViewNotifications["View Notifications"]
        ManageFavorites["Add/Remove Favorites"]
        ViewChat["Chat with Seller"]
    end

    subgraph "Seller Use Cases"
        CreateProduct["Create Product Listing"]
        EditProduct["Edit Product Details"]
        DeleteProduct["Delete Product"]
        UploadCertificate["Upload Gem Certificate"]
        SetProductPrice["Set Product Price"]
        ManageInventory["Manage Inventory"]
        
        CreateAuction["Create Auction"]
        EditAuction["Edit Auction Details"]
        SetAuctionPrice["Set Starting Price"]
        SetAuctionDuration["Set Auction Duration"]
        
        MonitorBids["Monitor Auction Bids"]
        EndAuction["End Auction Manually"]
        ViewWinner["View Auction Winner"]
        
        ViewOrders["View Orders Received"]
        UpdateOrderStatus["Update Order Status"]
        ManageShipping["Manage Shipping Methods"]
        
        ViewAnalytics["View Sales Analytics"]
        ViewRevenue["View Revenue Report"]
        ViewRatings["View Customer Ratings"]
        
        ViewChat["Chat with Buyers"]
        RespondToQuestions["Respond to Questions"]
        ManagePromotions["Create Discount Promotions"]
    end

    subgraph "Admin Use Cases"
        ViewAllUsers["View All Users"]
        ViewAllSellers["View All Sellers"]
        ViewAllBuyers["View All Buyers"]
        
        VerifySeller["Verify Seller Account"]
        ApproveSellerDocs["Approve Seller Documents"]
        RejectSellerDocs["Reject Seller Documents"]
        SuspendSeller["Suspend Seller Account"]
        BanUser["Ban User Account"]
        UnbanUser["Unban User Account"]
        
        ApproveProduct["Approve Product Listing"]
        RejectProduct["Reject Product Listing"]
        ReviewProductCompliance["Review Product Compliance"]
        RemoveProduct["Remove Inappropriate Product"]
        
        ApproveAuction["Approve Auction"]
        RejectAuction["Reject Auction"]
        ReviewAuctionDetails["Review Auction Details"]
        
        ResolveDisputes["Resolve Disputes"]
        ResolveRefunds["Process Refunds"]
        HandleComplaints["Handle Customer Complaints"]
        
        ViewSystemAnalytics["View System Analytics"]
        GenerateReports["Generate Reports"]
        ViewTransactions["View All Transactions"]
        ViewPayments["View Payment Records"]
        
        ManageContent["Manage Content & FAQs"]
        SendAnnouncements["Send Announcements"]
        ManageUsers["Manage User Access"]
        UploadCertificateTypes["Manage Gem Certificate Types"]
    end

    subgraph "System Processes (Automatic)"
        AutoCheckout["💻 System: Auto-Calculate Totals"]
        AutoTax["💻 System: Calculate Tax & Fees"]
        AutoShipping["💻 System: Calculate Shipping"]
        AutoPaymentProcess["💻 System: Process Payment Gateway"]
        AutoInventoryUpdate["💻 System: Update Inventory"]
        AutoNotifyBuyer["💻 System: Notify Buyer"]
        AutoNotifySeller["💻 System: Notify Seller"]
        AutoAuctionEnd["💻 System: End Auction at Time"]
        AutoWinner["💻 System: Determine & Notify Winner"]
        AutoOrderCreate["💻 System: Create Order Record"]
        AutoEmailConfirm["💻 System: Send Confirmation Email"]
    end

    %% Buyer Connections
    Buyer --> Register
    Buyer --> Login
    Buyer --> UpdateProfile
    Buyer --> UpdatePaymentInfo
    Buyer --> ViewAccount
    Buyer --> BrowseProducts
    Buyer --> BrowseAuctions
    Buyer --> SearchFilter
    Buyer --> ViewProductDetails
    Buyer --> ViewAuctionDetails
    Buyer --> AddToCart
    Buyer --> RemoveFromCart
    Buyer --> ViewCart
    Buyer --> ManageFavorites
    Buyer --> PlaceBid
    Buyer --> ViewBidHistory
    Buyer --> DirectCheckout
    Buyer --> AuctionCheckout
    Buyer --> TrackOrder
    Buyer --> ViewOrders
    Buyer --> LeaveReview
    Buyer --> ViewReviews
    Buyer --> ViewNotifications
    Buyer --> ViewChat
    Buyer --> Logout

    %% Seller Connections
    Seller --> Register
    Seller --> Login
    Seller --> UpdateProfile
    Seller --> ViewAccount
    Seller --> TwoFactorAuth
    
    Seller --> CreateProduct
    Seller --> EditProduct
    Seller --> DeleteProduct
    Seller --> UploadCertificate
    Seller --> SetProductPrice
    Seller --> ManageInventory
    
    Seller --> CreateAuction
    Seller --> EditAuction
    Seller --> SetAuctionPrice
    Seller --> SetAuctionDuration
    
    Seller --> MonitorBids
    Seller --> EndAuction
    Seller --> ViewWinner
    
    Seller --> ViewOrders
    Seller --> UpdateOrderStatus
    Seller --> ManageShipping
    
    Seller --> ViewAnalytics
    Seller --> ViewRevenue
    Seller --> ViewRatings
    
    Seller --> ViewChat
    Seller --> RespondToQuestions
    Seller --> ManagePromotions
    Seller --> Logout

    %% Admin Connections
    Admin --> Login
    Admin --> ViewAllUsers
    Admin --> ViewAllSellers
    Admin --> ViewAllBuyers
    
    Admin --> VerifySeller
    Admin --> ApproveSellerDocs
    Admin --> RejectSellerDocs
    Admin --> SuspendSeller
    Admin --> BanUser
    Admin --> UnbanUser
    
    Admin --> ApproveProduct
    Admin --> RejectProduct
    Admin --> ReviewProductCompliance
    Admin --> RemoveProduct
    
    Admin --> ApproveAuction
    Admin --> RejectAuction
    Admin --> ReviewAuctionDetails
    
    Admin --> ResolveDisputes
    Admin --> ResolveRefunds
    Admin --> HandleComplaints
    
    Admin --> ViewSystemAnalytics
    Admin --> GenerateReports
    Admin --> ViewTransactions
    Admin --> ViewPayments
    
    Admin --> ManageContent
    Admin --> SendAnnouncements
    Admin --> ManageUsers
    Admin --> UploadCertificateTypes
    Admin --> Logout

    %% System Process Inclusions (showing automatic system involvement)
    DirectCheckout -.->|includes| AutoCheckout
    DirectCheckout -.->|includes| AutoTax
    DirectCheckout -.->|includes| AutoShipping
    DirectCheckout -.->|includes| AutoPaymentProcess
    DirectCheckout -.->|includes| AutoInventoryUpdate
    DirectCheckout -.->|includes| AutoNotifyBuyer
    DirectCheckout -.->|includes| AutoNotifySeller
    DirectCheckout -.->|includes| AutoOrderCreate
    DirectCheckout -.->|includes| AutoEmailConfirm

    AuctionCheckout -.->|includes| AutoCheckout
    AuctionCheckout -.->|includes| AutoTax
    AuctionCheckout -.->|includes| AutoShipping
    AuctionCheckout -.->|includes| AutoPaymentProcess
    AuctionCheckout -.->|includes| AutoInventoryUpdate
    AuctionCheckout -.->|includes| AutoNotifyBuyer
    AuctionCheckout -.->|includes| AutoNotifySeller
    AuctionCheckout -.->|includes| AutoOrderCreate
    AuctionCheckout -.->|includes| AutoEmailConfirm

    CreateAuction -.->|extends| AutoAuctionEnd
    MonitorBids -.->|extends| AutoWinner

    style Buyer fill:#e1f5ff
    style Seller fill:#f3e5f5
    style Admin fill:#fff3e0
    style AutoCheckout fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoTax fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoShipping fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoPaymentProcess fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoInventoryUpdate fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoNotifyBuyer fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoNotifySeller fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoAuctionEnd fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoWinner fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoOrderCreate fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
    style AutoEmailConfirm fill:#ffebee,stroke:#d32f2f,stroke-width:2px,stroke-dasharray: 5 5
```

---

## Key Corrections Made

### 1. **Checkout as System Automatic Process** ✅
- **Before**: Checkout was a simple actor action
- **After**: Checkout now includes automatic system processes:
  - Auto-calculate totals, tax, and shipping
  - System processes payments through gateway
  - System updates inventory automatically
  - System creates order records
  - System sends notifications to both parties
  - System sends confirmation emails

### 2. **Separated Direct Purchase from Auction Checkout** ✅
- `DirectCheckout`: Regular product purchase
- `AuctionCheckout`: Winning an auction then checkout
- Both trigger the same automatic system processes

### 3. **Added Missing Use Cases**

#### **Buyer Use Cases Added:**
- ✅ View Bid History
- ✅ Manage Favorites
- ✅ Chat with Seller
- ✅ View Seller Reviews
- ✅ Search & Filter

#### **Seller Use Cases Added:**
- ✅ Monitor Auction Bids
- ✅ View Auction Winner
- ✅ View Order History
- ✅ Create Discount Promotions
- ✅ Respond to Questions
- ✅ Chat with Buyers
- ✅ Upload Gem Certificates

#### **Admin Use Cases Added:**
- ✅ Approve/Reject Seller Documents
- ✅ Resolve Disputes
- ✅ Process Refunds
- ✅ Handle Customer Complaints
- ✅ View All Transactions
- ✅ Upload Certificate Types
- ✅ Send Announcements
- ✅ Manage User Access

### 4. **Automatic System Processes (Highlighted in Red Dashed Box)** 💻
These represent backend processes that happen automatically without direct user action:
- Payment processing
- Order creation
- Inventory updates
- Notifications
- Auction timing & winner determination

---

## Actor Descriptions

### 👤 **BUYER**
- Browse and search products/auctions
- Add items to cart
- Place bids on auctions
- Initiate checkout (system handles rest)
- Track orders
- Rate sellers and leave reviews
- Communicate with sellers
- Manage account and payment methods

### 🏪 **SELLER**
- Create and manage product listings
- Create and manage auctions
- Upload gem certificates and documentation
- Monitor bids and auction activity
- View and update order status
- Track sales and revenue
- Communicate with buyers
- View analytics and performance metrics
- Manage promotions and pricing

### 👨‍💼 **ADMIN**
- Verify and approve seller accounts
- Approve/reject products and auctions
- Review seller documentation
- Resolve disputes and complaints
- Process refunds
- View system-wide analytics
- Manage user access and permissions
- Handle moderation and account suspension
- Generate reports
- Manage content and announcements

---

## Use Case Categories

| Category | Count | Examples |
|----------|-------|----------|
| **Authentication** | 8 | Register, Login, 2FA, Reset Password, etc. |
| **Buyer Use Cases** | 20 | Browse, Search, Bid, Checkout, Track, Review |
| **Seller Use Cases** | 20 | Create Product/Auction, Monitor, Analyze, Chat |
| **Admin Use Cases** | 24 | Verify, Approve, Resolve, Report, Manage |
| **System Auto Processes** | 11 | Payment, Inventory, Notifications, Winner |
| **Total** | **83** | Complete system coverage |

---

## Important Notes

### ✅ **Checkout is System-Driven**
The checkout process is now correctly modeled as:
1. User initiates checkout
2. **System automatically:**
   - Calculates totals, tax, shipping
   - Processes payment
   - Updates inventory
   - Creates order record
   - Sends notifications
   - Sends confirmation email

### ✅ **Auction Automation**
- System automatically ends auctions at scheduled time
- System determines and notifies winner
- Winner can then proceed to checkout (triggering the same automatic processes)

### ✅ **Separated Concerns**
- Authentication flows (shared by all actors)
- Actor-specific use cases (Buyer/Seller/Admin)
- Automatic system processes (shown as dependencies)

---

## Recommendations for Implementation

1. **Use `.includes` relationships** for automatic system processes
2. **Use `.extends` relationships** for optional extensions
3. **Document API endpoints** that trigger each use case
4. **Map database operations** to each use case
5. **Define error handling** for system processes (payment failures, etc.)

---

*This use case diagram provides a complete and accurate representation of the GemNest system with all three actors and their interactions with automatic system processes clearly separated.*
