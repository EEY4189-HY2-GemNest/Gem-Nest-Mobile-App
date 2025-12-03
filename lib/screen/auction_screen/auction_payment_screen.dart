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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blue[800],
        elevation: 6,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showPaymentSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[400]!],
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Successful!!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[900],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedPaymentMethod == 'cod' &&
                        _selectedDeliveryOption == 'delivery'
                    ? 'Your Cash on Delivery request has been submitted.'
                    : 'Your payment has been processed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 6,
                ),
                child: const Text(
                  'View Order History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 
}
