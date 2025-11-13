import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;
  final String id;
  final Map<String, dynamic> product;

  const ProductCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
    required this.id,
    required this.product,
  });

  @override
Widget build(BuildContext context) {
  return Consumer<CartProvider>(
    builder: (context, cartProvider, child) {
      return const SizedBox();
    },
  );
}

}
