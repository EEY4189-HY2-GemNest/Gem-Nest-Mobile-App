import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screen/product_screen/product_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}
