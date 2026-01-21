# GemNest - Complete Use Case Diagram

## Overview
This document contains the complete and corrected use case diagram for the GemNest Mobile App system with all three actors: **Buyer**, **Seller**, and **Admin**.

---

## Complete Use Case Diagram (Classical UML Format)

```mermaid
graph TB
    subgraph System["<b>GemNest E-Commerce System</b>"]
        direction TB
        
        %% Row 1: Authentication
        Login[("Login")]
        Register[("Register")]
        Logout[("Logout")]
        2FA[("Enable 2FA")]
        
        %% Row 2: Browse & Search
        Browse[("Browse Products")]
        BrowseAuc[("Browse Auctions")]
        Search[("Search & Filter")]
        
        %% Row 3: Product Details
        ViewProdDet[("View Product Details")]
        ViewAucDet[("View Auction Details")]
        
        %% Row 4: Cart Management
        AddCart[("Add to Cart")]
        RemoveCart[("Remove from Cart")]
        ViewCart[("View Cart")]
        
        %% Row 5: Bidding
        PlaceBid[("Place Bid")]
        ViewBidHist[("View Bid History")]
        MonitorBids[("Monitor Bids")]
        ViewWinner[("View Winner")]
        
        %% Row 6: Checkout & Payment
        DirectCheckout[("Direct Checkout")]
        AucCheckout[("Auction Checkout")]
        ProcessPayment[("Process Payment")]
        
        %% Row 7: Order Management
        TrackOrder[("Track Order")]
        ViewOrders[("View Orders")]
        UpdateStatus[("Update Order Status")]
        ManageShip[("Manage Shipping")]
        
        %% Row 8: Reviews & Feedback
        LeaveReview[("Leave Review")]
        ViewReviews[("View Reviews")]
        ViewRatings[("View Ratings")]
        
        %% Row 9: Products & Auctions (Seller)
        CreateProduct[("Create Product")]
        EditProduct[("Edit Product")]
        DeleteProduct[("Delete Product")]
        CreateAuc[("Create Auction")]
        EditAuc[("Edit Auction")]
        EndAuc[("End Auction")]
        
        %% Row 10: Seller Inventory & Analytics
        ManageInv[("Manage Inventory")]
        SetPrice[("Set Price")]
        ViewAnalytics[("View Analytics")]
        ViewRevenue[("View Revenue")]
        ManagePromo[("Manage Promotions")]
        
        %% Row 11: Certificates & Documentation
        UploadCert[("Upload Certificate")]
        UploadDocs[("Upload Documents")]
        
        %% Row 12: Admin User Management
        ViewUsers[("View All Users")]
        ViewSellers[("View All Sellers")]
        ViewBuyers[("View All Buyers")]
        VerifySeller[("Verify Seller")]
        ApproveDocs[("Approve Seller Docs")]
        RejectDocs[("Reject Seller Docs")]
        BanUser[("Ban User")]
        SuspendSeller[("Suspend Seller")]
        
        %% Row 13: Admin Content Management
        ApproveProduct[("Approve Product")]
        RejectProduct[("Reject Product")]
        ApproveAuc[("Approve Auction")]
        RejectAuc[("Reject Auction")]
        
        %% Row 14: Admin Dispute & Issue Resolution
        ResolveDisputes[("Resolve Disputes")]
        ProcessRefund[("Process Refunds")]
        HandleComplaints[("Handle Complaints")]
        
        %% Row 15: Admin Analytics & Reports
        ViewAnalyticsAdmin[("View System Analytics")]
        GenerateReports[("Generate Reports")]
        ViewTransactions[("View Transactions")]
        ManageCertTypes[("Manage Certificate Types")]
        
        %% Row 16: Additional
        UpdateProfile[("Update Profile")]
        ViewAccount[("View Account")]
        Chat[("Chat")]
        Favorites[("Manage Favorites")]
        Notify[("View Notifications")]
    end

    %% Actors
    Buyer["👤 BUYER"]
    Seller["🏪 SELLER"]  
    Admin["👨‍💼 ADMIN"]

    %% BUYER CONNECTIONS
    Buyer --> Login
    Buyer --> Register
    Buyer --> Logout
    Buyer --> UpdateProfile
    Buyer --> ViewAccount
    Buyer --> Browse
    Buyer --> BrowseAuc
    Buyer --> Search
    Buyer --> ViewProdDet
    Buyer --> ViewAucDet
    Buyer --> AddCart
    Buyer --> RemoveCart
    Buyer --> ViewCart
    Buyer --> Favorites
    Buyer --> PlaceBid
    Buyer --> ViewBidHist
    Buyer --> DirectCheckout
    Buyer --> AucCheckout
    Buyer --> TrackOrder
    Buyer --> ViewOrders
    Buyer --> LeaveReview
    Buyer --> ViewReviews
    Buyer --> Chat
    Buyer --> Notify

    %% SELLER CONNECTIONS
    Seller --> Login
    Seller --> Register
    Seller --> Logout
    Seller --> UpdateProfile
    Seller --> ViewAccount
    Seller --> 2FA
    Seller --> CreateProduct
    Seller --> EditProduct
    Seller --> DeleteProduct
    Seller --> UploadCert
    Seller --> UploadDocs
    Seller --> SetPrice
    Seller --> ManageInv
    Seller --> CreateAuc
    Seller --> EditAuc
    Seller --> MonitorBids
    Seller --> EndAuc
    Seller --> ViewWinner
    Seller --> ViewOrders
    Seller --> UpdateStatus
    Seller --> ManageShip
    Seller --> ViewAnalytics
    Seller --> ViewRevenue
    Seller --> ViewRatings
    Seller --> ManagePromo
    Seller --> Chat

    %% ADMIN CONNECTIONS
    Admin --> Login
    Admin --> Logout
    Admin --> ViewUsers
    Admin --> ViewSellers
    Admin --> ViewBuyers
    Admin --> VerifySeller
    Admin --> ApproveDocs
    Admin --> RejectDocs
    Admin --> SuspendSeller
    Admin --> BanUser
    Admin --> ApproveProduct
    Admin --> RejectProduct
    Admin --> ApproveAuc
    Admin --> RejectAuc
    Admin --> ResolveDisputes
    Admin --> ProcessRefund
    Admin --> HandleComplaints
    Admin --> ViewAnalyticsAdmin
    Admin --> GenerateReports
    Admin --> ViewTransactions
    Admin --> ManageCertTypes

    %% INCLUDES (System Automatic Processes)
    DirectCheckout -.->|includes| ProcessPayment
    AucCheckout -.->|includes| ProcessPayment

    %% STYLING
    style System fill:#f0f0f0,stroke:#333,stroke-width:3px
    
    style Buyer fill:#c3e9ff,stroke:#0066cc,stroke-width:3px,color:#000
    style Seller fill:#f0d9ff,stroke:#9900cc,stroke-width:3px,color:#000
    style Admin fill:#fff4d9,stroke:#ff9900,stroke-width:3px,color:#000
    
    style Login fill:#fff,stroke:#666,stroke-width:2px
    style Register fill:#fff,stroke:#666,stroke-width:2px
    style Logout fill:#fff,stroke:#666,stroke-width:2px
    
    style ProcessPayment fill:#ffe6e6,stroke:#cc0000,stroke-width:2px,color:#000
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
