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
      deliveryOption: checkout.DeliveryOption(
        id: 'standard',
        name: 'Standard Delivery',
        description: 'Standard delivery option',
        cost: 50.0,
        estimatedDays: 3,
        icon: 'assets/icons/delivery.png',
      ),
      specialInstructions: 'Test order for Stripe integration',
    );
  }

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  // Form Controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();

  // Form Keys
  final GlobalKey<FormState> _cardFormKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State Variables
  PaymentMethod? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _saveCard = false;
  String? _orderId;
  bool _isLoadingPaymentMethods = true;
  String? _paymentLoadError;

  // Stripe Integration
  final StripeService _stripeService = StripeService();
  final StripeServiceDirect _stripeServiceDirect = StripeServiceDirect();
  String? _paymentIntentClientSecret;
  String? _stripePaymentIntentId;
  final bool _useDirectStripe = true; // Use direct Stripe for development

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Payment Methods - loaded dynamically from Firebase
  List<PaymentMethod> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateOrderId();
    _loadPaymentMethods();

    // Pre-select card payment method for test mode
    _selectedPaymentMethod = PaymentMethod(
      id: 'card',
      name: 'Credit/Debit Card',
      description: 'Pay securely with your card',
      icon: '💳',
    );
    print(
        'PaymentScreen: Card method pre-selected: ${_selectedPaymentMethod?.id}');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  void _generateOrderId() {
    _orderId = 'GN${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
      _paymentLoadError = null;
    });

    try {
      // Get cart provider to access cart items
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (cartProvider.cartItems.isEmpty) {
        setState(() {
          _isLoadingPaymentMethods = false;
          _paymentLoadError = 'Cart is empty';
        });
        return;
      }

      // Get unique seller IDs from cart items
      final sellerIds = cartProvider.cartItems
          .map((item) => item.sellerId)
          .where((id) => id.isNotEmpty)
          .toSet();

      if (sellerIds.isEmpty) {
        setState(() {
          _isLoadingPaymentMethods = false;
          _paymentLoadError = 'No seller information found';
        });
        return;
      }

      // For simplicity, use the first seller's payment config
      final sellerId = sellerIds.first;

      // Fetch payment config from Firebase
      final doc =
          await _firestore.collection('payment_configs').doc(sellerId).get();
