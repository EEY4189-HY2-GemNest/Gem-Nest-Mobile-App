import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screen/category_screen/category_card.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:gemnest_mobile_app/widget/no_data_widget.dart';
import 'package:gemnest_mobile_app/widget/shared_app_bar.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  // All available categories with their images and titles
  final List<Map<String, String>> allCategories = [
    {
      'imagePath': 'assets/images/category1.jpg',
      'title': 'Blue Sapphires',
    },
    {
      'imagePath': 'assets/images/category2.jpg',
      'title': 'White Sapphires',
    },
    {
      'imagePath': 'assets/images/category3.jpg',
      'title': 'Yellow Sapphires',
    },
    {
      'imagePath': 'assets/images/category1.jpg',
      'title': 'Pink Sapphires',
    },
    {
      'imagePath': 'assets/images/category2.jpg',
      'title': 'Rubies',
    },
    {
      'imagePath': 'assets/images/category3.jpg',
      'title': 'Emeralds',
    },
    {
      'imagePath': 'assets/images/category1.jpg',
      'title': 'Diamonds',
    },
    {
      'imagePath': 'assets/images/category2.jpg',
      'title': 'Pearls',
    },
    {
      'imagePath': 'assets/images/category3.jpg',
      'title': 'Amethysts',
    },
    {
      'imagePath': 'assets/images/category1.jpg',
      'title': 'Garnets',
    },
    {
      'imagePath': 'assets/images/category2.jpg',
      'title': 'Topaz',
    },
    {
      'imagePath': 'assets/images/category3.jpg',
      'title': 'Opals',
    },
  ];

  String _searchQuery = '';

  List<Map<String, String>> get filteredCategories {
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
                    '${filteredCategories.length} categories',
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
              child: filteredCategories.isEmpty
                  ? const NoDataWidget(
                      title: 'No categories found',
                      subtitle: 'Try searching with different keywords',
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
                          imagePath: category['imagePath']!,
                          title: category['title']!,
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
