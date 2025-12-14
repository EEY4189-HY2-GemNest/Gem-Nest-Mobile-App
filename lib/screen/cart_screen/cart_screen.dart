// cart_screen.dart
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screen/checkout_screen/checkout_screen.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:gemnest_mobile_app/widget/shared_bottom_nav.dart';
import 'package:provider/provider.dart';

import 'cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Load cart from local storage - handled by CartProvider constructor now
    Future.microtask(() {
      context.read<CartProvider>().validateCartStock();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton:
          SharedBottomNavigation.buildFloatingActionButton(context, 1),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const SharedBottomNavigation(currentIndex: 1),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.backgroundColor, Colors.white],
              ),
            ),
            child: cartProvider.cartItems.isEmpty
                ? _buildEmptyCart()
                : Column(
                    children: [
                      _buildCartHeader(cartProvider),
                      Expanded(child: _buildCartItems(cartProvider)),
                      _buildPriceBreakdown(cartProvider),
                      _buildCheckoutButton(cartProvider),
                    ],
                  ),
          );
        },
      ),
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
      title: Text(
        'Shopping Cart',
        style: AppTheme.headingLarge.copyWith(
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      leading: const ProfessionalAppBarBackButton(),
      actions: [
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return IconButton(
              icon:
                  const Icon(Icons.delete_sweep, color: Colors.white, size: 26),
              onPressed: cartProvider.cartItems.isEmpty
                  ? null
                  : () => _showClearCartDialog(cartProvider),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: const Text(
                'Start Shopping',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartHeader(CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: cartProvider.selectedCartItems.length ==
                cartProvider.cartItems.length,
            onChanged: (value) {
              cartProvider.selectAllItems(value ?? false);
            },
            activeColor: AppTheme.primaryBlue,
          ),
          const Text(
            'Select All',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            '${cartProvider.selectedCartItems.length} of ${cartProvider.cartItems.length} selected',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }  