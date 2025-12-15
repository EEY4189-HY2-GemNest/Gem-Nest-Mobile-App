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

      if (!doc.exists) {
        // Fallback to default payment methods if no config exists
        setState(() {
          _paymentMethods = [
            PaymentMethod(
              id: 'card',
              name: 'Credit/Debit Card',
              description: 'Pay securely with your card',
              icon: '💳',
            ),
            PaymentMethod(
              id: 'cod',
              name: 'Cash on Delivery',
              description: 'Pay when you receive your order',
              icon: '💵',
              processingFee: 50.0,
            ),
          ];
          if (_paymentMethods.isNotEmpty) {
            _selectedPaymentMethod = _paymentMethods.first;
          }
          _isLoadingPaymentMethods = false;
        });
        return;
      }

      final data = doc.data()!;
      final paymentOptions = <PaymentMethod>[];

      // Map payment method IDs to emoji icons
      const iconMap = {
        'card': '💳',
        'cod': '💵',
        'bank_transfer': '🏦',
      };

      data.forEach((key, value) {
        if (key != 'sellerId' && key != 'updatedAt') {
          final methodData = value as Map<String, dynamic>;
          if (methodData['enabled'] == true) {
            paymentOptions.add(
              PaymentMethod(
                id: key,
                name: methodData['name'] ?? key,
                description: methodData['description'] ?? '',
                icon: iconMap[key] ?? '💳',
                processingFee: key == 'cod' ? 50.0 : null,
              ),
            );
          }
        }
      });

      setState(() {
        _paymentMethods = paymentOptions;
        if (_paymentMethods.isNotEmpty) {
          // Always select the card method first
          _selectedPaymentMethod = _paymentMethods.firstWhere(
            (method) => method.id == 'card',
            orElse: () => _paymentMethods.first,
          );
        }
        _isLoadingPaymentMethods = false;
      });
    } catch (e) {
      print('Error loading payment methods: $e');
      setState(() {
        _isLoadingPaymentMethods = false;
        _paymentLoadError = 'Failed to load payment methods';
        // Fallback to default methods
        _paymentMethods = [
          PaymentMethod(
            id: 'card',
            name: 'Credit/Debit Card',
            description: 'Pay securely with your card',
            icon: '💳',
          ),
          PaymentMethod(
            id: 'cod',
            name: 'Cash on Delivery',
            description: 'Pay when you receive your order',
            icon: '💵',
            processingFee: 50.0,
          ),
        ];
        // Ensure card is always selected first
        _selectedPaymentMethod = _paymentMethods.firstWhere(
          (method) => method.id == 'card',
          orElse: () => _paymentMethods.first,
        );
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundColor, Colors.white],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderSummaryCard(),
                      const SizedBox(height: 24),
                      _buildPaymentMethodsSection(),
                      const SizedBox(height: 24),
                      if (_selectedPaymentMethod?.id == 'card')
                        _buildCardDetailsForm(),
                      if (_selectedPaymentMethod?.id == 'cod') _buildCODInfo(),
                      const SizedBox(height: 24),
                      _buildSecurityInfo(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
      ),
      elevation: 0,
      leading: const ProfessionalAppBarBackButton(),
      title: const Text(
        'Payment',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildProgressStep('Cart', 0, true),
          _buildProgressLine(true),
          _buildProgressStep('Checkout', 1, true),
          _buildProgressLine(true),
          _buildProgressStep('Payment', 2, true),
          _buildProgressLine(false),
          _buildProgressStep('Confirm', 3, false),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String title, int step, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryBlue : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.primaryBlue : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppTheme.primaryBlue : Colors.grey[300],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final processingFee = _selectedPaymentMethod?.processingFee ?? 0.0;
    final finalTotal = widget.totalAmount + processingFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Order ID: $_orderId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.deliveryAddress.fullName}, ${widget.deliveryAddress.city}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      widget.deliveryOption.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal',
              'Rs.${(widget.totalAmount - widget.deliveryOption.cost - (widget.totalAmount * 0.18)).toStringAsFixed(2)}'),
          _buildPriceRow('Delivery Charges',
              'Rs.${widget.deliveryOption.cost.toStringAsFixed(2)}'),
          _buildPriceRow('Taxes (GST)',
              'Rs.${(widget.totalAmount * 0.18).toStringAsFixed(2)}'),
          if (processingFee > 0)
            _buildPriceRow(
                'Processing Fee', 'Rs.${processingFee.toStringAsFixed(2)}',
                textColor: AppTheme.errorRed),
          const Divider(thickness: 1.5),
          _buildPriceRow('Total Amount', 'Rs.${finalTotal.toStringAsFixed(2)}',
              isBold: true, textSize: 18, textColor: AppTheme.primaryBlue),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment_outlined,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667eea).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              method.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      if (method.processingFee != null &&
                          method.processingFee! > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+Rs.${method.processingFee!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFE53E3E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF667eea),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _cardFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Card Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _cardNumberController,
              'Card Number',
              Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberFormatter(),
                LengthLimitingTextInputFormatter(19),
              ],
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter card number';
                }
                final cleanValue = value!.replaceAll(' ', '');
                if (cleanValue.length < 13 || cleanValue.length > 19) {
                  return 'Please enter valid card number';
                }
                if (!_validateCardNumber(cleanValue)) {
                  return 'Invalid card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _holderNameController,
              'Cardholder Name',
              Icons.person_outline,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter cardholder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _expiryController,
                    'MM/YY',
                    Icons.calendar_month_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryDateFormatter(),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter expiry';
                      }
                      if (value!.length != 5) {
                        return 'Please enter valid expiry';
                      }
                      if (!_validateExpiryDate(value)) {
                        return 'Card has expired';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    _cvvController,
                    'CVV',
                    Icons.security_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter CVV';
                      }
                      if (value!.length < 3 || value.length > 4) {
                        return 'Please enter valid CVV';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _saveCard,
                  onChanged: (value) {
                    setState(() {
                      _saveCard = value ?? false;
                    });
                  },
                  activeColor: AppTheme.primaryBlue,
                ),
                const Expanded(
                  child: Text(
                    'Save card for future payments (Secure)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCODInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash on Delivery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Important Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Additional Rs.25 processing fee applies\n'
                  '• Please keep exact change ready\n'
                  '• Payment due upon delivery\n'
                  '• Cash accepted at doorstep',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // child: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     Row(
      //       children: [
      //         Container(
      //           padding: const EdgeInsets.all(8),
      //           decoration: BoxDecoration(
      //             color: const Color(0xFF38A169).withOpacity(0.1),
      //             borderRadius: BorderRadius.circular(8),
      //           ),
      //           child: const Icon(
      //             Icons.security_outlined,
      //             color: Color(0xFF38A169),
      //             size: 20,
      //           ),
      //         ),
      //         const SizedBox(width: 12),
      //         const Text(
      //           'Secure Payment',
      //           style: TextStyle(
      //             fontSize: 18,
      //             fontWeight: FontWeight.bold,
      //             color: Color(0xFF2D3748),
      //           ),
      //         ),
      //       ],
      //     ),
      //     const SizedBox(height: 16),
      //     const Row(
      //       children: [
      //         Icon(Icons.lock_outlined, color: Color(0xFF38A169), size: 16),
      //         SizedBox(width: 8),
      //         Text('256-bit SSL encryption', style: TextStyle(fontSize: 14)),
      //       ],
      //     ),
      //     const SizedBox(height: 8),
      //     const Row(
      //       children: [
      //         Icon(Icons.verified_outlined, color: Color(0xFF38A169), size: 16),
      //         SizedBox(width: 8),
      //         Text('PCI DSS compliant', style: TextStyle(fontSize: 14)),
      //       ],
      //     ),
      //     const SizedBox(height: 8),
      //     const Row(
      //       children: [
      //         Icon(Icons.shield_outlined, color: Color(0xFF38A169), size: 16),
      //         SizedBox(width: 8),
      //         Text('100% secure transactions', style: TextStyle(fontSize: 14)),
      //       ],
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, double textSize = 14, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? const Color(0xFF4A5568),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: textColor ?? const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildBottomSheet() {
    final processingFee = _selectedPaymentMethod?.processingFee ?? 0.0;
    final finalTotal = widget.totalAmount + processingFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  'Rs.${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing Payment...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _selectedPaymentMethod?.id == 'cod'
                            ? 'Place Order'
                            : 'Pay Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() async {
    // Validate form based on payment method
    bool isValid = true;
    if (_selectedPaymentMethod?.id == 'card') {
      isValid = _cardFormKey.currentState?.validate() ?? false;
    }

    if (!isValid) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please login to continue', Colors.red);
        return;
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final processingFee = _selectedPaymentMethod?.processingFee ?? 0.0;
      final finalTotal = widget.totalAmount + processingFee;

      // Process payment based on method
      if (_selectedPaymentMethod?.id == 'card') {
        await _processCardPayment();
      } else {
        // For COD, just simulate order processing
        await Future.delayed(const Duration(seconds: 2));
      }

      // Create order in Firestore
      final orderData = {
        'orderId': _orderId,
        'userId': user.uid,
        'items': cartProvider.cartItems
            .map((item) => {
                  'id': item.id,
                  'name': item.name,
                  'price': item.finalPrice,
                  'quantity': item.quantity,
                  'image': item.image,
                })
            .toList(),
        'deliveryAddress': widget.deliveryAddress.toMap(),
        'deliveryOption': {
          'id': widget.deliveryOption.id,
          'name': widget.deliveryOption.name,
          'cost': widget.deliveryOption.cost,
          'estimatedDays': widget.deliveryOption.estimatedDays,
        },
        'paymentMethod': {
          'id': _selectedPaymentMethod!.id,
          'name': _selectedPaymentMethod!.name,
          'processingFee': processingFee,
        },
        'stripePaymentIntentId': _stripePaymentIntentId,
        'specialInstructions': widget.specialInstructions,
        'totalAmount': finalTotal,
        'status': 'confirmed',
        'orderDate': FieldValue.serverTimestamp(),
        'estimatedDelivery': DateTime.now()
            .add(Duration(days: widget.deliveryOption.estimatedDays)),
      };