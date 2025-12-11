import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gemnest_mobile_app/stripe_service.dart';
import 'dart:developer' as developer;

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;
  final String customerId;
  final String description;
  final Function(bool) onPaymentComplete;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.orderId,
    required this.customerId,
    required this.description,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final StripeService _stripeService = StripeService();
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    try {
      await StripeService.initialize();
    } catch (e) {
      developer.log('Error initializing Stripe: $e');
      setState(() {
        _statusMessage = 'Failed to initialize payment system';
      });
    }
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing payment...';
    });

    try {
      // Create payment intent
      final paymentIntentData = await _stripeService.createPaymentIntentSimple(
        amount: widget.amount,
        currency: 'USD',
        customerId: widget.customerId,
      );

      if (!mounted) return;

      final clientSecret = paymentIntentData['client_secret'];

      // Initialize payment sheet
      await _stripeService.initPaymentSheet(
        paymentIntentClientSecret: clientSecret,
        customerID: widget.customerId,
        ephemeralKeySecret: '', // Generate from backend if using customer
      );

      if (!mounted) return;

      // Display payment sheet
      final success = await _stripeService.displayPaymentSheet();

      if (success) {
        setState(() {
          _statusMessage = 'Payment successful!';
          _isProcessing = false;
        });
        widget.onPaymentComplete(true);

        // Close after brief delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _statusMessage = 'Payment cancelled';
          _isProcessing = false;
        });
      }
    } catch (e) {
      developer.log('Payment error: $e');
      setState(() {
        _statusMessage = 'Payment failed: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment Summary Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order ID:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          widget.orderId,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Description:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Expanded(
                          child: Text(
                            widget.description,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('successful')
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('successful')
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusMessage.contains('successful')
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Payment Methods Info
            const Text(
              'Accepted Payment Methods:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodCard('💳 Visa', Colors.blue.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentMethodCard(
                      '💳 Mastercard', Colors.red.shade600),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Pay Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processPayment,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.lock),
              label: Text(
                _isProcessing
                    ? 'Processing...'
                    : 'Pay \$${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            OutlinedButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 24),

            // Test Card Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sandbox Test Cards:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Visa: 4242 4242 4242 4242\n'
                    '• Mastercard: 5555 5555 5555 4444\n'
                    '• Expiry: Any future date\n'
                    '• CVC: Any 3 digits',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String method, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          method,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
