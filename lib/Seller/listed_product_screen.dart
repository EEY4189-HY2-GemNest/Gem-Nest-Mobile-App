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

  // Method to save PDF to internal storage
  Future<String> _savePdfToStorage(Uint8List pdfBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'Product_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  // Method to show save/share dialog
  Future<void> _showSaveOrShareDialog(
      List<QueryDocumentSnapshot> products) async {
    final pdfBytes = await _generatePdfReport(products);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text(
              'Download Product Report',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an option to proceed with your product report:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              'Products in Range: ${products.length}',
              style: const TextStyle(color: Colors.white60),
            ),
            if (_selectedDateRange != null)
              Text(
                'Date Range: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}',
                style: const TextStyle(color: Colors.white60),
              ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              final filePath = await _savePdfToStorage(pdfBytes);
              if (Platform.isAndroid || Platform.isIOS) {
                try {
                  Fluttertoast.showToast(
                    msg: 'Saved to $filePath',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.green.withOpacity(0.9),
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                } catch (e) {
                  print('Toast error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to $filePath')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved to $filePath')),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename:
                    'Product_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
              );
              if (Platform.isAndroid || Platform.isIOS) {
                try {
                  Fluttertoast.showToast(
                    msg: 'Sharing report...',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.blueAccent.withOpacity(0.9),
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                } catch (e) {
                  print('Toast error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing report...')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing report...')),
                );
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        title: const Text(
          'Listed Products',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () => _pickDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('timestamp', descending: true)
                  .get();
              var filteredProducts = snapshot.docs;
              if (_selectedDateRange != null) {
                filteredProducts = filteredProducts.where((product) {
                  final data = product.data();
                  final timestamp = (data['timestamp'] as Timestamp).toDate();
                  return timestamp.isAfter(_selectedDateRange!.start) &&
                      timestamp.isBefore(
                          _selectedDateRange!.end.add(const Duration(days: 1)));
                }).toList();
              }
              await _showSaveOrShareDialog(filteredProducts);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: Colors.blue, strokeWidth: 3));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: Colors.white70, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'No products listed yet',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            var products = snapshot.data!.docs;
            if (_selectedDateRange != null) {
              products = products.where((product) {
                final data = product.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp).toDate();
                return timestamp.isAfter(_selectedDateRange!.start) &&
                    timestamp.isBefore(
                        _selectedDateRange!.end.add(const Duration(days: 1)));
              }).toList();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                return ProductCard(
                  docId: product.id,
                  title: product['title'],
                  pricing: product['pricing'].toString(),
                  quantity: product['quantity'].toString(),
                  imageUrl: product['imageUrl'],
                  category: product['category'],
                  description: product['description'],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

