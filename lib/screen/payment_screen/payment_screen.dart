import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gemnest_mobile_app/screen/cart_screen/cart_provider.dart';
import 'package:gemnest_mobile_app/screen/checkout_screen/checkout_screen.dart'
    as checkout;
import 'package:gemnest_mobile_app/screen/order_history_screen/oreder_history_screen.dart';
import 'package:gemnest_mobile_app/stripe_service_direct.dart';
import 'package:gemnest_mobile_app/stripe_service_firebase.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:provider/provider.dart';

// Payment Method Model
class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isAvailable;
  final double? processingFee;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isAvailable = true,
    this.processingFee,
  });
}

// Card Details Model
class CardDetails {
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final String holderName;

  CardDetails({
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.holderName,
  });
}

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final checkout.Address deliveryAddress;
  final checkout.DeliveryOption deliveryOption;
  final String specialInstructions;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.deliveryOption,
    required this.specialInstructions,
  });

  // Factory constructor for testing Stripe integration
  factory PaymentScreen.test({
    double? totalAmount,
  }) {
    return PaymentScreen(
      totalAmount: totalAmount ?? 100.0,
      deliveryAddress: checkout.Address(
        id: 'test-address-1',
        label: 'Home',
        fullName: 'Test User',
        mobile: '+91 9876543210',
        address: '123 Test Street, Test Area',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001',
      ),