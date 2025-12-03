import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/order_history_screen/oreder_history_screen.dart';

class AuctionPaymentScreen extends StatefulWidget {
  final String auctionId;
  final double itemPrice;
  final String title;
  final String imagePath;

  const AuctionPaymentScreen({
    super.key,
    required this.auctionId,
    required this.itemPrice,
    required this.title,
    required this.imagePath,
  });

  @override
  _AuctionPaymentScreenState createState() => _AuctionPaymentScreenState();
}

class _AuctionPaymentScreenState extends State<AuctionPaymentScreen> {
  String _selectedDeliveryOption = 'pickup';
  String? _selectedPaymentMethod;
  final double _deliveryCharge = 1000.0;
  bool _isLoading = false;

  // Controllers for delivery details
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Controllers for card payment
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expDateController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();

  String _formatCurrency(double amount) {
    return 'Rs.${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  double _calculateTotalPrice() {
    return _selectedDeliveryOption == 'delivery'
        ? widget.itemPrice + _deliveryCharge
        : widget.itemPrice;
  }

  
}
