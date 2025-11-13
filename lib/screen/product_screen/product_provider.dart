import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Define a product model for easier handling
class Product {
  final String title;
  final double price;
  final String imagePath;

  Product({required this.title, required this.price, required this.imagePath});

  // Convert document from Firestore to Product
  factory Product.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Product(
      title: data['title'],
      price: data['price'],
      imagePath: data['imagePath'],
    );
  }
}
// Create the ProductProvider class
class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Product> _products = [];

  List<Product> get products => _products;
}
