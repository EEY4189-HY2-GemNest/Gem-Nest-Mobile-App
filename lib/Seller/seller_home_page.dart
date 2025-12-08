import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gemnest_mobile_app/Seller/delivery_config_screen.dart';
import 'package:gemnest_mobile_app/Seller/listed_auction_screen.dart';
import 'package:gemnest_mobile_app/Seller/listed_product_screen.dart';
import 'package:gemnest_mobile_app/Seller/order_history_screen.dart';
import 'package:gemnest_mobile_app/Seller/payment_config_screen.dart';
import 'package:gemnest_mobile_app/Seller/seller_profile_screen.dart';
import 'package:gemnest_mobile_app/screen/auth_screens/login_screen.dart';

import 'auction_product.dart';
import 'notifications_page.dart';
import 'product_listing.dart';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _notifications = [];
  String? currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real data fields
  int _activeProductsCount = 0;
  int _liveAuctionsCount = 0;
  int _totalOrdersCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _cardAnimation = CurvedAnimation(
        parent: _cardAnimationController, curve: Curves.easeInOutCubic);

    _controller.forward();
    _cardAnimationController.forward();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    if (currentUserId == null) return;

    try {
      // Fetch active products count
      final productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: currentUserId)
          .get();

      // Fetch live auctions count
      final auctionsSnapshot = await _firestore
          .collection('auctions')
          .where('sellerId', isEqualTo: currentUserId)
          .where('endDate', isGreaterThan: Timestamp.now())
          .get();

      // Fetch total orders count
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: currentUserId)
          .get();

      if (mounted) {
        setState(() {
          _activeProductsCount = productsSnapshot.docs.length;
          _liveAuctionsCount = auctionsSnapshot.docs.length;
          _totalOrdersCount = ordersSnapshot.docs.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _cardAnimationController.dispose();
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

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.black87,
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Confirm Logout',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            content: const Text('Are you sure you want to logout?',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pop(true);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Logout',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 1: // Notifications
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NotificationsPage(notifications: _notifications),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        break;
      case 2: // Profile
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SellerProfileScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        break;
      case 3: // Logout
        _onWillPop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const SizedBox();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Modern gradient background
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Colors.black87,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Animated background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: DashboardPatternPainter(),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: RefreshIndicator(
                      onRefresh: _fetchRealData,
                      color: Colors.blue,
                      backgroundColor: Colors.grey[900],
                      child: CustomScrollView(
                        slivers: [
                          // Modern App Bar
                          SliverToBoxAdapter(
                            child: _buildModernHeader(),
                          ),
                          // Dashboard Stats Cards
                          SliverToBoxAdapter(
                            child: _buildStatsSection(),
                          ),
                          // Quick Actions Grid
                          SliverToBoxAdapter(
                            child: _buildQuickActionsGrid(),
                          ),
                          // Recent Activity Section
                          SliverToBoxAdapter(
                            child: _buildRecentActivitySection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildModernBottomNav(),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller Dashboard',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back! Manage your business',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
                ],
              ),
              // Container(
              //   width: 80,
              //   height: 80,
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       colors: [Colors.blue.shade600, Colors.blue.shade400],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(color: Colors.blue.shade300, width: 2),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.blue.withOpacity(0.4),
              //         blurRadius: 15,
              //         offset: const Offset(0, 8),
              //       ),
              //     ],
              //   ),
              //   child: ClipRRect(
              //     borderRadius: BorderRadius.circular(18),
              //     child: Image.asset(
              //       'assets/images/logo_new.png',
              //       fit: BoxFit.cover,
              //     ),
              //   ),
              // ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Products',
                  _isLoadingStats ? '...' : _activeProductsCount.toString(),
                  Icons.inventory_2_outlined,
                  Colors.blue,
                  0.ms,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Live Auctions',
                  _isLoadingStats ? '...' : _liveAuctionsCount.toString(),
                  Icons.gavel_outlined,
                  Colors.orange,
                  200.ms,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  _isLoadingStats ? '...' : _totalOrdersCount.toString(),
                  Icons.shopping_bag_outlined,
                  Colors.green,
                  400.ms,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, Duration delay) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[900]!.withOpacity(0.8),
                Colors.grey[800]!.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 600.ms, delay: delay).slideY(begin: 0.3);
  }

  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildActionCard(
                'List Product',
                Icons.add_box_outlined,
                Colors.blue,
                () => _navigateToProductListing(),
                0.ms,
              ),
              _buildActionCard(
                'Start Auction',
                Icons.gavel_outlined,
                Colors.orange,
                () => _navigateToAuctionListing(),
                200.ms,
              ),
              _buildActionCard(
                'View Products',
                Icons.inventory_outlined,
                Colors.green,
                () => _navigateToListedProducts(),
                400.ms,
              ),
              _buildActionCard(
                'Order History',
                Icons.history_outlined,
                Colors.purple,
                () => _navigateToOrderHistory(),
                600.ms,
              ),
              _buildActionCard(
                'Delivery Config',
                Icons.local_shipping_outlined,
                Colors.teal,
                () => _navigateToDeliveryConfig(),
                800.ms,
              ),
              _buildActionCard(
                'Payment Config',
                Icons.payment_outlined,
                Colors.purple,
                () => _navigateToPaymentConfig(),
                1000.ms,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color,
      VoidCallback onTap, Duration delay) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[900]!.withOpacity(0.9),
              Colors.grey[800]!.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: delay)
          .scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildActionCard(
                'Listed Products',
                Icons.inventory_outlined,
                Colors.green,
                () => _navigateToListedProducts(),
                0.ms,
              ),
              _buildActionCard(
                'Auction History',
                Icons.timeline_outlined,
                Colors.purple,
                () => _navigateToAuctionHistory(),
                200.ms,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.dashboard_outlined, Icons.dashboard, 0),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
                Icons.notifications_outlined, Icons.notifications, 1),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person_outline, Icons.person, 2),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.logout_outlined, Icons.logout, 3),
            label: 'Logout',
          ),
        ],
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlineIcon, IconData filledIcon, int index) {
    final isSelected = _selectedIndex == index;
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? Colors.blueAccent.withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Icon(
            isSelected ? filledIcon : outlineIcon,
            size: 26,
          ),
        ),
        if (index == 1 && _notifications.isNotEmpty)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                _notifications.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Navigation methods
  void _navigateToProductListing() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProductListing(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeInOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      _showNotification(
          result['title'], result['quantity'], result['imagePath'], 'product');
    }
  }

  void _navigateToAuctionListing() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuctionProduct(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeInOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      _showNotification(
          result['title'], result['quantity'], result['imagePath'], 'auction');
    }
  }

  void _navigateToListedProducts() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ListedProductScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeInOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToAuctionHistory() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ListedAuctionScreen(
          sellerId: currentUserId!,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeInOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToOrderHistory() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SellerOrderHistoryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeInOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToDeliveryConfig() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DeliveryConfigScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeInOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToPaymentConfig() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PaymentConfigScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeInOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

// Custom painter for background pattern
class DashboardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    const spacing = 60.0;

    // Draw diagonal grid pattern
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      path.moveTo(i, 0);
      path.lineTo(i + size.height, size.height);
    }

    for (double i = 0; i < size.height + spacing; i += spacing) {
      path.moveTo(0, i);
      path.lineTo(size.width, i - size.width);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
