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

  bool _areDeliveryFieldsValid() {
    if (_selectedDeliveryOption == 'pickup') return true;
    return _fullNameController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _postalCodeController.text.isNotEmpty &&
        RegExp(r'^\d{5}$').hasMatch(_postalCodeController.text);
  }

  bool _areCardFieldsValid() {
    if (_selectedPaymentMethod != 'card') return true;
    return _cardNumberController.text.length >= 16 &&
        RegExp(r'^\d{2}/\d{2}$').hasMatch(_expDateController.text) &&
        RegExp(r'^\d{3,4}$').hasMatch(_cvcController.text);
  }

  bool _isFormValid() {
    return _selectedPaymentMethod != null &&
        _areDeliveryFieldsValid() &&
        _areCardFieldsValid();
  }

  Future<void> _handlePaymentSubmission() async {
    if (!_isFormValid()) {
      _showSnackBar('Please fill all required fields correctly');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showSnackBar('Please log in to proceed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> paymentData = {
        'auctionId': widget.auctionId,
        'userId': currentUser.uid,
        'totalPrice': _calculateTotalPrice(),
        'paymentMethod': _selectedPaymentMethod == 'cash' &&
                _selectedDeliveryOption == 'pickup'
            ? 'cash'
            : _selectedPaymentMethod,
        'paymentStatus': 'pending',
        'paymentInitiatedAt': FieldValue.serverTimestamp(),
      };

      if (_selectedDeliveryOption == 'delivery') {
        paymentData.addAll({
          'deliveryDetails': {
            'fullName': _fullNameController.text,
            'address': _addressController.text,
            'city': _cityController.text,
            'postalCode': _postalCodeController.text,
          },
        });
      }

      if (_selectedPaymentMethod == 'card') {
        paymentData.addAll({
          'cardDetails': {
            'cardNumber': _cardNumberController.text,
            'expDate': _expDateController.text,
            'cvc': _cvcController.text,
          },
        });
      }

      DocumentReference paymentRef = await FirebaseFirestore.instance
          .collection('payments')
          .add(paymentData);

      DateTime paymentDate = DateTime.now();
      DateTime deliveryDate = paymentDate.add(const Duration(days: 5));

      Map<String, dynamic> orderData = {
        'userId': currentUser.uid,
        'auctionId': widget.auctionId,
        'orderDate': paymentDate.toIso8601String(),
        'deliveryDate': _selectedDeliveryOption == 'delivery'
            ? deliveryDate.toIso8601String()
            : null,
        'address': _selectedDeliveryOption == 'delivery'
            ? '${_fullNameController.text}, ${_addressController.text}, ${_cityController.text}, ${_postalCodeController.text}'
            : 'Pickup at 123 Luxury Auction St, Colombo, Sri Lanka',
        'paymentMethod': _selectedPaymentMethod == 'cash' &&
                _selectedDeliveryOption == 'pickup'
            ? 'cash'
            : _selectedPaymentMethod,
        'totalAmount': _calculateTotalPrice(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      await FirebaseFirestore.instance
          .collection('auctions')
          .doc(widget.auctionId)
          .update({
        'paymentStatus': 'completed',
        'paymentInitiatedAt': FieldValue.serverTimestamp(),
      });

      await _showPaymentSuccessDialog();
    } catch (e) {
      print("Payment error: $e");
      _showSnackBar('Payment error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _cardNumberController.dispose();
    _expDateController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 26,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      