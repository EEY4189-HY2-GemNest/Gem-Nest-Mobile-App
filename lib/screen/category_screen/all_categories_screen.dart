import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screen/category_screen/category_card.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:gemnest_mobile_app/widget/no_data_widget.dart';
import 'package:gemnest_mobile_app/widget/shared_app_bar.dart';

class AllCategoriesScreen extends StatefulWidget {
  final String? selectedCategory;

  const AllCategoriesScreen({
    super.key,
    this.selectedCategory,
  });

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  String _searchQuery = '';
  List<Map<String, dynamic>> allCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      final List<Map<String, dynamic>> loadedCategories = [];
      for (var doc in categoriesSnapshot.docs) {
        try {
          final data = doc.data();
          loadedCategories.add({
            'id': doc.id,
            'imagePath': (data['categoryImage'] ?? '') as String,
            'title': (data['categoryName'] ?? 'Category') as String,
          });
        } catch (e) {
          debugPrint('Error processing category ${doc.id}: $e');
          continue;
        }
      }

      if (mounted) {
        setState(() {
          allCategories = loadedCategories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredCategories {
    if (_searchQuery.isEmpty) {
      return allCategories;
    }
    return allCategories
        .where((category) => category['title']!
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppBar(
        title: 'All Categories',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundColor, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.primaryBlue, size: 24),
                    hintText: 'Search categories...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 15,
                    ),
                  ),
                ),
              ),
            ),
            // Categories Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _isLoading
                        ? 'Loading categories...'
                        : '${filteredCategories.length} categories',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Categories Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : filteredCategories.isEmpty
                      ? const NoDataWidget(
                          title: 'No categories found',
                          subtitle:
                              'Try searching with different keywords or check back later',
                          icon: Icons.search_off,
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.95,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            return CategoryCard(
                              imagePath: category['imagePath'] ?? '',
                              title: category['title'] ?? 'Category',
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
