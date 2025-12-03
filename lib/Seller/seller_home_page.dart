import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gemnest_mobile_app/Seller/listed_auction_screen.dart';
import 'package:gemnest_mobile_app/Seller/listed_product_screen.dart';
import 'package:gemnest_mobile_app/Seller/order_history_screen.dart';
import 'package:gemnest_mobile_app/Seller/seller_profile_screen.dart';
import 'package:gemnest_mobile_app/screens/auth_screens/login_screen.dart';

import 'auction_product.dart' as auction;
import 'notifications_page.dart';
import 'product_listing.dart' as product;

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _notifications = [];
  String? currentUserId; // Added to store current user ID

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();

    // Get current user ID
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showNotification(
      String title, int quantity, String? imagePath, String type) {
    setState(() {
      _notifications.add({
        'title': title,
        'quantity': quantity,
        'imagePath': imagePath,
        'type': type,
      });
    });
  }

  

  Widget _buildButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: _isHovered ? 12 : 8,
              shadowColor: Colors.blueAccent.withOpacity(0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios,
                    size: 20, color: Colors.white),
              ],
            ),
          ).animate().scale(duration: 250.ms, curve: Curves.easeInOut),
        ),
      ),
    );
  }
}
