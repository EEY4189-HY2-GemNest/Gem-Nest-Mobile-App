# GemNest - System Activity Diagram

```mermaid
flowchart TD
    Start([User Access])
    Start --> Auth{Account Exists?}
    
    Auth -->|No| Signup[Register & Select Role]
    Auth -->|Yes| Login[Login]
    
    Signup --> CreateAcc[Create Account]
    CreateAcc --> Role{Role?}
    Login --> Role
    
    Role -->|Buyer| BuyerFlow[Buyer]
    Role -->|Seller| SellerFlow[Seller]
    Role -->|Admin| AdminFlow[Admin]
    
    %% BUYER FLOW
    BuyerFlow --> BuyerHome[Home Dashboard]
    BuyerHome --> Browse{Activity?}
    
    Browse -->|Products| BrowseProd[View Products]
    BrowseProd --> CartDecide{Add to Cart?}
    CartDecide -->|Yes| AddCart[Add Item]
    CartDecide -->|No| Browse
    AddCart --> Browse
    
    Browse -->|Auctions| BrowseAuc[View Auctions<br/>Place Bids]
    BrowseAuc --> Browse
    
    Browse -->|Checkout| Cart[Cart Review<br/>Apply Coupon]
    Cart --> Address[Enter Address]
    Address --> Payment[Stripe Payment]
    Payment --> PayStatus{Success?}
    PayStatus -->|No| Retry[Retry]
    Retry --> Payment
    PayStatus -->|Yes| OrderCreate[Order Created]
    OrderCreate --> Browse
    
    Browse -->|Orders| ViewOrders[View Orders<br/>Track Status]
    ViewOrders --> Browse
    
    Browse -->|Logout| LogoutBuy[Logout]
    LogoutBuy --> End([End])
    
    %% SELLER FLOW
    SellerFlow --> SellerHome[Seller Dashboard]
    SellerHome --> Sell{Activity?}
    
    Sell -->|Products| ProdMgmt[Create/Edit Products<br/>Upload Images<br/>Add Certificates]
    ProdMgmt --> SubmitProd[Submit for Approval]
    SubmitProd --> Sell
    
    Sell -->|Auctions| AucMgmt[Create Auctions<br/>Set Price & Time<br/>Monitor Bids]
    AucMgmt --> SubmitAuc[Submit for Approval]
    SubmitAuc --> Sell
    
    Sell -->|Orders| OrdMgmt[View Orders<br/>Confirm & Ship<br/>Update Tracking]
    OrdMgmt --> Sell
    
    Sell -->|Analytics| ViewAna[View Sales Stats]
    ViewAna --> Sell
    
    Sell -->|Logout| LogoutSell[Logout]
    LogoutSell --> End
    
    %% ADMIN FLOW
    AdminFlow --> AdminHome[Admin Dashboard]
    AdminHome --> Admin{Task?}
    
    Admin -->|Products| AppProd[Review Products<br/>Approve/Reject]
    AppProd --> Admin
    
    Admin -->|Auctions| AppAuc[Review Auctions<br/>Approve/Reject]
    AppAuc --> Admin
    
    Admin -->|Users| UserMgmt[Manage Users<br/>Verify Sellers<br/>Activate/Deactivate]
    UserMgmt --> Admin
    
    Admin -->|Analytics| AdminStats[View Platform Stats]
    AdminStats --> Admin
    
    Admin -->|Logout| LogoutAdmin[Logout]
    LogoutAdmin --> End
    
    %% SERVICES
    BuyerFlow -.->|Uses| Services[Global Services]
    SellerFlow -.->|Uses| Services
    AdminFlow -.->|Uses| Services
    
    Services --> Firebase[Firebase]
    Firebase --> FBServices[Auth - Firestore<br/>Storage - Messaging]
    
    Services --> Stripe[Stripe Payments]
    Services --> Notif[Notification Engine]
    
    FBServices --> NotifEng[Process Notifications]
    Stripe --> NotifEng
    Notif --> NotifEng
    
    NotifEng --> NotifType[Approvals - Orders<br/>Payments - Bids]
```

---

## System Overview

**Buyer**: Register/Login → Browse products & auctions → Add to cart → Checkout with Stripe → Create order → Track delivery

**Seller**: Register/Login → Create products & auctions → Submit for admin approval → Manage orders → View analytics

**Admin**: Login → Review & approve products & auctions → Manage users & verify sellers → View platform stats

**Services**: Firebase (Auth, Firestore, Storage, Messaging) + Stripe (Payments) + Notification Engine
