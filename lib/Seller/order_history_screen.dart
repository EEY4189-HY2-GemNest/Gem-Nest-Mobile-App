import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gemnest_mobile_app/Seller/order_details_screen.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SellerOrderHistoryScreen extends StatefulWidget {
  const SellerOrderHistoryScreen({super.key});

  @override
  _SellerOrderHistoryScreenState createState() =>
      _SellerOrderHistoryScreenState();
}

class _SellerOrderHistoryScreenState extends State<SellerOrderHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTimeRange? _selectedDateRange;
  String _selectedStatus = 'All';
  final String _sortBy = 'Date';
  final bool _isAscending = false;
  
  final List<String> _statusOptions = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
  final List<String> _sortOptions = ['Date', 'Amount', 'Status'];

  // Helper method to check if order is overdue
  bool isOrderOverdue(Map<String, dynamic> order) {
    final deliveryDateStr = order['deliveryDate'];
    final status = order['status'];

    if (deliveryDateStr == null || status == null) {
      return false;
    }

    try {
      final deliveryDate = DateTime.parse(deliveryDateStr.toString());
      final currentDate = DateTime.now();
      return currentDate.isAfter(deliveryDate) &&
          status.toString().toLowerCase() != 'delivered';
    } catch (e) {
      return false;
    }
  }

  // Apply filters to orders
  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> orders) {
    return orders.where((order) {
      final data = order.data() as Map<String, dynamic>;
      
      // Date range filter
      if (_selectedDateRange != null) {
        try {
          final orderDate = DateTime.parse(data['deliveryDate']?.toString() ?? '');
          if (!(orderDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                orderDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))))) {
            return false;
          }
        } catch (e) {
          return false;
        }
      }
      
      // Status filter
      if (_selectedStatus != 'All') {
        final status = data['status']?.toString() ?? '';
        if (status.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  // Apply sorting to orders
  List<QueryDocumentSnapshot> _applySorting(List<QueryDocumentSnapshot> orders) {
    orders.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      
      int comparison = 0;
      
      switch (_sortBy) {
        case 'Date':
          try {
            final dateA = DateTime.parse(dataA['deliveryDate']?.toString() ?? '');
            final dateB = DateTime.parse(dataB['deliveryDate']?.toString() ?? '');
            comparison = dateA.compareTo(dateB);
          } catch (e) {
            comparison = 0;
          }
          break;
        case 'Amount':
          final amountA = (dataA['totalAmount'] ?? 0).toDouble();
          final amountB = (dataB['totalAmount'] ?? 0).toDouble();
          comparison = amountA.compareTo(amountB);
          break;
        case 'Status':
          final statusA = dataA['status']?.toString() ?? '';
          final statusB = dataB['status']?.toString() ?? '';
          comparison = statusA.compareTo(statusB);
          break;
      }
      
      return _isAscending ? comparison : -comparison;
    });
    
    return orders;
  }

  String _getFilterStatusText() {
    List<String> filters = [];
    if (_selectedDateRange != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      filters.add('Date: ${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}');
    }
    if (_selectedStatus != 'All') {
      filters.add('Status: $_selectedStatus');
    }
    return 'Filters: ${filters.join(', ')}';
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedStatus = 'All';
    });
  }

  // Apply filters to orders
  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> orders) {
    return orders.where((order) {
      final data = order.data() as Map<String, dynamic>;
      
      // Date range filter
      if (_selectedDateRange != null) {
        try {
          final orderDate = DateTime.parse(data['deliveryDate']?.toString() ?? '');
          if (!(orderDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                orderDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))))) {
            return false;
          }
        } catch (e) {
          return false;
        }
      }
      
      // Status filter
      if (_selectedStatus != 'All') {
        final status = data['status']?.toString() ?? '';
        if (status.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  // Apply sorting to orders
  List<QueryDocumentSnapshot> _applySorting(List<QueryDocumentSnapshot> orders) {
    orders.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      
      int comparison = 0;
      
      switch (_sortBy) {
        case 'Date':
          try {
            final dateA = DateTime.parse(dataA['deliveryDate']?.toString() ?? '');
            final dateB = DateTime.parse(dataB['deliveryDate']?.toString() ?? '');
            comparison = dateA.compareTo(dateB);
          } catch (e) {
            comparison = 0;
          }
          break;
        case 'Amount':
          final amountA = (dataA['totalAmount'] ?? 0).toDouble();
          final amountB = (dataB['totalAmount'] ?? 0).toDouble();
          comparison = amountA.compareTo(amountB);
          break;
        case 'Status':
          final statusA = dataA['status']?.toString() ?? '';
          final statusB = dataB['status']?.toString() ?? '';
          comparison = statusA.compareTo(statusB);
          break;
      }
      
      return _isAscending ? comparison : -comparison;
    });
    
    return orders;
  }

  // Method to generate PDF report
  Future<Uint8List> _generatePdfReport(
      List<QueryDocumentSnapshot> orders) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    double totalIncome = 0;

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final amount = data['totalAmount'];
      totalIncome += (amount is int ? amount.toDouble() : amount as double);
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Order History Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Date Range: ${dateFormat.format(_selectedDateRange?.start ?? DateTime.now())} - ${dateFormat.format(_selectedDateRange?.end ?? DateTime.now())}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'Total Income: Rs. ${totalIncome.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Order ID', 'Status', 'Total Amount', 'Delivery Date'],
              data: orders.map((order) {
                final data = order.data() as Map<String, dynamic>;
                return [
                  order.id.substring(0, 8),
                  data['status'],
                  'Rs. ${(data['totalAmount'] is int ? (data['totalAmount'] as int).toDouble() : data['totalAmount'] as double).toStringAsFixed(2)}',
                  data['deliveryDate'],
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
        'Order_History_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  // Method to show improved save/share dialog
  Future<void> _showSaveOrShareDialog(
      List<QueryDocumentSnapshot> orders) async {
    final pdfBytes = await _generatePdfReport(orders);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey[900], // Dark background to match app theme
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text(
              'Download Report',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an option to proceed with your order history report:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              'Orders: ${orders.length}',
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
              Fluttertoast.showToast(
                msg: 'Saved to $filePath',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.green.withOpacity(0.9),
                textColor: Colors.white,
                fontSize: 16.0,
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white, // Set text and icon color to white
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
                    'Order_History_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
              );
              Fluttertoast.showToast(
                msg: 'Sharing report...',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.blueAccent.withOpacity(0.9),
                textColor: Colors.white,
                fontSize: 16.0,
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white, // Set text and icon color to white
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        title: const Text(
          'Order History',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: const ProfessionalAppBarBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () => _pickDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () async {
              final currentUserId = _auth.currentUser?.uid;
              if (currentUserId == null) return;
              
              final snapshot = await FirebaseFirestore.instance
                  .collection('orders')
                  .where('sellerId', isEqualTo: currentUserId)
                  .get();
              await _showSaveOrShareDialog(snapshot.docs);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _auth.currentUser?.uid != null 
              ? FirebaseFirestore.instance
                  .collection('orders')
                  .where('sellerId', isEqualTo: _auth.currentUser!.uid)
                  .snapshots()
              : const Stream.empty(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text('Error loading orders',
                        style: TextStyle(color: Colors.white)));
              }

              var orders = snapshot.data!.docs;
              
              // Apply filters
              orders = _applyFilters(orders);
              
              // Apply sorting
              orders = _applySorting(orders);

              return Column(
                children: [
                  // Filter status display
                  if (_selectedDateRange != null || _selectedStatus != 'All')
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getFilterStatusText(),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                    ),
                  // Orders list
                  Expanded(
                    child: _buildOrdersList(orders),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _getFilterStatusText() {
    List<String> filters = [];
    if (_selectedDateRange != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      filters.add('Date: ${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}');
    }
    if (_selectedStatus != 'All') {
      filters.add('Status: $_selectedStatus');
    }
    return 'Filters: ${filters.join(', ')}';
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedStatus = 'All';
    });
  }

  Widget _buildOrdersList(List<QueryDocumentSnapshot> orders) {

    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text('No orders found',
                style:
                    TextStyle(color: Colors.white70, fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
return null;
                  final order = orders[index].data() as Map<String, dynamic>;
                  final orderId = orders[index].id;
                  final isOverdue = isOrderOverdue(order);

                  return Card(
                    elevation: 4,
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOverdue
                              ? [Colors.red[800]!, Colors.red[900]!]
                              : [Colors.grey[850]!, Colors.grey[900]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOverdue
                              ? Colors.red.withOpacity(0.5)
                              : Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text('Order #${orderId.substring(0, 8)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Status: ${order['status']}',
                                style: const TextStyle(color: Colors.white60)),
                            Text(
                                'Total: Rs. ${order['totalAmount'].toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white60)),
                            Text('Delivery: ${order['deliveryDate']}',
                                style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: isOverdue ? Colors.white : Colors.blueAccent,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailsScreen(orderId: orderId),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
