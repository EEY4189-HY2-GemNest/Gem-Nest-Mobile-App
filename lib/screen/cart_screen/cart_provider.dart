import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String imagePath;
  final String title;
  final double price;
  final double originalPrice;
  final String category;
  final String sellerId;
  final int availableStock;
  final bool isDiscounted;
  final double discountPercentage;
  final Map<String, dynamic> productData;
  int quantity;
  bool isSelected;

  CartItem({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.category,
    required this.sellerId,
    required this.availableStock,
    required this.productData,
    this.quantity = 1,
    this.isSelected = true,
    this.isDiscounted = false,
    this.discountPercentage = 0.0,
  });

  double get totalPrice => price * quantity;
  double get originalTotalPrice => originalPrice * quantity;
  double get savings => originalTotalPrice - totalPrice;
  
  bool get isInStock => availableStock > 0;
  bool get isQuantityAvailable => quantity <= availableStock;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'title': title,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'sellerId': sellerId,
      'availableStock': availableStock,
      'quantity': quantity,
      'isSelected': isSelected,
      'isDiscounted': isDiscounted,
      'discountPercentage': discountPercentage,
      'productData': productData,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      imagePath: json['imagePath'],
      title: json['title'],
      price: json['price'].toDouble(),
      originalPrice: json['originalPrice'].toDouble(),
      category: json['category'],
      sellerId: json['sellerId'],
      availableStock: json['availableStock'],
      quantity: json['quantity'],
      isSelected: json['isSelected'] ?? true,
      isDiscounted: json['isDiscounted'] ?? false,
      discountPercentage: json['discountPercentage']?.toDouble() ?? 0.0,
      productData: json['productData'] ?? {},
    );
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];
  final List<CartItem> _wishlistItems = [];
  String? _appliedCouponCode;
  double _couponDiscount = 0.0;
  double _shippingCost = 0.0;
  double _taxRate = 0.1; // 10% tax
  bool _isLoading = false;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  List<CartItem> get wishlistItems => _wishlistItems;
  List<CartItem> get selectedCartItems => _cartItems.where((item) => item.isSelected).toList();
  String? get appliedCouponCode => _appliedCouponCode;
  double get couponDiscount => _couponDiscount;
  double get shippingCost => _shippingCost;
  double get taxRate => _taxRate;
  bool get isLoading => _isLoading;
  
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + (item.isSelected ? item.quantity : 0));
  int get wishlistItemCount => _wishlistItems.length;

  void addToCart(Map<String, dynamic> product) {
    final existingItemIndex =
        _cartItems.indexWhere((item) => item.id == product['id']);
    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex].quantity++;
    } else {
      _cartItems.add(CartItem(
        id: product['id'],
        imagePath: product['imageUrl'] ?? '',
        title: product['title'] ?? 'Untitled',
        price: (product['pricing'] as num? ?? 0).toDouble(),
      ));
    }
    notifyListeners();
  }

  void incrementQuantity(String id) {
    final item = _cartItems.firstWhere((item) => item.id == id);
    item.quantity++;
    notifyListeners();
  }

  void decrementQuantity(String id) {
    final item = _cartItems.firstWhere((item) => item.id == id);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _cartItems.removeWhere((item) => item.id == id);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  double get totalAmount {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }
}
