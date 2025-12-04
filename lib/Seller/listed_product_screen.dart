import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ListedProductScreen extends StatefulWidget {
  const ListedProductScreen({super.key});

  @override
  _ListedProductScreenState createState() => _ListedProductScreenState();
}

class _ListedProductScreenState extends State<ListedProductScreen> {
  DateTimeRange? _selectedDateRange;

  // Method to pick date range
  Future<void> _pickDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ?? initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.grey,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }

  // Method to generate PDF report
  Future<Uint8List> _generatePdfReport(
      List<QueryDocumentSnapshot> products) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    double totalValueInRange = 0;
    double allTimeTotalValue = 0;

    // Calculate total value for products in the selected date range (if any)
    for (var product in products) {
      final data = product.data() as Map<String, dynamic>;
      final pricing = data['pricing'] is int
          ? (data['pricing'] as int).toDouble()
          : data['pricing'] as double;
      final quantity = data['quantity'] is int
          ? (data['quantity'] as int).toDouble()
          : data['quantity'] as double;
      totalValueInRange += pricing * quantity;
    }

    // Fetch all products for all-time total value
    
}
