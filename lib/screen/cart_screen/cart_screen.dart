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
