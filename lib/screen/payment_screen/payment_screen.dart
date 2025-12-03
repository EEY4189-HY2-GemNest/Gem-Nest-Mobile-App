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

class _PaymentScreenState extends State<PaymentScreen> {
  String paymentMethod = 'Cash on Delivery';
  bool isCardDetailsComplete = false;
  bool saveCard = false;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  List<Map<String, String>> savedCards = [];
  String? selectedSavedCard;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  // Load saved cards from SharedPreferences
  Future<void> _loadSavedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCardsString = prefs.getString('savedCards');
    if (savedCardsString != null) {
      setState(() {
        savedCards = List<Map<String, String>>.from(
            savedCardsString.split('|').map((card) {
          final parts = card.split(',');
          return {
            'number': parts[0],
            'expiry': parts[1],
            'type': parts[2],
          };
        }).where((card) => card['number']!.isNotEmpty));
      });
    }
  }

  // Save cards to SharedPreferences
  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsString = savedCards
        .map((card) => "${card['number']},${card['expiry']},${card['type']}")
        .join('|');
    await prefs.setString('savedCards', cardsString);
  }

  Future<void> _saveOrderToFirebase() async {
    try {
      final firestore = FirebaseFirestore.instance;
      DateTime now = DateTime.now();
      DateTime deliveryDate = now.add(const Duration(days: 3));

      final order = {
        'items': widget.cartItems
            .map((item) => {
                  'title': item.title,
                  'quantity': item.quantity,
                  'price': item.price,
                  'totalPrice': item.totalPrice,
                })
            .toList(),
        'totalAmount': widget.totalAmount,
        'address': widget.address,
        'name': widget.name,
        'mobile': widget.mobile,
        'email': widget.email,
        'deliveryNote':
            widget.deliveryNote.isEmpty ? 'None' : widget.deliveryNote,
        'paymentMethod': paymentMethod,
        'orderDate': DateFormat('yyyy-MM-dd').format(now),
        'deliveryDate': DateFormat('yyyy-MM-dd').format(deliveryDate),
        'status': 'Pending',
      };

      await firestore.collection('orders').add(order);

      if (saveCard &&
          paymentMethod == 'Card Payment' &&
          selectedSavedCard == null) {
        final cardNumber = _cardNumberController.text;
        setState(() {
          savedCards.add({
            'number':
                '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}',
            'expiry': _expiryController.text,
            'type': _getCardType(cardNumber),
          });
        });
        await _saveCards();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  

  Widget _buildTotalCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
              'Rs. ${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteOrderButton() {
    bool isButtonEnabled = paymentMethod == 'Cash on Delivery' ||
        (paymentMethod == 'Card Payment' &&
            (selectedSavedCard != null || _validateCardDetails()));

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: isButtonEnabled
            ? () async {
                await _saveOrderToFirebase();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderHistoryScreen()),
                );
              }
            : null,
        child: const Text(
          'Complete Order',
          style: TextStyle(
              fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title, IconData icon, String value) {
    return RadioListTile(
      title: Row(
        children: [
          Icon(icon, color: Colors.blue[700]),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
      value: value,
      groupValue: paymentMethod,
      activeColor: Colors.blue[700],
      onChanged: (value) {
        setState(() {
          paymentMethod = value.toString();
          selectedSavedCard = null;
          isCardDetailsComplete = paymentMethod == 'Cash on Delivery';
        });
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    void Function(String)? onChanged,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        counterText: '',
      ),
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      onChanged: (value) {
        if (onChanged != null) onChanged(value);
        setState(() {
          isCardDetailsComplete = _validateCardDetails();
        });
      },
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}
