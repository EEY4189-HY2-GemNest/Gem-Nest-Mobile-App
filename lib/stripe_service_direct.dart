import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeServiceDirect {
  // Stripe Publishable Key - Get from environment variables
  static String get publishableKey {
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
          'STRIPE_PUBLISHABLE_KEY not found in environment variables. Make sure .env file is loaded.');
    }
    return key;
  }

  static const String merchantDisplayName = 'GemNest';

  static final StripeServiceDirect _instance = StripeServiceDirect._internal();

  factory StripeServiceDirect() {
    return _instance;
  }

  StripeServiceDirect._internal();

  static Future<void> initialize() async {
    Stripe.publishableKey = publishableKey;
    developer.log(
        'Stripe initialized with publishable key: ${publishableKey.substring(0, 20)}...');
  }

  /// Simulate a successful payment for development/testing
  /// This bypasses the actual Stripe payment sheet to avoid backend requirements
  Future<bool> simulateTestPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      developer.log('Simulating test payment for amount: $amount $currency');

      // Show a simple dialog to simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      developer.log('Test payment simulation completed successfully');
      return true;
    } catch (e) {
      developer.log('Error in test payment simulation: $e');
      return false;
    }
  }

  /// Initialize payment sheet for test mode
  Future<void> initTestPaymentSheet({
    required String paymentIntentClientSecret,
    String? customerID,
  }) async {
    try {
      developer.log('Initializing test payment sheet...');

      // For development: Use a simplified payment sheet setup
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          customerId: customerID,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF667eea),
            ),
          ),
        ),
      );

      developer.log('Test payment sheet initialized successfully');
    } catch (e) {
      developer.log('Error initializing test payment sheet: $e');
      rethrow;
    }
  }

  /// Display Payment Sheet for testing
  Future<bool> displayTestPaymentSheet() async {
    try {
      developer.log('Presenting test payment sheet...');

      await Stripe.instance.presentPaymentSheet();

      developer.log('Test payment completed successfully');
      return true;
    } on StripeException catch (e) {
      developer
          .log('Stripe error during test payment: ${e.error.localizedMessage}');

      // Handle specific error codes
      switch (e.error.code) {
        case FailureCode.Canceled:
          developer.log('Payment was cancelled by user');
          return false;
        case FailureCode.Failed:
          developer.log('Payment failed: ${e.error.localizedMessage}');
          return false;
        default:
          developer.log('Payment error: ${e.error.localizedMessage}');
          return false;
      }
    } catch (e) {
      developer.log('Error presenting test payment sheet: $e');
      return false;
    }
  }

  /// Complete test payment flow (simulated for development)
  Future<Map<String, dynamic>> processTestPayment({
    required double amount,
    required String currency,
    required String orderId,
    String? description,
  }) async {
    try {
      developer.log('Starting simulated test payment flow for order: $orderId');

      // For development: Simulate successful payment without requiring backend
      final success = await simulateTestPayment(
        amount: amount,
        currency: currency,
      );

      if (success) {
        return {
          'success': true,
          'payment_intent_id':
              'pi_test_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'currency': currency,
          'order_id': orderId,
          'message': 'Test payment completed successfully (simulated)'
        };
      } else {
        return {
          'success': false,
          'message': 'Test payment simulation failed',
          'order_id': orderId,
        };
      }
    } catch (e) {
      developer.log('Test payment flow error: $e');
      return {
        'success': false,
        'message': 'Payment failed: ${e.toString()}',
        'order_id': orderId,
      };
    }
  }

  /// Simulate payment confirmation for testing
  Future<Map<String, dynamic>> confirmTestPayment({
    required String paymentIntentId,
    required String orderId,
  }) async {
    try {
      developer
          .log('Confirming test payment: $paymentIntentId for order: $orderId');

      // Simulate backend payment confirmation
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'payment_intent_id': paymentIntentId,
        'order_id': orderId,
        'status': 'succeeded',
        'message': 'Test payment confirmed successfully'
      };
    } catch (e) {
      developer.log('Test payment confirmation error: $e');
      return {
        'success': false,
        'message': 'Payment confirmation failed: ${e.toString()}',
        'order_id': orderId,
      };
    }
  }
}
