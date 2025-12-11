import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  // Stripe Publishable Key - Get from https://dashboard.stripe.com/apikeys
  static const String publishableKey =
      'pk_test_YOUR_PUBLISHABLE_KEY_HERE'; // Replace with your key

  static const String merchantDisplayName = 'GemNest';

  static final StripeService _instance = StripeService._internal();

  factory StripeService() {
    return _instance;
  }

  StripeService._internal();

  static Future<void> initialize() async {
    await Stripe.instance.initialize(
      publishableKey,
      merchantDisplayName: merchantDisplayName,
      stripeAccountId: null,
    );
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
      // Verify user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call Firebase Cloud Function
      final callable =
          FirebaseFunctions.instance.httpsCallable('createPaymentIntent');

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

  /// Confirm payment using Firebase Cloud Function
  Future<Map<String, dynamic>?> confirmPayment({
    required String intentId,
    required String orderId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call Firebase Cloud Function to confirm payment
      final callable =
          FirebaseFunctions.instance.httpsCallable('confirmPayment');

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
          FirebaseFunctions.instance.httpsCallable('processRefund');

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
