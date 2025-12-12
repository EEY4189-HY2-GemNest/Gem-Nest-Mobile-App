import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' as cf;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
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

  static final StripeService _instance = StripeService._internal();

  factory StripeService() {
    return _instance;
  }

  StripeService._internal();

  static Future<void> initialize() async {
    Stripe.publishableKey = publishableKey;
  }

  /// Create a payment intent using Firebase Cloud Function
  /// This is secure because the secret key stays on the backend
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String orderId,
    String? description,
  }) async {
    try {
      // Ensure user is authenticated (sign in anonymously if needed)
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('User not authenticated, signing in anonymously...');
        try {
          final userCredential =
              await FirebaseAuth.instance.signInAnonymously();
          user = userCredential.user;
          developer.log('Signed in anonymously: ${user?.uid}');
        } catch (authError) {
          developer.log('Failed to authenticate: $authError');
          throw Exception('Authentication failed: ${authError.toString()}');
        }
      }

      if (user == null) {
        throw Exception('Unable to authenticate user');
      }

      // Call Firebase Cloud Function
      final callable =
          cf.FirebaseFunctions.instance.httpsCallable('createPaymentIntent');

      final response = await callable.call({
        'amount': amount,
        'currency': currency,
        'orderId': orderId,
        'description': description ?? 'GemNest Purchase',
      });

      final data = response.data as Map<String, dynamic>;

      return {
        'client_secret': data['clientSecret'],
        'intent_id': data['intentId'],
        'status': data['status'],
      };
    } catch (e) {
      developer.log('Error creating payment intent: $e');
      rethrow;
    }
  }

  /// Initialize Payment Sheet
  Future<void> initPaymentSheet({
    required String paymentIntentClientSecret,
    required String customerID,
    String? ephemeralKeySecret,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          customerId: customerID,
          customerEphemeralKeySecret: ephemeralKeySecret,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.blue.shade600,
            ),
          ),
          googlePay: const PaymentSheetGooglePay(
            currencyCode: 'USD',
            merchantCountryCode: 'US',
          ),
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'US',
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

  /// Confirm payment using Firebase Cloud Function
  Future<Map<String, dynamic>?> confirmPayment({
    required String intentId,
    required String orderId,
  }) async {
    try {
      // Ensure user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log(
            'User not authenticated for payment confirmation, signing in anonymously...');
        try {
          final userCredential =
              await FirebaseAuth.instance.signInAnonymously();
          user = userCredential.user;
          developer.log(
              'Signed in anonymously for payment confirmation: ${user?.uid}');
        } catch (authError) {
          developer.log(
              'Failed to authenticate for payment confirmation: $authError');
          throw Exception('Authentication failed: ${authError.toString()}');
        }
      }

      if (user == null) {
        throw Exception('Unable to authenticate user for payment confirmation');
      }

      // Call Firebase Cloud Function to confirm payment
      final callable =
          cf.FirebaseFunctions.instance.httpsCallable('confirmPayment');

      final response = await callable.call({
        'intentId': intentId,
        'orderId': orderId,
      });

      final data = response.data as Map<String, dynamic>;

      return {
        'success': data['success'] ?? false,
        'status': data['status'],
        'message': data['message'],
        'amount': data['amount'],
      };
    } catch (e) {
      developer.log('Error confirming payment: $e');
      return {
        'success': false,
        'message': 'An error occurred during payment: $e',
      };
    }
  }

  /// Get user's order history from Firestore
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      developer.log('Error getting user orders: $e');
      return [];
    }
  }

  /// Get a specific order by ID
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      developer.log('Error getting order details: $e');
      return null;
    }
  }

  /// Process refund using Firebase Cloud Function
  Future<Map<String, dynamic>?> processRefund({
    required String orderId,
    double? amount,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call Firebase Cloud Function to process refund
      final callable =
          cf.FirebaseFunctions.instance.httpsCallable('processRefund');

      final response = await callable.call({
        'orderId': orderId,
        if (amount != null) 'amount': amount,
      });

      final data = response.data as Map<String, dynamic>;

      return {
        'success': data['success'] ?? false,
        'refund_id': data['refundId'],
        'status': data['status'],
        'amount': data['amount'],
      };
    } catch (e) {
      developer.log('Error processing refund: $e');
      return {
        'success': false,
        'message': 'An error occurred during refund: $e',
      };
    }
  }

  /// Listen to order status changes in real-time
  Stream<Map<String, dynamic>?> watchOrder(String orderId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return {
          'id': snapshot.id,
          ...snapshot.data()!,
        };
      }
      return null;
    });
  }

  /// Listen to user's orders in real-time
  Stream<List<Map<String, dynamic>>> watchUserOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    });
  }
}
