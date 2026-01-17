# GemNest Mobile App - Complete System Activity Diagram

```mermaid
activity
    title GemNest - Complete System Activity Diagram

    start
    :User Access Application;
    
    partition Authentication {
        if (User Exists?) then
            :Login with Email & Password;
            if (Login Successful?) then
                :Load User Profile;
            else
                :Show Login Error;
                :Retry Login;
            endif
        else
            :Register New Account;
            :Select User Type (Buyer/Seller);
            if (Is Seller?) then
                :Upload Business Documents;
                :NIC Document;
                :Business Registration;
            endif
            :Create Account;
        endif
        :Verify User Role;
    }

    if (User Role?) then (Buyer)
        :Buyer Session Initiated;
        partition BuyerDashboard {
            fork
                :Initialize Home Screen;
                :Load Popular Gems (4 Products);
                :Display Recommended Products;
                :Fetch Seller Information;
            and
                :Load Banner Provider;
                :Display Promotional Banners;
            and
                :Initialize Cart Provider;
                :Load Saved Cart Items;
                :Calculate Cart Totals;
            endfork
        }

        partition ProductBrowsing {
            repeat
                :View Home Screen;
                :Browse Product Categories;
                :Filter Products;
                :Sort Products;
                :Select Product Card;
                
                :Navigate to Product Details Screen;
                fork
                    :Display Product Image (Full Size);
                    :Display Product Info;
                    :Show Title & Description;
                    :Display Price & Discounts;
                    :Show Gem Certificates;
                    :Display Seller Information;
                and
                    :Display Delivery Methods;
                    :Show Available Quantity;
                    :Display Customer Reviews;
                endfork
                
                if (Want to Contact Seller?) then
                    fork
                        :Call Seller Button;
                        :Launch Phone Dialer;
                    or
                        :WhatsApp Button;
                        :Open WhatsApp Chat;
                    endfork
                endif
                
                if (Add to Cart?) then
                    :Select Quantity;
                    :Click Add to Cart;
                    :Save to Cart Provider;
                    :Update Cart Count;
                    :Show Confirmation Toast;
                endif
            repeat
        }

        partition AuctionActivity {
            repeat
                :Navigate to Auction Screen;
                :Fetch Approved Auctions;
                :Display Active Auctions;
                :Sort by Time Remaining;
                
                :Select Auction Card;
                :Navigate to Auction Details Screen;
                fork
                    :Display Auction Image;
                    :Show Auction Details;
                    :Display Starting Price;
                    :Show Current Bid Amount;
                and
                    :Start Countdown Timer;
                    :Display Time Remaining;
                    :Update in Real-Time;
                and
                    :Display Bid History;
                    :Show Previous Bids;
                    :Show Bidder Names;
                    :Sort by Amount (Descending);
                endfork
                
                if (Want to Contact Seller?) then
                    fork
                        :Call Seller;
                    or
                        :Message on WhatsApp;
                    endfork
                endif
                
                if (Place Bid?) then
                    :Enter Bid Amount;
                    :Validate Bid;
                    if (Bid >= Current Bid + Min Increment?) then
                        :Accept Bid;
                        :Add to Bid History;
                        :Update Current Bid;
                        :Notify Previous Bidder (Outbid);
                        :Send Notification to Seller;
                    else
                        :Show Validation Error;
                        :Suggest Minimum Bid;
                    endif
                endif
            repeat
        }

        partition ShoppingCart {
            :Navigate to Cart Screen;
            :Display Cart Items;
            :Show Product Details;
            :Display Unit Price;
            :Show Quantity;
            
            fork
                :Adjust Quantities;
                :Remove Items;
            and
                :Apply Coupon Code;
                :Validate Coupon;
                if (Valid?) then
                    :Calculate Discount;
                    :Update Cart Total;
                else
                    :Show Invalid Coupon;
                endif
            and
                :Calculate Totals;
                :Subtotal = Sum of Items;
                :Tax = Subtotal * 10%;
                :Shipping Cost;
                :Total = Subtotal + Tax + Shipping;
            endfork
            
            if (Proceed to Checkout?) then
                :Navigate to Checkout Screen;
            endif
        }

        partition CheckoutAndPayment {
            :Enter Shipping Address;
            :Verify Address;
            :Select Delivery Method;
            fork
                :Standard Delivery (5-7 days);
            or
                :Express Delivery (2-3 days);
            or
                :Same Day Delivery;
            endfork
            
            :Review Order Summary;
            :Display All Items;
            :Show Prices Breakdown;
            :Confirm Total Amount;
            
            :Proceed to Payment;
            :Initialize Stripe Payment;
            fork
                :Display Stripe Payment Form;
                :Enter Card Details;
                :Enter Cardholder Name;
                :Enter CVV;
                :Enter Expiry Date;
            and
                :Display Order Summary;
                :Show Final Total;
            endfork
            
            :Submit Payment;
            
            if (Payment Processing?) then
                :Send Request to Stripe;
                if (Payment Successful?) then
                    :Payment Confirmed;
                    :Generate Order ID;
                    :Create Order Record in Firestore;
                    :Save Order Items;
                    :Update Product Stock;
                    :Clear Cart;
                    
                    fork
                        :Send Order Confirmation to Buyer;
                        :Email Receipt;
                    and
                        :Notify Seller;
                        :Update Seller Dashboard;
                    and
                        :Send Success Screen to Buyer;
                        :Display Order Number;
                        :Show Tracking Info;
                    endfork
                else
                    :Payment Failed;
                    :Show Error Message;
                    :Display Failure Reason;
                    if (Retry?) then
                        :Return to Payment Form;
                    else
                        :Save as Draft;
                    endif
                endif
            endif
        }

        partition OrderManagement {
            repeat
                :Navigate to Order History;
                :Fetch All Buyer Orders;
                :Display Orders List;
                
                :Select Order;
                fork
                    :View Order Details;
                    :Display Items;
                    :Show Order Status;
                and
                    :Track Delivery;
                    :Show Shipping Status;
                    :Display Tracking Number;
                    :Show Estimated Delivery;
                and
                    :Contact Seller;
                    :Message About Order;
                endfork
            repeat
        }

        partition NotificationsAndProfile {
            :View Notifications Center;
            :Fetch User Notifications;
            fork
                :Filter by Type;
                :Order Notifications;
                :Auction Notifications;
                :System Messages;
            and
                :Mark as Read;
                :Tap Notification;
                :Navigate to Relevant Screen;
            endfork
            
            :View User Profile;
            :Edit Profile Information;
            :Change Password;
            :Manage Addresses;
            :View Wishlist;
            :View Saved Items;
        }

    else (Seller)
        :Seller Session Initiated;
        partition SellerAuthentication {
            if (Seller Verified?) then
                :Load Seller Dashboard;
                :Display Seller Stats;
                :Show Total Products;
                :Show Total Auctions;
                :Show Total Sales;
            else
                :Show Pending Verification Notice;
                :Wait for Admin Approval;
            endif
        }

        partition ProductManagement {
            repeat
                :Navigate to Product Listing;
                :View My Products;
                :Filter by Status (Active/Pending/Rejected);
                
                if (Create New Product?) then
                    :Navigate to Product Upload Screen;
                    fork
                        :Enter Product Details;
                        :Title, Description;
                        :Category, Quantity;
                    and
                        :Set Price;
                        :Set Discount Percentage;
                    and
                        :Upload Product Image;
                        :Capture/Select from Gallery;
                    and
                        :Add Gem Certificates;
                        :Upload Certificate Files;
                        :Certificate Numbers;
                    and
                        :Select Delivery Methods;
                        :Standard/Express/Same-Day;
                    endfork
                    
                    :Submit Product for Approval;
                    :Set approvalStatus = 'pending';
                    :Save to Firestore;
                    :Show Confirmation;
                endif
                
                :Select Existing Product;
                fork
                    :View Product Details;
                    :Edit Product Info;
                    :Update Price;
                    :Update Stock Quantity;
                and
                    :View Sales Analytics;
                    :Show Views Count;
                    :Show Purchase Count;
                    :Show Revenue;
                and
                    :Manage Certificates;
                    :Add New Certificates;
                    :Remove Certificates;
                endfork
            repeat
        }

        partition AuctionManagement {
            repeat
                :Navigate to Auction Management;
                :View My Auctions;
                :Filter by Status (Active/Ended/Pending);
                
                if (Create New Auction?) then
                    :Navigate to Auction Upload Screen;
                    fork
                        :Enter Auction Details;
                        :Title, Description;
                        :Category;
                    and
                        :Set Auction Pricing;
                        :Starting Price;
                        :Minimum Bid Increment;
                    and
                        :Set Auction Duration;
                        :Start Time;
                        :End Time;
                    and
                        :Upload Auction Image;
                        :Add Gem Certificates;
                    endfork
                    
                    :Submit Auction for Approval;
                    :Set approvalStatus = 'pending';
                    :Save to Firestore;
                    :Show Confirmation;
                endif
                
                :Select Active Auction;
                fork
                    :View Live Bids;
                    :Display Bid History;
                    :Show Current Highest Bid;
                    :Show Bidder Count;
                and
                    :Monitor Auction Progress;
                    :Countdown Timer;
                    :Real-time Updates;
                and
                    :View Bidder Information;
                    :Bidder Names;
                    :Bid Amounts;
                    :Bid Times;
                endfork
                
                :Auction Ends;
                :Determine Winner;
                :Mark Winning Bid;
                :Create Order from Auction;
                :Notify Winner;
                :Wait for Payment Confirmation;
            repeat
        }

        partition OrderFulfillment {
            repeat
                :Navigate to Orders;
                :View All Seller Orders;
                :Filter by Status;
                
                :Select Order;
                fork
                    :View Order Details;
                    :Display Items;
                    :Show Buyer Info;
                and
                    :Manage Order Status;
                    :Mark as Confirmed;
                    :Prepare Shipment;
                    :Print Label;
                and
                    :Update Status to Shipped;
                    :Enter Tracking Number;
                    :Upload Proof;
                and
                    :Contact Buyer;
                    :Send Messages;
                    :Resolve Issues;
                endfork
            repeat
        }

        partition SellerAnalytics {
            :View Analytics Dashboard;
            fork
                :Sales Analytics;
                :Total Revenue;
                :Average Order Value;
                :Sales Trend;
            and
                :Product Analytics;
                :Top Selling Products;
                :Product Performance;
            and
                :Auction Analytics;
                :Average Auction Price;
                :Successful Auctions;
            and
                :Customer Analytics;
                :Repeat Customers;
                :Customer Reviews;
            endfork
        }

        partition SellerNotifications {
            :View Seller Notifications;
            fork
                :Product/Auction Approval Notifications;
                :Approval Status Changes;
            and
                :Auction Notifications;
                :New Bid Alerts;
                :Auction Ending Soon;
            and
                :Order Notifications;
                :New Order Created;
                :Payment Received;
            and
                :Message Notifications;
                :Customer Inquiries;
            endfork
        }

    else (Admin)
        :Admin Session Initiated;
        :Load Admin Dashboard;
        
        partition AdminApprovalSystem {
            fork
                :View Pending Products;
                :List All Pending Items;
                :Filter by Category;
                :Sort by Date;
                
                repeat
                    :Select Product to Review;
                    :Display Product Details;
                    :View Product Image;
                    :Check Certificates;
                    :Review Seller Info;
                    
                    if (Approve?) then
                        :Mark as Approved;
                        :Update approvalStatus = 'approved';
                        :Save Timestamp;
                        :Save Admin ID;
                        :Product Goes Live;
                        :Send Approval Notification to Seller;
                        :Product Visible to Customers;
                    else (Reject?)
                        :Mark as Rejected;
                        :Update approvalStatus = 'rejected';
                        :Enter Rejection Reason;
                        :Save Decision;
                        :Send Rejection Notification to Seller;
                    endif
                repeat
            and
                :View Pending Auctions;
                :List All Pending Auctions;
                :Filter by Category;
                :Sort by Date;
                
                repeat
                    :Select Auction to Review;
                    :Display Auction Details;
                    :Check Certificate Verification;
                    :Review Seller Information;
                    
                    if (Approve?) then
                        :Mark as Approved;
                        :Update approvalStatus = 'approved';
                        :Set Auction Status to Active;
                        :Send Approval Notification;
                        :Auction Goes Live;
                    else (Reject?)
                        :Mark as Rejected;
                        :Send Rejection Notification;
                    endif
                repeat
            endfork
        }

        partition AdminUserManagement {
            :Navigate to User Management;
            :View All Users;
            :Filter: Buyers, Sellers, Admins;
            
            repeat
                :Select User;
                fork
                    :View User Details;
                    :Profile Information;
                    :Activity History;
                and
                    :For Sellers Only;
                    :View Verification Status;
                    :Review Documents;
                    :NIC Document;
                    :Business Registration;
                and
                    :Manage Account Status;
                    if (Account Active?) then
                        :Option to Deactivate;
                        :Record Timestamp;
                    else
                        :Option to Activate;
                        :Record Timestamp;
                    endif
                and
                    :Seller Verification;
                    if (Documents Valid?) then
                        :Mark as Verified;
                        :Activate Account;
                    else
                        :Request Additional Documents;
                        :Reject Verification;
                    endif
                endfork
            repeat
        }

        partition AdminAnalytics {
            :View Platform Analytics;
            fork
                :User Statistics;
                :Total Users;
                :Active Users;
                :Inactive Users;
                :Buyer/Seller Breakdown;
            and
                :Product Statistics;
                :Total Products;
                :Approved Products;
                :Pending Products;
                :Rejected Products;
            and
                :Auction Statistics;
                :Total Auctions;
                :Active Auctions;
                :Completed Auctions;
                :Average Bid Price;
            and
                :Sales Statistics;
                :Total Orders;
                :Total Revenue;
                :Average Order Value;
                :Payment Status Breakdown;
            endfork
        }

        partition AdminModeration {
            :Monitor User Reports;
            :Review Complaints;
            :Take Moderation Actions;
            fork
                :Suspend User Account;
                :Block Fraudulent Sellers;
            or
                :Remove Inappropriate Content;
                :Delete Problematic Listings;
            or
                :Resolve Disputes;
                :Refund Failed Orders;
            endfork
        }

    endif

    partition GlobalSystemServices {
        fork
            :Firebase Authentication;
            :Handle Login/Logout;
            :Manage Sessions;
        and
            :Firebase Firestore;
            :Read/Write Operations;
            :Real-time Updates;
            :Query Data;
        and
            :Firebase Cloud Storage;
            :Upload Images;
            :Store Certificates;
        and
            :Firebase Messaging;
            :Send Push Notifications;
            :Handle Message Delivery;
        and
            :Stripe Payment;
            :Process Payments;
            :Handle Transactions;
            :Manage Refunds;
        and
            :Notification Service;
            :Trigger Notifications;
            :Store in Firestore;
            :Display to Users;
        endfork
    }

    partition NotificationEngine {
        fork
            :Product Approval Notification;
            :Sent to Seller;
            :When Status Changes;
        and
            :Auction Approval Notification;
            :Sent to Seller;
            :When Status Changes;
        and
            :Bid Placed Notification;
            :Sent to Seller;
            :Sent to Previous Bidder (Outbid);
        and
            :Auction Ending Soon;
            :Sent to Active Bidders;
            :Before 1 Hour;
        and
            :Auction Won Notification;
            :Sent to Winning Bidder;
            :Payment Instructions;
        and
            :Order Confirmation;
            :Sent to Buyer & Seller;
            :Order Details;
        and
            :Shipping Notification;
            :Sent to Buyer;
            :Tracking Information;
        and
            :Delivery Notification;
            :Sent to Buyer;
            :Order Delivered;
        and
            :Payment Notification;
            :Payment Received;
            :Payment Failed;
        and
            :System Messages;
            :Maintenance Alerts;
            :Security Alerts;
        endfork
    }

    :Session Log Data;
    :Store in Firebase;
    :Update User Activity;
    :Close Session;
    end
```

---

## Complete System Overview

This comprehensive activity diagram covers:

### 🔐 **Authentication Layer**
- User login/registration
- Role-based access (Buyer/Seller/Admin)
- Document verification for sellers

### 👥 **Buyer Flow**
1. **Product Browsing** - View 4 popular gems, details, contact seller
2. **Auction Participation** - Place bids, monitor auctions
3. **Shopping Cart** - Add items, apply coupons, manage quantities
4. **Checkout & Payment** - Address entry, payment processing via Stripe
5. **Order Management** - Track orders, view history
6. **Notifications** - Receive real-time updates

### 🏪 **Seller Flow**
1. **Product Management** - Create, edit, submit for approval
2. **Auction Management** - Create auctions, monitor bids
3. **Order Fulfillment** - Process orders, ship items
4. **Analytics** - Track sales, revenue, performance
5. **Seller Notifications** - Approval status, bids, orders

### ⚙️ **Admin Flow**
1. **Approval System** - Review & approve/reject products & auctions
2. **User Management** - Verify sellers, activate/deactivate accounts
3. **Analytics Dashboard** - Monitor all platform statistics
4. **Moderation** - Handle complaints and disputes

### 🔔 **Notification Engine**
- Approval notifications
- Auction alerts (new bids, outbid, ending soon)
- Order updates (confirmation, shipping, delivery)
- Payment notifications
- System messages

### 📱 **Global Services**
- Firebase Authentication & Firestore
- Cloud Storage for images
- Firebase Cloud Messaging
- Stripe Payment Integration
- Real-time notification system

This diagram provides a complete view of all system operations and user interactions!
