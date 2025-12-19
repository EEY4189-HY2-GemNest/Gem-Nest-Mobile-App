import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screen/category_screen/category_screen.dart';
class CategoryCard extends StatelessWidget {
  final String imagePath;
  final String title;
  const CategoryCard({super.key, required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to the CategoryScreen with the category title
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(categoryTitle: title),
          ),
        );
      },

