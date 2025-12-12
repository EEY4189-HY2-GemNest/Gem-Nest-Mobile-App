import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  // Stripe keys - Get from environment variables
  static String get publishableKey {
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('STRIPE_PUBLISHABLE_KEY not found in environment variables');
    }
    return key;
  }

  static String get secretKey {
    final key = dotenv.env['STRIPE_SECRET_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('STRIPE_SECRET_KEY not found in environment variables');
    }
    return key;
  }

  static const String merchantDisplayName = 'GemNest';

  static String get backendUrl {
    final url = dotenv.env['BACKEND_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BACKEND_URL not found in environment variables');
    }
    return url;
  }

  static final StripeService _instance = StripeService._internal();

  factory StripeService() {
    return _instance;
  }

  StripeService._internal();

  static Future<void> initialize() async {
    await Stripe.instance.initialize(
      publishableKey,
      merchantDisplayName: merchantDisplayName,
      stripeAccountId: null, // Use if you have a Stripe Connect account
    );
  }

  /// Create a payment intent on the backend
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount, // Amount in cents (e.g., $10.50 = 1050)
    required String currency,
    required String customerId,
    String? description,
  }) async {
    try {
      // Call your backend to create payment intent
      final dio = Dio();
      final response = await dio.post(
        '$backendUrl/api/payment/create-intent',
        data: {
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency,
          'customerId': customerId,
          'description': description ?? 'GemNest Purchase',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $secretKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      developer.log('Error creating payment intent: $e');
      rethrow;
    }
  }

  /// Initialize Payment Sheet
  Future<void> initPaymentSheet({
    required String paymentIntentClientSecret,
    required String customerID,
    required String ephemeralKeySecret,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          customerId: customerID,
          customerEphemeralKeySecret: ephemeralKeySecret,
          style: ThemeMode.light,
          googlePay: const PaymentSheetGooglePay(
            enabled: true,
            currencyCode: 'USD',
          ),
          applePay: const PaymentSheetApplePay(
            enabled: true,
          ),
        ),
      );
    } catch (e) {
      developer.log('Error initializing payment sheet: $e');
      rethrow;
    }
  }

  /// Display Payment Sheet and process payment
  Future<bool> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      developer.log('Stripe error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      developer.log('Error presenting payment sheet: $e');
      return false;
    }
  }

  /// Process payment for card without payment sheet (alternative method)
  Future<Map<String, dynamic>?> confirmPayment({
    required String clientSecret,
    required CardFieldInputDetails cardDetails,
  }) async {
    try {
      final result = await Stripe.instance.confirmPaymentSheetPayment();
      return {
        'success': true,
        'message': 'Payment successful',
      };
    } on StripeException catch (e) {
      developer.log('Stripe error: ${e.error.localizedMessage}');
      return {
        'success': false,
        'message': e.error.localizedMessage ?? 'Payment failed',
      };
    } catch (e) {
      developer.log('Error confirming payment: $e');
      return {
        'success': false,
        'message': 'An error occurred during payment',
      };
    }
  }

  /// Create payment intent for simple backend-less setup (for testing only)
  /// In production, always use a backend to create payment intents
  Future<Map<String, dynamic>> createPaymentIntentSimple({
    required double amount,
    required String currency,
    required String customerId,
  }) async {
    // This is a simplified version - in production use proper backend
    // For sandbox testing, ensure you're using test card numbers:
    // Visa: 4242 4242 4242 4242
    // Mastercard: 5555 5555 5555 4444
    // Expiry: Any future date
    // CVC: Any 3 digits

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: {
          'amount': (amount * 100).toInt(),
          'currency': currency,
          'customer': customerId,
          'automatic_payment_methods[enabled]': 'true',
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'Authorization': 'Bearer $secretKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'client_secret': response.data['client_secret'],
          'intent_id': response.data['id'],
        };
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      developer.log('Error creating payment intent: $e');
      rethrow;
    }
  }
}
