import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/providers/banner_provider.dart';
import 'package:gemhub/screens/auction_screen/auction_screen.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';
import 'package:gemhub/screens/cart_screen/cart_screen.dart';
import 'package:gemhub/screens/category_screen/category_card.dart';
import 'package:gemhub/screens/order_history_screen/oreder_history_screen.dart';
import 'package:gemhub/screens/product_screen/product_card.dart';
import 'package:gemhub/screens/profile_screen/profile_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final iconList = const [
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt,
    Icons.person,
  ];
  String userName = 'Guest';
  List<Map<String, dynamic>> popularProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchRandomGems();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc['name'] as String? ?? 'Guest';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchRandomGems() async {
    try {
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('products').get();

      final List<Map<String, dynamic>> products = [];
      for (var doc in productsSnapshot.docs) {
        products.add({
          'id': doc.id,
          'imageUrl': doc['imageUrl'],
          'title': doc['title'],
          'pricing': doc['pricing'],
        });
      }

      products.shuffle();
      final randomProducts = products.take(2).toList();

      setState(() {
        popularProducts = randomProducts;
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  
}
