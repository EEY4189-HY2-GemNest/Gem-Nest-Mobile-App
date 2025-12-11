import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/checkout_service.dart';

/// Example Cart Checkout Button
/// This shows how to integrate the Stripe payment into your cart screen
/// 
/// Add this to your cart_screen.dart or cart checkout widget

class CartCheckoutButton extends StatefulWidget {
  final double totalAmount;
  final List<CartItem> cartItems;
  final String userId;
  final Function()? onPaymentSuccess;

  const CartCheckoutButton({
    Key? key,
    required this.totalAmount,
    required this.cartItems,
    required this.userId,
    this.onPaymentSuccess,
  }) : super(key: key);

  @override
  State<CartCheckoutButton> createState() => _CartCheckoutButtonState();
}

class _CartCheckoutButtonState extends State<CartCheckoutButton> {
  bool _isProcessing = false;

  Future<void> _handleCheckout() async {
    if (widget.totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Generate order ID (use your own logic)
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      // Create description from cart items
      final description =
          'Purchase of ${widget.cartItems.length} item(s) from GemNest';

      // Initiate payment
      final paymentSuccess = await CheckoutService.initiatePayment(
        context,
        totalAmount: widget.totalAmount,
        orderId: orderId,
        customerId: widget.userId,
        description: description,
      );

      if (paymentSuccess == true && mounted) {
        // Payment successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Thank you for your purchase.'),
            backgroundColor: Colors.green,
          ),
        );

        // Handle post-payment actions
        await CheckoutService.handlePaymentSuccess(
          orderId: orderId,
          customerId: widget.userId,
          amount: widget.totalAmount,
        );

        // Notify parent widget
        widget.onPaymentSuccess?.call();

        // Optional: Clear cart or navigate to order confirmation
        // Future.delayed(
        //   const Duration(seconds: 1),
        //   () => Navigator.of(context).pushReplacementNamed('/order-confirmation'),
        // );
      } else if (mounted) {
        // Payment cancelled or failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during checkout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Proceed to Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for CartItem class
/// Replace this with your actual CartItem model
class CartItem {
  final String id;
  final String title;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
  });
}

/// Example of how to use in your cart screen:
/*
import 'package:gemnest_mobile_app/widgets/cart_checkout_button.dart';

class CartScreen extends StatelessWidget {
  final List<CartItem> cartItems = [...]; // Your cart items
  final double totalAmount = 99.99;
  final String userId = 'user_123';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return ListTile(
            title: Text(item.title),
            subtitle: Text('\$${item.price} x ${item.quantity}'),
          );
        },
      ),
      bottomNavigationBar: CartCheckoutButton(
        totalAmount: totalAmount,
        cartItems: cartItems,
        userId: userId,
        onPaymentSuccess: () {
          // Clear cart after successful payment
          // Navigate to order confirmation
          // Update user's order history
        },
      ),
    );
  }
}
*/
