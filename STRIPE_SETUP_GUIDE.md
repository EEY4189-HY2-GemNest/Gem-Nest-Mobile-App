# Stripe Payment Integration Guide

## Overview
This guide explains how to integrate Stripe payment processing into your GemNest Flutter app for accepting Visa and Mastercard payments.

## Setup Instructions

### 1. Get Stripe API Keys

1. Visit [Stripe Dashboard](https://dashboard.stripe.com)
2. Sign in or create a new account
3. Navigate to **Developers → API Keys**
4. You'll see two keys:
   - **Publishable Key** (starts with `pk_test_` for testing)
   - **Secret Key** (starts with `sk_test_` for testing)
5. Copy both keys

### 2. Update Configuration

Update the keys in `lib/stripe_config.dart`:

```dart
static const String publishableKey = 'pk_test_YOUR_ACTUAL_KEY_HERE';
static const String secretKey = 'sk_test_YOUR_ACTUAL_KEY_HERE';
```

### 3. Update Stripe Service

Update `lib/stripe_service.dart` with your keys:

```dart
static const String publishableKey = 'pk_test_YOUR_ACTUAL_KEY_HERE';
static const String secretKey = 'sk_test_YOUR_ACTUAL_KEY_HERE';
static const String backendUrl = 'https://your-backend-url.com';
```

### 4. Install Dependencies

Run the following command:
```bash
flutter pub get
```

### 5. Android Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21 // Stripe requires minimum API 21
    }
}
```

### 6. iOS Configuration

Edit `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY'
      ]
    end
  end
end
```

Then run:
```bash
cd ios && pod install && cd ..
```

## Usage

### From Cart Screen

```dart
import 'package:gemnest_mobile_app/checkout_service.dart';

// In your cart button handler:
onCheckoutPressed: () async {
  final success = await CheckoutService.initiatePayment(
    context,
    totalAmount: cartTotal,
    orderId: 'ORD-12345',
    customerId: userId,
    description: 'Purchase from GemNest',
  );
  
  if (success == true) {
    // Payment successful - update order status
    await CheckoutService.handlePaymentSuccess(
      orderId: 'ORD-12345',
      customerId: userId,
      amount: cartTotal,
    );
  } else {
    // Payment failed or cancelled
    await CheckoutService.handlePaymentFailure(
      orderId: 'ORD-12345',
      customerId: userId,
      reason: 'Payment cancelled by user',
    );
  }
}
```

## Testing

### Test Card Numbers

| Card Type | Number | Expiry | CVC | Result |
|-----------|--------|--------|-----|--------|
| Visa | 4242 4242 4242 4242 | Any future date | Any 3 digits | Success |
| Mastercard | 5555 5555 5555 4444 | Any future date | Any 3 digits | Success |
| Visa (Decline) | 4000 0000 0000 0002 | Any future date | Any 3 digits | Decline |
| American Express | 3782 822463 10005 | Any future date | Any 4 digits | Success |

### Testing Flow

1. Open the app and navigate to checkout
2. Tap "Pay" button to open payment screen
3. Enter test card details from the table above
4. Complete the payment
5. Check [Stripe Dashboard](https://dashboard.stripe.com/payments) to see test transactions

## File Structure

```
lib/
├── stripe_service.dart         # Core Stripe integration logic
├── stripe_config.dart          # Configuration and test cards
├── checkout_service.dart       # Checkout flow management
├── screen/
│   └── payment_screen.dart     # Payment UI screen
├── main.dart                   # Updated with Stripe initialization
└── ...
```

## Key Files

### stripe_service.dart
- `initialize()` - Initialize Stripe with publishable key
- `createPaymentIntent()` - Create payment intent on backend
- `initPaymentSheet()` - Setup payment sheet UI
- `displayPaymentSheet()` - Show payment UI to user
- `createPaymentIntentSimple()` - Direct API call (for testing only)

### payment_screen.dart
- `PaymentScreen` - Full payment UI with order summary
- Displays accepted payment methods
- Shows payment status and test card information

### checkout_service.dart
- `initiatePayment()` - Start payment flow from cart
- `handlePaymentSuccess()` - Process successful payment
- `handlePaymentFailure()` - Handle payment failure

## Production Checklist

- [ ] Replace test keys with live Stripe keys (pk_live_, sk_live_)
- [ ] Set up backend API endpoint for creating payment intents
- [ ] Implement webhook handling for payment confirmations
- [ ] Add proper error handling and user feedback
- [ ] Store payment records in Firestore
- [ ] Implement email notifications for orders
- [ ] Add order history to user profile
- [ ] Set up refund handling
- [ ] Test with real cards in live mode (with small amounts)
- [ ] Review Stripe documentation for compliance

## Useful Links

- [Stripe Flutter Documentation](https://stripe.dev/docs/stripe-js/elements/payment-element)
- [Stripe Dashboard](https://dashboard.stripe.com)
- [Stripe Payment Methods](https://stripe.com/docs/payments/payment-methods)
- [Stripe Testing Guide](https://stripe.com/docs/testing)
- [Flutter Stripe Plugin](https://pub.dev/packages/flutter_stripe)

## Common Issues

### Issue: "flutter_stripe: not found"
**Solution**: Run `flutter pub get` to install dependencies

### Issue: Payment sheet not opening
**Solution**: Ensure your Stripe keys are correctly set in `stripe_service.dart`

### Issue: "Invalid API Key" error
**Solution**: Make sure you're using test keys (pk_test_) and not live keys

### Issue: Android build failing
**Solution**: Ensure `minSdkVersion` is set to 21 or higher in `android/app/build.gradle`

## Next Steps

1. **Backend Integration**: Create endpoint to handle `createPaymentIntent` safely
2. **Order Management**: Save orders to Firestore after successful payment
3. **Webhooks**: Set up Stripe webhooks for payment confirmations
4. **Analytics**: Track payment metrics and conversion rates
5. **Refunds**: Implement refund functionality in admin panel

## Support

For issues or questions:
- Check Stripe Dashboard for transaction details
- Review Flutter Stripe plugin documentation
- Check app logs for error messages
