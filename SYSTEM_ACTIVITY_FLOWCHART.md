# GemNest - System Activity Diagram

```mermaid
flowchart TD
    Start([User Access])
    Start --> Auth{Login?}
    
    Auth -->|No| Signup[Register]
    Auth -->|Yes| Login[Login]
    
    Signup --> VerifyRole{Role?}
    Login --> VerifyRole
    
    VerifyRole -->|Buyer| Buyer[Buyer Dashboard]
    VerifyRole -->|Seller| Seller[Seller Dashboard]
    VerifyRole -->|Admin| Admin[Admin Dashboard]
    
    %% BUYER
    Buyer --> BuyerAct[Browse Products<br/>Bid Auctions<br/>Shop & Checkout<br/>Track Orders]
    BuyerAct --> BuyerPay[Stripe Payment]
    BuyerPay --> BuyerEnd[Orders Created]
    BuyerEnd --> Notifications[Notifications]
    
    %% SELLER
    Seller --> SellerAct[Create Products<br/>Create Auctions<br/>Manage Orders<br/>View Analytics]
    SellerAct --> SellerSubmit[Submit for Approval]
    SellerSubmit --> SellerWait[Waiting Approval]
    SellerWait --> Notifications
    
    %% ADMIN
    Admin --> AdminAct[Approve Products<br/>Approve Auctions<br/>Manage Users<br/>View Stats]
    AdminAct --> AdminNotify[Send Notifications]
    AdminNotify --> Notifications
    
    %% SERVICES
    BuyerPay --> Firebase[Firebase Services]
    SellerSubmit --> Firebase
    AdminAct --> Firebase
    
    Firebase --> Services[Auth - Firestore<br/>Storage - Messaging]
    Services --> Stripe[Stripe Payments]
    Services --> NotifEngine[Notification Engine]
    Stripe --> NotifEngine
    
    Notifications --> End([Session End])
```

---

## System Overview

**Buyer**: Browse products → Bid auctions → Shop → Payment → Track orders

**Seller**: Create products → Create auctions → Submit approval → Manage orders

**Admin**: Approve items → Manage users → View stats

**Services**: Firebase (Auth, Firestore, Storage, Messaging) + Stripe + Notifications
