import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  double get finalPrice => price; // Price after any applicable discounts
  String get name => title; // Alias for title
  String get image => imagePath; // Alias for imagePath

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
  final double _taxRate = 0.1; // 10% tax
  bool _isLoading = false;

  // Constructor - automatically load from local storage
  CartProvider() {
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    await loadCartFromLocal();
  }

  // Getters
  List<CartItem> get cartItems => _cartItems;
  List<CartItem> get wishlistItems => _wishlistItems;
  List<CartItem> get selectedCartItems =>
      _cartItems.where((item) => item.isSelected).toList();
  String? get appliedCouponCode => _appliedCouponCode;
  double get couponDiscount => _couponDiscount;
  double get shippingCost => _shippingCost;
  double get taxRate => _taxRate;
  bool get isLoading => _isLoading;

  int get cartItemCount => _cartItems.fold(
      0, (total, item) => total + (item.isSelected ? item.quantity : 0));
  int get wishlistItemCount => _wishlistItems.length;

  // Price calculations
  double get subtotal =>
      selectedCartItems.fold(0.0, (total, item) => total + item.totalPrice);
  double get originalSubtotal => selectedCartItems.fold(
      0.0, (total, item) => total + item.originalTotalPrice);
  double get totalSavings => originalSubtotal - subtotal + _couponDiscount;
  double get taxAmount => (subtotal - _couponDiscount) * _taxRate;
  double get totalAmount =>
      subtotal - _couponDiscount + _shippingCost + taxAmount;

  // Additional computed properties
  double get savings => _couponDiscount;
  String? get appliedCoupon => _appliedCouponCode;
  double get discountAmount => _couponDiscount;

  // Cart operations
  Future<bool> addToCart(Map<String, dynamic> product) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check stock availability
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(product['id'])
          .get();

      if (!productDoc.exists) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final stockData = productDoc.data()!;
      final availableStock = stockData['quantity'] ?? 0;

      final existingItemIndex =
          _cartItems.indexWhere((item) => item.id == product['id']);

      if (existingItemIndex != -1) {
        final currentItem = _cartItems[existingItemIndex];
        if (currentItem.quantity < availableStock) {
          currentItem.quantity++;
        } else {
          _isLoading = false;
          notifyListeners();
          return false; // Out of stock
        }
      } else {
        if (availableStock > 0) {
          _cartItems.add(CartItem(
            id: product['id'],
            imagePath: product['imageUrl'] ?? '',
            title: product['title'] ?? 'Untitled',
            price: (product['pricing'] as num? ?? 0).toDouble(),
            originalPrice: ((product['originalPrice'] as num?) ??
                    (product['pricing'] as num? ?? 0))
                .toDouble(),
            category: product['category'] ?? '',
            sellerId: product['sellerId'] ?? '',
            availableStock: (availableStock as num).toInt(),
            productData: product,
            isDiscounted: product['isDiscounted'] ?? false,
            discountPercentage:
                (product['discountPercentage'] as num?)?.toDouble() ?? 0.0,
          ));
        } else {
          _isLoading = false;
          notifyListeners();
          return false; // Out of stock
        }
      }

      await _saveCartToLocal();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void incrementQuantity(String id) {
    final itemIndex = _cartItems.indexWhere((item) => item.id == id);
    if (itemIndex != -1) {
      final item = _cartItems[itemIndex];
      if (item.quantity < item.availableStock) {
        item.quantity++;
        _saveCartToLocal();
        notifyListeners();
      }
    }
  }

  void decrementQuantity(String id) {
    final itemIndex = _cartItems.indexWhere((item) => item.id == id);
    if (itemIndex != -1) {
      final item = _cartItems[itemIndex];
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cartItems.removeAt(itemIndex);
      }
      _saveCartToLocal();
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    _saveCartToLocal();
    notifyListeners();
  }

  void toggleItemSelection(String id) {
    final item = _cartItems.firstWhere((item) => item.id == id);
    item.isSelected = !item.isSelected;
    _saveCartToLocal();
    notifyListeners();
  }

  void selectAllItems(bool selected) {
    for (var item in _cartItems) {
      item.isSelected = selected;
    }
    _saveCartToLocal();
    notifyListeners();
  }

  void clearSelectedItems() {
    _cartItems.removeWhere((item) => item.isSelected);
    _saveCartToLocal();
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _saveCartToLocal();
    notifyListeners();
  }

  // Wishlist operations
  void addToWishlist(Map<String, dynamic> product) {
    final existingIndex =
        _wishlistItems.indexWhere((item) => item.id == product['id']);
    if (existingIndex == -1) {
      _wishlistItems.add(CartItem(
        id: product['id'],
        imagePath: product['imageUrl'] ?? '',
        title: product['title'] ?? 'Untitled',
        price: (product['pricing'] as num? ?? 0).toDouble(),
        originalPrice: ((product['originalPrice'] as num?) ??
                (product['pricing'] as num? ?? 0))
            .toDouble(),
        category: product['category'] ?? '',
        sellerId: product['sellerId'] ?? '',
        availableStock: ((product['quantity'] as num?) ?? 0).toInt(),
        productData: product,
        quantity: 0, // Wishlist items don't have quantity
      ));
      _saveWishlistToLocal();
      notifyListeners();
    }
  }

  void removeFromWishlist(String id) {
    _wishlistItems.removeWhere((item) => item.id == id);
    _saveWishlistToLocal();
    notifyListeners();
  }

  Future<bool> moveWishlistToCart(String id) async {
    final wishlistItem = _wishlistItems.firstWhere((item) => item.id == id);
    final success = await addToCart(wishlistItem.productData);
    if (success) {
      removeFromWishlist(id);
    }
    return success;
  }

  // Coupon operations
  Future<bool> applyCoupon(String couponCode) async {
    try {
      final couponDoc = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(couponCode.toUpperCase())
          .get();

      if (couponDoc.exists) {
        final couponData = couponDoc.data()!;
        final isActive = couponData['isActive'] ?? false;
        final minAmount = couponData['minAmount']?.toDouble() ?? 0.0;
        final discountType = couponData['discountType'] ?? 'percentage';
        final discountValue = couponData['discountValue']?.toDouble() ?? 0.0;
        final expiryDate = couponData['expiryDate']?.toDate();

        if (!isActive ||
            (expiryDate != null && expiryDate.isBefore(DateTime.now()))) {
          return false; // Coupon expired or inactive
        }

        if (subtotal < minAmount) {
          return false; // Minimum amount not met
        }

        _appliedCouponCode = couponCode.toUpperCase();
        if (discountType == 'percentage') {
          _couponDiscount = (subtotal * discountValue / 100)
              .clamp(
                  0.0, couponData['maxDiscount']?.toDouble() ?? double.infinity)
              .toDouble();
        } else {
          _couponDiscount = discountValue.clamp(0, subtotal);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    notifyListeners();
  }

  // Shipping calculation
  void updateShippingCost(double cost) {
    _shippingCost = cost;
    notifyListeners();
  }

  // Local storage operations
  Future<void> _saveCartToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = _cartItems.map((item) => item.toJson()).toList();
      await prefs.setString('cart_items', jsonEncode(cartJson));
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveWishlistToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = _wishlistItems.map((item) => item.toJson()).toList();
      await prefs.setString('wishlist_items', jsonEncode(wishlistJson));
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> loadCartFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('cart_items');
      final wishlistString = prefs.getString('wishlist_items');

      if (cartString != null) {
        final cartJson = jsonDecode(cartString) as List;
        _cartItems.clear();
        _cartItems.addAll(cartJson.map((item) => CartItem.fromJson(item)));
      }

      if (wishlistString != null) {
        final wishlistJson = jsonDecode(wishlistString) as List;
        _wishlistItems.clear();
        _wishlistItems
            .addAll(wishlistJson.map((item) => CartItem.fromJson(item)));
      }

      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  // Stock validation
  Future<void> validateCartStock() async {
    // Early return if cart is empty
    if (_cartItems.isEmpty) return;

    bool hasChanges = false;

    for (int i = _cartItems.length - 1; i >= 0; i--) {
      // Check if index is still valid (list might have been modified)
      if (i >= _cartItems.length || i < 0) continue;

      final item = _cartItems[i];
      try {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(item.id)
            .get();

        if (!productDoc.exists) {
          _cartItems.removeAt(i);
          hasChanges = true;
          continue;
        }

        final currentStock = productDoc.data()!['quantity'] ?? 0;
        if (currentStock == 0) {
          _cartItems.removeAt(i);
          hasChanges = true;
          continue; // Skip updating since item was removed
        }

        // Only update item if it wasn't removed
        bool itemUpdated = false;
        if (item.quantity > currentStock) {
          item.quantity = currentStock;
          itemUpdated = true;
        }

        // Update available stock (only if item still exists in cart)
        if (i < _cartItems.length) {
          _cartItems[i] = CartItem(
            id: item.id,
            imagePath: item.imagePath,
            title: item.title,
            price: item.price,
            originalPrice: item.originalPrice,
            category: item.category,
            sellerId: item.sellerId,
            availableStock: currentStock,
            productData: item.productData,
            quantity: item.quantity,
            isSelected: item.isSelected,
            isDiscounted: item.isDiscounted,
            discountPercentage: item.discountPercentage,
          );
          if (itemUpdated) hasChanges = true;
        }
      } catch (e) {
        // If error, remove item (with bounds check)
        if (i < _cartItems.length) {
          _cartItems.removeAt(i);
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      await _saveCartToLocal();
      notifyListeners();
    }
  }
}
