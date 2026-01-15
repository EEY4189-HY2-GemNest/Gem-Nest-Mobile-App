# Firebase Cloud Functions for Stripe - Setup Guide

## Overview

**YES, you CAN use Firebase instead of a separate Node.js backend!** 

This guide shows how to use **Firebase Cloud Functions** to handle Stripe payments securely. This is actually the **recommended approach** when using Firebase as your backend.

## Why Firebase Cloud Functions?

✅ **No separate server to manage**  
✅ **Automatic scaling**  
✅ **Integrated with Firestore** (where you're already storing data)  
✅ **Free tier included** (with generous limits)  
✅ **Secure** (secret keys never exposed to frontend)  
✅ **Easy to deploy** (one command)  

## Quick Comparison

| Feature | Firebase Cloud Functions | Separate Node.js Backend |
|---------|--------------------------|--------------------------|
| Server Management | Automatic (Google manages) | You manage |
| Cost | Pay per execution | Pay per server instance |
| Scaling | Automatic | Manual |
| Integration | Native Firebase integration | Via API calls |
| Complexity | Simple setup | More complex |
| Best For | Firebase-first projects | Microservices architecture |

## Setup Instructions

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Step 2: Initialize Cloud Functions

In your project root directory:

```bash
firebase init functions
```

Select your Firebase project and choose **JavaScript** when prompted.

### Step 3: Install Dependencies

```bash
cd functions
npm install stripe express cors
```

Your `functions/package.json` should have:
```json
{
  "dependencies": {
    "firebase-admin": "^11.0.0",
    "firebase-functions": "^4.0.0",
    "stripe": "^14.0.0",
    "express": "^4.18.0",
    "cors": "^2.8.5"
  }
}
```

### Step 4: Copy Cloud Functions Code

Copy the code from `FIREBASE_CLOUD_FUNCTIONS.js` to your `functions/index.js` file.

### Step 5: Set Environment Variables

Set your Stripe keys as Firebase environment variables:

```bash
# From your Stripe Dashboard
firebase functions:config:set stripe.secret_key="sk_test_YOUR_ACTUAL_SECRET_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_test_YOUR_WEBHOOK_SECRET"
```

Verify they're set:
```bash
firebase functions:config:get
```

### Step 6: Deploy Functions

Deploy to Firebase:

```bash
firebase deploy --only functions
```

You'll see output like:
```
✔  Deploy complete!

Function URLs:
  createPaymentIntent: https://us-central1-your-project.cloudfunctions.net/createPaymentIntent
  confirmPayment: https://us-central1-your-project.cloudfunctions.net/confirmPayment
  stripeWebhook: https://us-central1-your-project.cloudfunctions.net/stripeWebhook
```

### Step 7: Update Stripe Webhook

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/developers/webhooks)
2. Click **Add endpoint**
3. Paste your webhook URL: `https://us-central1-your-project.cloudfunctions.net/stripeWebhook`
4. Select events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `charge.refunded`
5. Copy the webhook signing secret
6. Set it as an environment variable:
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_test_YOUR_WEBHOOK_SECRET"
   firebase deploy --only functions
   ```

### Step 8: Update Flutter App

Use the Firebase version of Stripe service:

```dart
// In your imports
import 'package:gemnest_mobile_app/stripe_service_firebase.dart';

// Initialize in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await StripeService.initialize();
  runApp(const MyApp());
}
```

## Usage Example

### Create Payment Intent

```dart
final stripeService = StripeService();

final paymentIntent = await stripeService.createPaymentIntent(
  amount: 99.99,
  currency: 'USD',
  orderId: 'ORD-12345',
  description: 'Purchase from GemNest',
);

// Initialize and display payment sheet
await stripeService.initPaymentSheet(
  paymentIntentClientSecret: paymentIntent['client_secret'],
  customerID: FirebaseAuth.instance.currentUser!.uid,
);

final success = await stripeService.displayPaymentSheet();

if (success) {
  // Confirm payment with backend
  await stripeService.confirmPayment(
    intentId: paymentIntent['intent_id'],
    orderId: 'ORD-12345',
  );
}
```

### Get Order History

```dart
// Get all orders
final orders = await stripeService.getUserOrders();

// Get specific order
final order = await stripeService.getOrderDetails('ORD-12345');

// Watch orders in real-time
stripeService.watchUserOrders().listen((orders) {
  print('Orders updated: $orders');
});

// Watch specific order status
stripeService.watchOrder('ORD-12345').listen((order) {
  if (order != null && order['status'] == 'completed') {
    print('Order completed!');
  }
});
```

### Process Refund

```dart
final refund = await stripeService.processRefund(
  orderId: 'ORD-12345',
  amount: 99.99, // Optional - full refund if not specified
);

if (refund!['success']) {
  print('Refund processed: ${refund['refund_id']}');
}
```

## Firestore Collection Structure

Your orders are automatically saved in Firestore with this structure:

```
orders/
├── ORD-12345/
│   ├── userId: "user_uid"
│   ├── paymentIntentId: "pi_xxx"
│   ├── amount: 99.99
│   ├── currency: "USD"
│   ├── description: "Purchase from GemNest"
│   ├── status: "completed" | "failed" | "pending" | "refunded"
│   ├── paymentStatus: "paid" | "failed" | "refunded"
│   ├── createdAt: Timestamp
│   ├── updatedAt: Timestamp
│   ├── paidAt: Timestamp (if paid)
│   ├── chargeId: "ch_xxx" (if paid)
│   └── refundId: "re_xxx" (if refunded)
```

## Firestore Security Rules

Add these rules to protect order data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Orders can only be read/written by the owner
    match /orders/{orderId} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    // Allow Cloud Functions to access
    match /{document=**} {
      allow read, write: if request.auth.uid != null;
    }
  }
}
```

## Testing

### Test with Stripe Sandbox Cards

Use the same test cards as before:

```
Visa:       4242 4242 4242 4242
Mastercard: 5555 5555 5555 4444
Expiry:     Any future date (MM/YY)
CVC:        Any 3 digits
```

### View Payments in Stripe Dashboard

1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to **Payments**
3. You'll see all test payments

### Monitor Cloud Functions

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Functions**
4. Click on each function to see logs and performance

## Troubleshooting

### "functions/index.js not found"
- Make sure you ran `firebase init functions`
- Check that you have a `functions` folder

### "STRIPE_SECRET_KEY is undefined"
- Run: `firebase functions:config:get` to verify environment variables
- Ensure you set them correctly: `firebase functions:config:set stripe.secret_key="sk_test_..."`

### "Payment intent creation fails"
- Check Cloud Function logs: `firebase functions:log`
- Verify Stripe keys are correct
- Ensure user is authenticated (Flutter app has `FirebaseAuth`)

### "Webhook not working"
- Verify webhook URL in Stripe Dashboard
- Check Cloud Function logs for errors
- Ensure webhook secret is set correctly

## File Structure

```
your-flutter-app/
├── functions/
│   ├── index.js (copy content from FIREBASE_CLOUD_FUNCTIONS.js)
│   ├── package.json
│   └── .runtimeconfig.json (auto-generated)
├── lib/
│   ├── stripe_service_firebase.dart (use this instead of stripe_service.dart)
│   ├── main.dart
│   └── ...
├── firebase.json
├── pubspec.yaml
└── ...
```

## Production Checklist

- [ ] Use **live** Stripe keys (pk_live_, sk_live_), not test keys
- [ ] Set up Firestore Security Rules
- [ ] Enable HTTPS for webhook endpoint
- [ ] Test full payment flow
- [ ] Set up Cloud Function monitoring and alerts
- [ ] Configure backup and disaster recovery
- [ ] Review Firebase Cloud Functions pricing
- [ ] Set up email notifications for orders
- [ ] Implement order status tracking UI
- [ ] Add refund functionality to admin panel

## Cost Estimation

**Firebase Cloud Functions pricing:**
- 2 million function calls free per month
- $0.40 per million calls after free tier
- Plus compute time charges

**Example:** 1000 orders per month = ~$0.0008 cost (essentially free)

## Next Steps

1. Deploy Cloud Functions
2. Set up Stripe Webhook
3. Update Flutter app to use Firebase version
4. Test with sandbox cards
5. Go live with production keys

## Useful Resources

- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Stripe Firebase Extension](https://firebase.google.com/products/extensions/stripe-firebaseextensions-firestore-stripe-payments)
- [Stripe Webhooks Guide](https://stripe.com/docs/webhooks)
- [Firebase Pricing](https://firebase.google.com/pricing)

## Still Need Help?

Check the comprehensive setup guide at `STRIPE_SETUP_GUIDE.md` for general Stripe concepts and test card information.
