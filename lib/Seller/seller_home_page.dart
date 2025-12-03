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


}
