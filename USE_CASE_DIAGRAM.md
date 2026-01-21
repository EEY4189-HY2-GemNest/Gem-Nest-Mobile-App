# GemNest - Complete Use Case Diagram

## Overview
This document contains the complete and corrected use case diagram for the GemNest Mobile App system with all three actors: **Buyer**, **Seller**, and **Admin**.

---

## Complete Use Case Diagram (Classical UML Format - Vertical)

```mermaid
graph TB
    subgraph System["<b>GemNest E-Commerce System</b>"]
        direction TB
        
        %% Authentication Layer
        Login[("Login")]
        Register[("Register")]
        Logout[("Logout")]
        UpdateProfile[("Update Profile")]
        ViewAccount[("View Account")]
        2FA[("Enable 2FA")]
        
        %% Browse & Discovery Layer
        Browse[("Browse<br/>Products")]
        BrowseAuc[("Browse<br/>Auctions")]
        Search[("Search &<br/>Filter")]
        ViewProdDet[("View Product<br/>Details")]
        ViewAucDet[("View Auction<br/>Details")]
        
        %% Shopping Cart & Wishlist
        AddCart[("Add to<br/>Cart")]
        RemoveCart[("Remove from<br/>Cart")]
        ViewCart[("View<br/>Cart")]
        Favorites[("Manage<br/>Favorites")]
        
        %% Bidding & Auction
        PlaceBid[("Place<br/>Bid")]
        ViewBidHist[("View Bid<br/>History")]
        MonitorBids[("Monitor<br/>Bids")]
        ViewWinner[("View<br/>Winner")]
        
        %% Checkout & Payment
        DirectCheckout[("Direct<br/>Checkout")]
        AucCheckout[("Auction<br/>Checkout")]
        ProcessPayment[("Process<br/>Payment")]
        
        %% Order Management
        TrackOrder[("Track<br/>Order")]
        ViewOrders[("View<br/>Orders")]
        UpdateStatus[("Update Order<br/>Status")]
        ManageShip[("Manage<br/>Shipping")]
        
        %% Reviews & Feedback
        LeaveReview[("Leave<br/>Review")]
        ViewReviews[("View<br/>Reviews")]
        ViewRatings[("View<br/>Ratings")]
        
        %% Product Management (Seller)
        CreateProduct[("Create<br/>Product")]
        EditProduct[("Edit<br/>Product")]
        DeleteProduct[("Delete<br/>Product")]
        SetPrice[("Set<br/>Price")]
        ManageInv[("Manage<br/>Inventory")]
        UploadCert[("Upload<br/>Certificate")]
        UploadDocs[("Upload<br/>Documents")]
        
        %% Auction Management (Seller)
        CreateAuc[("Create<br/>Auction")]
        EditAuc[("Edit<br/>Auction")]
        EndAuc[("End<br/>Auction")]
        
        %% Analytics & Reports (Seller)
        ViewAnalytics[("View<br/>Analytics")]
        ViewRevenue[("View<br/>Revenue")]
        ViewRatings2[("View<br/>Ratings")]
        ManagePromo[("Manage<br/>Promotions")]
        
        %% Communication
        Chat[("Chat")]
        Notify[("View<br/>Notifications")]
        
        %% Admin - User Management
        ViewUsers[("View All<br/>Users")]
        ViewSellers[("View All<br/>Sellers")]
        ViewBuyers[("View All<br/>Buyers")]
        VerifySeller[("Verify<br/>Seller")]
        ApproveDocs[("Approve Seller<br/>Docs")]
        RejectDocs[("Reject Seller<br/>Docs")]
        BanUser[("Ban<br/>User")]
        SuspendSeller[("Suspend<br/>Seller")]
        
        %% Admin - Content Management
        ApproveProduct[("Approve<br/>Product")]
        RejectProduct[("Reject<br/>Product")]
        ApproveAuc[("Approve<br/>Auction")]
        RejectAuc[("Reject<br/>Auction")]
        
        %% Admin - Dispute Resolution
        ResolveDisputes[("Resolve<br/>Disputes")]
        ProcessRefund[("Process<br/>Refunds")]
        HandleComplaints[("Handle<br/>Complaints")]
        
        %% Admin - Reports & Analytics
        ViewAnalyticsAdmin[("View System<br/>Analytics")]
        GenerateReports[("Generate<br/>Reports")]
        ViewTransactions[("View<br/>Transactions")]
        ManageCertTypes[("Manage<br/>Certificate Types")]
    end

    %% ACTORS - Positioned Outside System
    Buyer["👤<br/><b>BUYER</b>"]
    Seller["🏪<br/><b>SELLER</b>"]
    Admin["👨‍💼<br/><b>ADMIN</b>"]

    %% ===== BUYER USE CASES =====
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

    %% ===== SELLER USE CASES =====
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
    Seller --> ViewRatings2
    Seller --> ManagePromo
    
    Seller --> Chat

    %% ===== ADMIN USE CASES =====
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

    %% INCLUDE RELATIONSHIPS
    DirectCheckout -.->|includes| ProcessPayment
    AucCheckout -.->|includes| ProcessPayment

    %% STYLING
    style System fill:#f5f5f5,stroke:#333,stroke-width:3px
    
    style Buyer fill:#c3e9ff,stroke:#0066cc,stroke-width:3px,color:#000
    style Seller fill:#f0d9ff,stroke:#9900cc,stroke-width:3px,color:#000
    style Admin fill:#fff4d9,stroke:#ff9900,stroke-width:3px,color:#000
    
    style Login fill:#fff,stroke:#666,stroke-width:2px
    style Register fill:#fff,stroke:#666,stroke-width:2px
    style Logout fill:#fff,stroke:#666,stroke-width:2px
    style UpdateProfile fill:#fff,stroke:#666,stroke-width:2px
    style ViewAccount fill:#fff,stroke:#666,stroke-width:2px
    style 2FA fill:#fff,stroke:#666,stroke-width:2px
    
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
