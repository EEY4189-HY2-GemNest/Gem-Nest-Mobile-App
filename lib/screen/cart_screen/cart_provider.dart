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