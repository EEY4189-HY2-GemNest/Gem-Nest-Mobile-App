/// Stripe Configuration
/// 
/// This file contains Stripe API keys for payment processing.
/// 
/// TO SET UP:
/// 1. Go to https://dashboard.stripe.com/apikeys
/// 2. Copy your keys from the "Publishable key" and "Secret key" sections
/// 3. Ensure you're using TEST mode keys (they start with pk_test_ and sk_test_)
/// 4. Replace the placeholders below with your actual keys

class StripeConfig {
  /// Test mode publishable key
  /// Get from: https://dashboard.stripe.com/apikeys
  /// Starts with: pk_test_
  static const String publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';

  /// Test mode secret key
  /// IMPORTANT: Never share this key or commit it to version control!
  /// Get from: https://dashboard.stripe.com/apikeys
  /// Starts with: sk_test_
  static const String secretKey = 'sk_test_YOUR_SECRET_KEY_HERE';

  /// Test Card Numbers (Sandbox Mode)
  /// Use these for testing without real transactions
  static const testCards = {
    'visa': {
      'number': '4242 4242 4242 4242',
      'expiry': 'Any future date (MM/YY)',
      'cvc': 'Any 3 digits',
      'description': 'Success'
    },
    'mastercard': {
      'number': '5555 5555 5555 4444',
      'expiry': 'Any future date (MM/YY)',
      'cvc': 'Any 3 digits',
      'description': 'Success'
    },
    'visa_decline': {
      'number': '4000 0000 0000 0002',
      'expiry': 'Any future date (MM/YY)',
      'cvc': 'Any 3 digits',
      'description': 'Decline'
    },
    'amex': {
      'number': '3782 822463 10005',
      'expiry': 'Any future date (MM/YY)',
      'cvc': 'Any 4 digits',
      'description': 'Success'
    },
  };

  /// Stripe Merchant Display Name
  static const String merchantName = 'GemNest';

  /// Supported currencies (adjust based on your requirements)
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP'];

  /// Default currency
  static const String defaultCurrency = 'USD';

  /// Backend API endpoint for creating payment intents
  /// Replace with your actual backend URL
  static const String backendUrl = 'https://your-backend-url.com/api';

  /// Instructions for obtaining Stripe keys:
  /// 1. Create a Stripe account: https://stripe.com
  /// 2. Go to Dashboard → Developers → API keys
  /// 3. Copy the Publishable key (starts with pk_test_)
  /// 4. Copy the Secret key (starts with sk_test_)
  /// 5. Update the values above
}
