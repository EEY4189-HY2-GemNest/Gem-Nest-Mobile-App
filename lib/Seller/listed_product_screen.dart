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
    final allProductsSnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    for (var product in allProductsSnapshot.docs) {
      final data = product.data();
      final pricing = data['pricing'] is int
          ? (data['pricing'] as int).toDouble()
          : data['pricing'] as double;
      final quantity = data['quantity'] is int
          ? (data['quantity'] as int).toDouble()
          : data['quantity'] as double;
      allTimeTotalValue += pricing * quantity;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Listed Products Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Date Range: ${_selectedDateRange != null ? '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}' : 'All Time'}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'Total Value (Selected Range): Rs. ${totalValueInRange.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'All-Time Total Value: Rs. ${allTimeTotalValue.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Product Details:',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Title', 'Category', 'Pricing', 'Quantity', 'Total'],
              data: products.map((product) {
                final data = product.data() as Map<String, dynamic>;
                final pricing = data['pricing'] is int
                    ? (data['pricing'] as int).toDouble()
                    : data['pricing'] as double;
                final quantity = data['quantity'] is int
                    ? (data['quantity'] as int).toDouble()
                    : data['quantity'] as double;
                return [
                  data['title'],
                  data['category'],
                  'Rs. ${pricing.toStringAsFixed(2)}',
                  quantity.toString(),
                  'Rs. ${(pricing * quantity).toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  