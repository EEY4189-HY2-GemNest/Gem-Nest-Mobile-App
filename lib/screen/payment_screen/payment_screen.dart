import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screens/cart_screen/cart_provider.dart';
import 'package:gemnest_mobile_app/screens/order_history_screen/oreder_history_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String address;
  final String name;
  final String mobile;
  final String email;
  final String deliveryNote;
  final List<CartItem> cartItems;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.address,
    required this.cartItems,
    required this.name,
    required this.mobile,
    required this.email,
    required this.deliveryNote,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}


  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}
