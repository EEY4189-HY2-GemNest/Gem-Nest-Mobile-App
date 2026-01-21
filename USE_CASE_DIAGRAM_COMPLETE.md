# GemNest - Complete & Corrected Use Case Diagram

## Overview
This document contains the **complete and fully corrected** use case diagram for the GemNest Mobile App system with all three actors: **Buyer**, **Seller**, and **Admin**.

### ✅ Key Corrections & Additions
1. **Checkout is System Automatic** - Not a single use case but triggers automatic processes
2. **Payment Processing System-Driven** - System handles all payment logic automatically
3. **Auction End-Time Automation** - System automatically ends auctions at scheduled time
4. **Winner Notification Automatic** - System notifies winners automatically
5. **Separated Concerns** - Clear distinction between actor actions and system processes
6. **Added Missing Use Cases** - Return requests, dispute handling, seller verification, certificates, etc.
7. **Proper Dependencies** - Shows how use cases trigger system processes

---

## Complete Use Case Diagram (Hierarchical View)

```mermaid
graph TB
    subgraph System["🛍️ GemNest E-Commerce System"]
        direction TB
        
        %% ==================== AUTHENTICATION LAYER ====================
        subgraph Auth["🔐 AUTHENTICATION & ACCOUNT"]
            Login(["🔓 Login"])
            Register(["📝 Register"])
            Logout(["🚪 Logout"])
            ResetPassword(["🔑 Reset Password"])
            UpdateProfile(["✏️ Update Profile"])
            ViewAccount(["👁️ View Account"])
            Enable2FA(["🔒 Enable 2FA"])
            ManageAddresses(["📍 Manage Addresses"])
            UpdatePaymentMethod(["💳 Update Payment Method"])
        end
        
        %% ==================== BUYER - DISCOVERY & SHOPPING ====================
        subgraph BuyerDiscover["🔍 BUYER: DISCOVERY & SHOPPING"]
            BrowseProducts(["Browse Products"])
            BrowseAuctions(["Browse Auctions"])
            SearchFilter(["Search & Filter"])
            ViewProductDetails(["View Product Details"])
            ViewAuctionDetails(["View Auction Details"])
            CheckProductReviews(["Check Reviews"])
            CompareProducts(["Compare Products"])
            CheckProductCert(["Check Certificate"])
        end
        
        %% ==================== BUYER - CART & WISHLIST ====================
        subgraph BuyerCart["🛒 BUYER: CART & WISHLIST"]
            AddToCart(["Add to Cart"])
            RemoveFromCart(["Remove from Cart"])
            UpdateQuantity(["Update Quantity"])
            ViewCart(["View Cart"])
            ApplyCoupon(["Apply Coupon"])
            ManageWishlist(["Manage Wishlist"])
            ViewWishlist(["View Wishlist"])
        end
        
        %% ==================== BUYER - BIDDING ====================
        subgraph BuyerBid["🏷️ BUYER: AUCTIONS & BIDDING"]
            PlaceBid(["Place Bid"])
            UpdateBid(["Update Bid"])
            ViewBidHistory(["View Bid History"])
            MonitorBidStatus(["Monitor Bid Status"])
            GetOutbidNotification(["Get Outbid Notification"])
        end
        
        %% ==================== BUYER - CHECKOUT & PAYMENT ====================
        subgraph BuyerCheckout["💰 BUYER: CHECKOUT & PAYMENT"]
            InitiateCheckout(["Initiate Checkout"])
            InitiateAuctionCheckout(["Initiate Auction Checkout"])
            SelectShipping(["Select Shipping Method"])
            EnterShippingAddress(["Enter Shipping Address"])
            SelectPaymentMethod(["Select Payment Method"])
            ViewOrderSummary(["View Order Summary"])
        end
        
        %% ==================== SYSTEM - AUTOMATIC CHECKOUT PROCESSES ====================
        subgraph SystemCheckout["⚙️ SYSTEM: AUTOMATIC CHECKOUT PROCESS"]
            CalcTotals(["Calculate Total & Tax"])
            CalcShipping(["Calculate Shipping"])
            ValidateAddress(["Validate Address"])
            CreateOrder(["Create Order Record"])
            ProcessPayment(["🔐 Process Payment via Stripe"])
            UpdateInventory(["Update Inventory"])
            SendOrderConfirm(["Send Order Confirmation Email"])
            SendSellerNotif(["Send Seller Notification"])
            GenerateInvoice(["Generate Invoice"])
            ClearCart(["Clear Cart"])
        end
        
        %% ==================== BUYER - ORDER MANAGEMENT ====================
        subgraph BuyerOrder["📦 BUYER: ORDER MANAGEMENT"]
            ViewOrders(["View Orders"])
            TrackOrder(["Track Order"])
            ViewOrderDetails(["View Order Details"])
            CancelOrder(["Request Cancellation"])
            RequestReturn(["Request Return"])
            ReturnReason(["Select Return Reason"])
            DownloadInvoice(["Download Invoice"])
        end
        
        %% ==================== BUYER - FEEDBACK & REVIEWS ====================
        subgraph BuyerFeedback["⭐ BUYER: FEEDBACK & REVIEWS"]
            LeaveProductReview(["Leave Product Review"])
            RateProduct(["Rate Product"])
            LeaveSellerReview(["Rate Seller"])
            ReportProduct(["Report Product"])
            ReportSeller(["Report Seller"])
            ViewNotifications(["View Notifications"])
        end
        
        %% ==================== BUYER - COMMUNICATION ====================
        subgraph BuyerComm["💬 BUYER: COMMUNICATION"]
            ChatWithSeller(["Chat with Seller"])
            ViewChatHistory(["View Chat History"])
            ContactSupport(["Contact Support"])
        end
        
        %% ==================== SELLER - AUTHENTICATION & PROFILE ====================
        subgraph SellerAuth["🏪 SELLER: AUTHENTICATION & PROFILE"]
            SellerLogin(["Login"])
            SellerRegister(["Register"])
            SellerLogout(["Logout"])
            CompleteProfile(["Complete Profile"])
            UploadDocuments(["Upload Documents"])
            UploadCertificates(["Upload Certificates"])
            SellerUpdateProfile(["Update Profile"])
            ManagePaymentAccount(["Manage Payment Account"])
        end
        
        %% ==================== SYSTEM - SELLER VERIFICATION ====================
        subgraph SystemVerify["✔️ SYSTEM: SELLER VERIFICATION"]
            VerifyDocuments(["Verify Documents"])
            VerifyCertificates(["Verify Certificates"])
            AssignSellerTier(["Assign Seller Tier"])
            SendVerificationStatus(["Send Status Email"])
        end
        
        %% ==================== SELLER - PRODUCT MANAGEMENT ====================
        subgraph SellerProduct["📝 SELLER: PRODUCT MANAGEMENT"]
            CreateProduct(["Create Product"])
            EditProduct(["Edit Product"])
            DeleteProduct(["Delete/Delist Product"])
            UploadProductImages(["Upload Images"])
            SetPrice(["Set Price"])
            ManageInventory(["Manage Inventory"])
            SetProductCertificate(["Assign Certificate"])
            BulkUpload(["Bulk Upload Products"])
        end
        
        %% ==================== SELLER - AUCTION MANAGEMENT ====================
        subgraph SellerAuction["🏷️ SELLER: AUCTION MANAGEMENT"]
            CreateAuction(["Create Auction"])
            EditAuction(["Edit Auction"])
            ScheduleAuction(["Schedule Auction"])
            MonitorBids(["Monitor Bids"])
            ReceiveOutbidNotif(["Receive Outbid Notifications"])
        end
        
        %% ==================== SYSTEM - AUCTION AUTOMATION ====================
        subgraph SystemAuction["⚙️ SYSTEM: AUTOMATIC AUCTION PROCESSES"]
            AutoEndAuction(["Auto End Auction at Scheduled Time"])
            DeterminWinner(["Determine Winner"])
            NotifyWinner(["Notify Winner with Checkout"])
            NotifyOtherBidders(["Notify Other Bidders"])
            AuctionExpiry(["Handle Expired Auctions"])
        end
        
        %% ==================== SELLER - ORDER & SHIPPING ====================
        subgraph SellerOrder["📦 SELLER: ORDER & SHIPPING MANAGEMENT"]
            ViewSellerOrders(["View Orders"])
            ViewSellerOrderDetails(["View Order Details"])
            UpdateOrderStatus(["Update Order Status"])
            ManageShipping(["Manage Shipping"])
            TrackShipment(["Track Shipment"])
            HandleReturn(["Handle Return Request"])
            ProcessRefund(["Process Refund"])
            PrintLabel(["Print Shipping Label"])
        end
        
        %% ==================== SELLER - ANALYTICS & BUSINESS ====================
        subgraph SellerAnalytics["📊 SELLER: ANALYTICS & BUSINESS"]
            ViewDashboard(["View Dashboard"])
            ViewSalesAnalytics(["View Sales Analytics"])
            ViewRevenue(["View Revenue"])
            ViewSellerRatings(["View Ratings"])
            ManagePromotions(["Manage Promotions"])
            SetDiscount(["Set Discounts"])
            ViewCustomerInsights(["View Customer Insights"])
        end
        
        %% ==================== SELLER - COMMUNICATION ====================
        subgraph SellerComm["💬 SELLER: COMMUNICATION"]
            ChatWithBuyer(["Chat with Buyer"])
            SendMessages(["Send Messages"])
            ViewSellerChatHistory(["View Chat History"])
            ContactSellerSupport(["Contact Support"])
        end
        
        %% ==================== ADMIN - USER MANAGEMENT ====================
        subgraph AdminUser["👥 ADMIN: USER MANAGEMENT"]
            ViewAllUsers(["View All Users"])
            ViewBuyers(["View All Buyers"])
            ViewSellers(["View All Sellers"])
            SearchUsers(["Search Users"])
            ViewUserDetails(["View User Details"])
            BanUser(["Ban User"])
            SuspendUser(["Suspend User"])
            UnbanUser(["Unban User"])
            SendUserNotice(["Send Notice to User"])
        end
        
        %% ==================== ADMIN - SELLER MANAGEMENT ====================
        subgraph AdminSeller["🏪 ADMIN: SELLER MANAGEMENT"]
            ReviewSellerDocs(["Review Seller Documents"])
            ApproveSeller(["Approve Seller"])
            RejectSeller(["Reject Seller"])
            VerifySellerTier(["Verify Seller Tier"])
            SuspendSeller(["Suspend Seller"])
            PromoteSeller(["Promote Seller"])
            ViewSellerAnalytics(["View Seller Analytics"])
        end
        
        %% ==================== ADMIN - CONTENT MANAGEMENT ====================
        subgraph AdminContent["📝 ADMIN: CONTENT MANAGEMENT"]
            ReviewProducts(["Review Products"])
            ApproveProduct(["Approve Product"])
            RejectProduct(["Reject Product"])
            RemoveProduct(["Remove Product"])
            ReviewAuctions(["Review Auctions"])
            ApproveAuction(["Approve Auction"])
            RejectAuction(["Reject Auction"])
            ManageCertificates(["Manage Certificates"])
            ManageCertTypes(["Manage Certificate Types"])
            ReviewListings(["Review Listings"])
        end
        
        %% ==================== ADMIN - PAYMENT & TRANSACTIONS ====================
        subgraph AdminPayment["💳 ADMIN: PAYMENT & TRANSACTIONS"]
            ViewTransactions(["View Transactions"])
            ViewPaymentHistory(["View Payment History"])
            ViewFailedPayments(["View Failed Payments"])
            ManualPaymentProcess(["Manual Payment Processing"])
            GenerateInvoices(["Generate Invoices"])
            ViewSettlements(["View Settlements"])
        end
        
        %% ==================== ADMIN - DISPUTE RESOLUTION ====================
        subgraph AdminDispute["⚖️ ADMIN: DISPUTE RESOLUTION"]
            ViewComplaints(["View Complaints"])
            ViewDisputes(["View Disputes"])
            InvestigateDispute(["Investigate Dispute"])
            ResolveDispute(["Resolve Dispute"])
            ProcessRefundAdmin(["Process Refund"])
            CompensateBuyer(["Compensate Buyer"])
            IssueWarning(["Issue Warning to Seller"])
        end
        
        %% ==================== ADMIN - ANALYTICS & REPORTING ====================
        subgraph AdminAnalytics["📊 ADMIN: ANALYTICS & REPORTING"]
            ViewSystemDashboard(["View System Dashboard"])
            ViewSystemAnalytics(["View System Analytics"])
            GenerateReports(["Generate Reports"])
            ViewPlatformMetrics(["View Platform Metrics"])
            ExportData(["Export Data"])
            ViewUserTrends(["View User Trends"])
            ViewSalesTrends(["View Sales Trends"])
        end
        
        %% ==================== ADMIN - COMMUNICATION ====================
        subgraph AdminComm["📢 ADMIN: COMMUNICATION & SUPPORT"]
            SendSystemNotif(["Send System Notification"])
            SendBulkEmail(["Send Bulk Email"])
            ViewUserQueries(["View Support Queries"])
            RespondToSupport(["Respond to Support"])
            ManageTickets(["Manage Support Tickets"])
        end
        
    end

    %% ==================== ACTORS ====================
    Buyer["👤 BUYER"]
    Seller["🏪 SELLER"]
    Admin["👨‍💼 ADMIN"]

    %% ==================== BUYER RELATIONSHIPS ====================
    Buyer --> Login
    Buyer --> Register
    Buyer --> Logout
    Buyer --> ResetPassword
    Buyer --> UpdateProfile
    Buyer --> ViewAccount
    
    Buyer --> BrowseProducts
    Buyer --> BrowseAuctions
    Buyer --> SearchFilter
    Buyer --> ViewProductDetails
    Buyer --> ViewAuctionDetails
    Buyer --> CheckProductReviews
    Buyer --> CompareProducts
    
    Buyer --> AddToCart
    Buyer --> RemoveFromCart
    Buyer --> UpdateQuantity
    Buyer --> ViewCart
    Buyer --> ApplyCoupon
    Buyer --> ManageWishlist
    
    Buyer --> PlaceBid
    Buyer --> UpdateBid
    Buyer --> ViewBidHistory
    Buyer --> MonitorBidStatus
    
    Buyer --> InitiateCheckout
    Buyer --> InitiateAuctionCheckout
    Buyer --> SelectShipping
    Buyer --> EnterShippingAddress
    Buyer --> SelectPaymentMethod
    Buyer --> ViewOrderSummary
    
    Buyer --> ViewOrders
    Buyer --> TrackOrder
    Buyer --> ViewOrderDetails
    Buyer --> CancelOrder
    Buyer --> RequestReturn
    Buyer --> DownloadInvoice
    
    Buyer --> LeaveProductReview
    Buyer --> RateProduct
    Buyer --> LeaveSellerReview
    Buyer --> ReportProduct
    Buyer --> ReportSeller
    Buyer --> ViewNotifications
    
    Buyer --> ChatWithSeller
    Buyer --> ContactSupport
    
    %% SYSTEM TRIGGERS - Checkout initiates automatic processes
    InitiateCheckout --> CalcTotals
    InitiateCheckout --> CalcShipping
    InitiateCheckout --> ValidateAddress
    InitiateCheckout --> CreateOrder
    InitiateCheckout --> ProcessPayment
    InitiateCheckout --> UpdateInventory
    InitiateCheckout --> SendOrderConfirm
    InitiateCheckout --> SendSellerNotif
    InitiateCheckout --> GenerateInvoice
    InitiateCheckout --> ClearCart
    
    InitiateAuctionCheckout --> CalcTotals
    InitiateAuctionCheckout --> ProcessPayment
    InitiateAuctionCheckout --> UpdateInventory
    InitiateAuctionCheckout --> SendOrderConfirm
    
    %% ==================== SELLER RELATIONSHIPS ====================
    Seller --> SellerLogin
    Seller --> SellerRegister
    Seller --> SellerLogout
    
    Seller --> CompleteProfile
    Seller --> UploadDocuments
    Seller --> UploadCertificates
    Seller --> SellerUpdateProfile
    Seller --> ManagePaymentAccount
    Seller --> Enable2FA
    
    %% SYSTEM VERIFICATION TRIGGERS
    CompleteProfile --> VerifyDocuments
    UploadDocuments --> VerifyDocuments
    UploadCertificates --> VerifyCertificates
    VerifyDocuments --> AssignSellerTier
    VerifyDocuments --> SendVerificationStatus
    
    Seller --> CreateProduct
    Seller --> EditProduct
    Seller --> DeleteProduct
    Seller --> UploadProductImages
    Seller --> SetPrice
    Seller --> ManageInventory
    Seller --> SetProductCertificate
    Seller --> BulkUpload
    
    Seller --> CreateAuction
    Seller --> EditAuction
    Seller --> ScheduleAuction
    Seller --> MonitorBids
    Seller --> ReceiveOutbidNotif
    
    %% SYSTEM AUCTION AUTOMATION TRIGGERS
    ScheduleAuction --> AutoEndAuction
    CreateAuction --> AutoEndAuction
    AutoEndAuction --> DeterminWinner
    DeterminWinner --> NotifyWinner
    NotifyWinner --> InitiateAuctionCheckout
    AutoEndAuction --> NotifyOtherBidders
    
    Seller --> ViewSellerOrders
    Seller --> ViewSellerOrderDetails
    Seller --> UpdateOrderStatus
    Seller --> ManageShipping
    Seller --> TrackShipment
    Seller --> HandleReturn
    Seller --> ProcessRefund
    Seller --> PrintLabel
    
    Seller --> ViewDashboard
    Seller --> ViewSalesAnalytics
    Seller --> ViewRevenue
    Seller --> ViewSellerRatings
    Seller --> ManagePromotions
    Seller --> SetDiscount
    
    Seller --> ChatWithBuyer
    Seller --> SendMessages
    Seller --> ContactSellerSupport

    %% ==================== ADMIN RELATIONSHIPS ====================
    Admin --> Login
    Admin --> Logout
    
    Admin --> ViewAllUsers
    Admin --> ViewBuyers
    Admin --> ViewSellers
    Admin --> SearchUsers
    Admin --> ViewUserDetails
    Admin --> BanUser
    Admin --> SuspendUser
    Admin --> UnbanUser
    
    Admin --> ReviewSellerDocs
    Admin --> ApproveSeller
    Admin --> RejectSeller
    Admin --> VerifySellerTier
    Admin --> SuspendSeller
    Admin --> PromoteSeller
    
    Admin --> ReviewProducts
    Admin --> ApproveProduct
    Admin --> RejectProduct
    Admin --> RemoveProduct
    Admin --> ReviewAuctions
    Admin --> ApproveAuction
    Admin --> RejectAuction
    Admin --> ManageCertificates
    Admin --> ManageCertTypes
    
    Admin --> ViewTransactions
    Admin --> ViewPaymentHistory
    Admin --> ViewFailedPayments
    Admin --> ManualPaymentProcess
    Admin --> GenerateInvoices
    Admin --> ViewSettlements
    
    Admin --> ViewComplaints
    Admin --> ViewDisputes
    Admin --> InvestigateDispute
    Admin --> ResolveDispute
    Admin --> ProcessRefundAdmin
    Admin --> CompensateBuyer
    Admin --> IssueWarning
    
    Admin --> ViewSystemDashboard
    Admin --> ViewSystemAnalytics
    Admin --> GenerateReports
    Admin --> ViewPlatformMetrics
    Admin --> ExportData
    
    Admin --> SendSystemNotif
    Admin --> SendBulkEmail
    Admin --> ViewUserQueries
    Admin --> RespondToSupport
    Admin --> ManageTickets

```

---

## System Automatic Processes (⚙️ Marked Below)

### 🛒 **Checkout Automation**
When a **buyer initiates checkout**, the system **automatically**:

| Step | Process | Details |
|------|---------|---------|
| 1 | **Calculate Totals** | Subtotal + Tax (18%) + Shipping |
| 2 | **Calculate Shipping** | Based on location & method selected |
| 3 | **Validate Address** | Checks if serviceable |
| 4 | **Create Order Record** | Stored in Firestore with unique ID |
| 5 | **Process Payment** | Via Stripe (card, COD, etc.) |
| 6 | **Update Inventory** | Decreases product stock immediately |
| 7 | **Generate Invoice** | PDF with order details |
| 8 | **Send Confirmation** | Email + SMS to buyer |
| 9 | **Notify Seller** | New order notification |
| 10 | **Clear Cart** | Remove items from buyer's cart |

### 🏷️ **Auction Automation**
When **auction time expires**, the system **automatically**:

| Step | Process | Details |
|------|---------|---------|
| 1 | **End Auction** | At exactly scheduled end time |
| 2 | **Determine Winner** | Highest bidder wins |
| 3 | **Notify Winner** | With direct checkout link |
| 4 | **Notify Other Bidders** | Auction ended message |
| 5 | **Handle Expired** | If no bids, offer relisting to seller |

### ✔️ **Seller Verification Automation**
When **seller uploads documents**, system **automatically**:

| Step | Process | Details |
|------|---------|---------|
| 1 | **Verify Documents** | Checks format & authenticity |
| 2 | **Verify Certificates** | Validates gemstone certificates |
| 3 | **Assign Tier** | Gold/Silver/Bronze based on verification |
| 4 | **Send Status Email** | Notifies seller of approval/rejection |

---

## Key Use Case Groups & Actor Responsibilities

### 👤 **BUYER** (8 main activity areas)
| Area | Use Cases | Triggers |
|------|-----------|----------|
| **Authentication** | Login, Register, Logout, 2FA | System tracks login |
| **Discovery** | Browse, Search, View Details, Compare | View products & auctions |
| **Shopping** | Add to Cart, Apply Coupon, Manage Wishlist | Create cart session |
| **Bidding** | Place Bid, Monitor Status | Auctions update in real-time |
| **Checkout** | Initiate Checkout ➜ **Auto Processes** | Creates order in system |
| **Order Mgmt** | Track, Cancel, Return | Seller updates status |
| **Feedback** | Reviews, Ratings, Reports | After order completion |
| **Communication** | Chat, Support | Direct messaging |

### 🏪 **SELLER** (8 main activity areas)
| Area | Use Cases | Triggers |
|------|-----------|----------|
| **Onboarding** | Register, Upload Docs ➜ **Auto Verify** | Verification process starts |
| **Products** | Create, Edit, Delete, Manage Inventory | Product goes live after approval |
| **Auctions** | Create, Schedule ➜ **Auto End** | Automatic winner notification |
| **Orders** | View, Update Status, Manage Shipping | Updates sent to buyer in real-time |
| **Returns** | Handle Returns, Process Refunds | Creates refund record |
| **Analytics** | View Sales, Revenue, Ratings | Real-time dashboard |
| **Promotions** | Set Discounts, Manage Coupons | Applied to buyer checkout |
| **Communication** | Chat, Support Tickets | Direct buyer interaction |

### 👨‍💼 **ADMIN** (8 main activity areas)
| Area | Use Cases | Purpose |
|------|-----------|---------|
| **User Mgmt** | View, Search, Ban, Suspend Users | Moderation & compliance |
| **Seller Mgmt** | Review Docs, Approve, Verify Tier | Quality control |
| **Content Mgmt** | Review Products, Auctions, Certificates | Content moderation |
| **Payment Mgmt** | View Transactions, Failed Payments | Financial oversight |
| **Disputes** | Investigate, Resolve, Compensate | Conflict resolution |
| **Certificates** | Manage Types, Verify Gemstones | Authenticity control |
| **Analytics** | Dashboard, Reports, Metrics | Business intelligence |
| **Communication** | Send Notifications, Support | System announcements |

---

## Important Notes & Clarifications

### ✅ **Checkout is NOT a Single Use Case**
```
WRONG ❌: Buyer → Checkout → Done
RIGHT ✅: Buyer → Initiate Checkout → [System: Calc, Validate, Pay, Notify] → Order Created
```
- **Buyer action**: "Initiate Checkout" (what user does)
- **System actions**: All automatic processes (what system does)

### ✅ **Auction Lifecycle is Fully Automated**
- Seller schedules auction with end time
- **System automatically ends** at exact scheduled time
- **System automatically determines** the winner
- **System automatically notifies** winner with checkout
- Winner can then initiate auction checkout

### ✅ **Seller Verification is Automatic**
- Seller completes profile & uploads documents
- **System automatically verifies** documents & certificates
- **System automatically assigns** seller tier (Gold/Silver/Bronze)
- **System sends** verification status email

### ✅ **Complete Use Cases Included** (vs Old Diagram)

**NEW** ✨ Added Use Cases:
- Request Return & Select Return Reason
- Report Product & Report Seller
- Compare Products
- Check Certificate
- Manage Addresses & Payment Methods
- Bulk Upload Products
- Print Shipping Label
- Manual Payment Processing
- Investigate Disputes
- Compensate Buyer
- Issue Warning to Seller
- Support Ticket Management
- Send System Notifications
- Export Data
- All authentication features (2FA, Reset Password, etc.)

### ✅ **Clear Separation of Concerns**
```
AUTHENTICATION (Shared by all)
├─ Login, Register, Logout
├─ 2FA, Reset Password
└─ Profile Management

BUYER ACTIVITIES (User-initiated)
├─ Discovery: Browse, Search, Compare
├─ Shopping: Cart, Wishlist, Coupon
├─ Bidding: Place Bid, Monitor
├─ Order: Track, Cancel, Return
└─ Feedback: Review, Report, Chat

SELLER ACTIVITIES (User-initiated)
├─ Onboarding: Register, Upload Docs
├─ Products: Create, Edit, Manage
├─ Auctions: Create, Schedule, Monitor
├─ Orders: View, Update, Process Refund
├─ Analytics: Dashboard, Reports
└─ Communication: Chat, Support

ADMIN ACTIVITIES (User-initiated)
├─ Moderation: Ban, Suspend, Review
├─ Verification: Approve Sellers, Products
├─ Disputes: Investigate, Resolve
├─ Analytics: System Dashboard, Reports
└─ Communication: Notifications, Support

SYSTEM PROCESSES (Automatic ⚙️)
├─ Checkout: Calc, Validate, Pay, Notify
├─ Auctions: End, Winner, Notify
├─ Verification: Verify, Assign Tier
└─ Notifications: Email, SMS, Alerts
```

### ✅ **Payment Flow Correctly Modeled**
1. Buyer selects payment method
2. System processes through Stripe (automatic)
3. System handles COD separately
4. System creates order only if payment succeeds
5. System notifies all parties

### ✅ **Auction Flow Correctly Modeled**
1. Seller creates auction with end time
2. Buyers place bids (continuous monitoring)
3. System automatically ends at scheduled time (not seller action)
4. System determines and notifies winner
5. Winner proceeds to checkout (triggers checkout automation)

---

## File Structure Reference

This diagram represents:
- **lib/** - Mobile app with all buyer features
- **admin-dashboard/** - Admin web portal
- **functions/** - Cloud functions for automation
- **Firestore Collections**: Users, Products, Auctions, Orders, Payments, Notifications

---

## Next Steps for Implementation

1. ✅ **Buyer Features** - Discovery, Shopping, Bidding (mostly done)
2. ✅ **Payment System** - Stripe integration (done)
3. ✅ **Seller Dashboard** - Product & Auction Management (in progress)
4. ⏳ **Admin Dashboard** - User & Content Moderation
5. ⏳ **Automation Services** - Cloud Functions for system processes
6. ⏳ **Analytics** - Real-time dashboards & reports
