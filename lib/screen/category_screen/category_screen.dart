import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screen/product_screen/product_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _searchQuery = '';
  String _sortOrder = 'asc';
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;

  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  void _fetchProducts() {
    _productsCollection
        .where('category', isEqualTo: widget.categoryTitle)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _products = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        _applyFilters();
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $error')),
      );
    });
  }  

  void _applyFilters() {
    setState(() {
      _filteredProducts = List.from(_products);

      if (_searchQuery.isNotEmpty) {
        _filteredProducts = _filteredProducts
            .where((product) => product['title']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }

      _filteredProducts.sort((a, b) {
        final aPrice = a['pricing'] as num? ?? 0;
        final bPrice = b['pricing'] as num? ?? 0;
        return _sortOrder == 'asc'
            ? aPrice.compareTo(bPrice)
            : bPrice.compareTo(aPrice);
      });
    });
  }  

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }