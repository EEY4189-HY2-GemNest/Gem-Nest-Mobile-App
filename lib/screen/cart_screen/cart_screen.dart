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
