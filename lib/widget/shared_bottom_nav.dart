import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/home_screen.dart';
import 'package:gemnest_mobile_app/screen/auction_screen/auction_screen.dart';
import 'package:gemnest_mobile_app/screen/cart_screen/cart_screen.dart';
import 'package:gemnest_mobile_app/screen/order_history_screen/oreder_history_screen.dart';
import 'package:gemnest_mobile_app/screen/profile_screen/profile_screen.dart';

class SharedBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const SharedBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  static const iconList = [
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt,
    Icons.person,
  ];

  void _onItemTapped(BuildContext context, int index) {
    // If already on the same screen, don't navigate
    if (index == currentIndex) return;

    // Navigate to the selected screen
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
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavigationBar(
      icons: iconList,
      activeIndex: currentIndex == 4
          ? -1
          : currentIndex, // No active index for auction screen
      gapLocation: GapLocation.center,
      notchSmoothness: NotchSmoothness.smoothEdge,
      onTap: (index) => _onItemTapped(context, index),
      backgroundColor: const Color.fromARGB(255, 173, 216, 230),
      activeColor: const Color.fromARGB(255, 0, 0, 139),
      leftCornerRadius: 32,
      rightCornerRadius: 32,
    );
  }

  static FloatingActionButton buildFloatingActionButton(
      BuildContext context, int currentIndex) {
    return FloatingActionButton(
      onPressed: () {
        if (currentIndex == 4) return; // Already on auction screen

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuctionScreen()),
        );
      },
      backgroundColor: const Color.fromARGB(255, 173, 216, 230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: const Icon(Icons.gavel),
    );
  }
}
