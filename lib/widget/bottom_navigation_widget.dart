import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/home_screen.dart';
import 'package:gemnest_mobile_app/screen/auction_screen/auction_screen.dart';
import 'package:gemnest_mobile_app/screen/cart_screen/cart_screen.dart';
import 'package:gemnest_mobile_app/screen/order_history_screen/oreder_history_screen.dart';
import 'package:gemnest_mobile_app/screen/profile_screen/profile_screen.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  
  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
  });

  final List<IconData> iconList = const [
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt,
    Icons.person,
  ];

  void _onItemTapped(BuildContext context, int index) {
    // Don't navigate if already on the selected screen
    if (index == currentIndex) return;

    Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = const HomeScreen();
        break;
      case 1:
        targetScreen = const CartScreen();
        break;
      case 2:
        targetScreen = const OrderHistoryScreen();
        break;
      case 3:
        targetScreen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToAuction(BuildContext context) {
    if (currentIndex == 4) return; // Don't navigate if already on auction screen
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuctionScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () => _navigateToAuction(context),
          backgroundColor: const Color.fromARGB(255, 173, 216, 230),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: const Icon(Icons.gavel),
        ),
        const SizedBox(height: 8),
        AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: currentIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.smoothEdge,
          onTap: (index) => _onItemTapped(context, index),
          backgroundColor: const Color.fromARGB(255, 173, 216, 230),
          activeColor: const Color.fromARGB(255, 0, 0, 139),
          leftCornerRadius: 32,
          rightCornerRadius: 32,
        ),
      ],
    );
  }
}