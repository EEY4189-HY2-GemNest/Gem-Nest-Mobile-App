import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/Seller/order_details_screen.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:intl/intl.dart';

class SellerOrderHistoryScreen extends StatefulWidget {
  const SellerOrderHistoryScreen({super.key});

  @override
  _SellerOrderHistoryScreenState createState() =>
      _SellerOrderHistoryScreenState();
}

class _SellerOrderHistoryScreenState extends State<SellerOrderHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedStatus = 'All';
  String _sortBy = 'Date';
  bool _isAscending = false;
  DateTimeRange? _selectedDateRange;

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];
  final List<String> _sortOptions = ['Date', 'Amount', 'Status'];

  // Helper method to check if order is overdue (NULL SAFE - FIXED)
  bool isOrderOverdue(Map<String, dynamic> order) {
    final deliveryDateStr = order['deliveryDate'];
    final status = order['status'];

    // NULL SAFETY CHECK - prevents the crash
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
  List<QueryDocumentSnapshot> _applyFilters(
      List<QueryDocumentSnapshot> orders) {
    return orders.where((order) {
      final data = order.data() as Map<String, dynamic>;

      // Date range filter
      if (_selectedDateRange != null) {
        try {
          final orderDate =
              DateTime.parse(data['deliveryDate']?.toString() ?? '');
          if (!(orderDate.isAfter(_selectedDateRange!.start
                  .subtract(const Duration(days: 1))) &&
              orderDate.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1))))) {
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
  List<QueryDocumentSnapshot> _applySorting(
      List<QueryDocumentSnapshot> orders) {
    orders.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      int comparison = 0;

      switch (_sortBy) {
        case 'Date':
          try {
            final dateA =
                DateTime.parse(dataA['deliveryDate']?.toString() ?? '');
            final dateB =
                DateTime.parse(dataB['deliveryDate']?.toString() ?? '');
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
      filters.add(
          'Date: ${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}');
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

    // Method to pick date range
  Future<void> _pickDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange ?? initialDateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

    Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

   Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Order History'),
  leading: const ProfessionalAppBarBackButton(),
  actions: [
    PopupMenuButton<String>(...),
    PopupMenuButton<String>(...),
    IconButton(
      icon: const Icon(Icons.date_range),
      onPressed: () => _pickDateRange(context),
    ),
  ],
  )
    )

}
StreamBuilder<QuerySnapshot>(
  stream: _auth.currentUser?.uid != null
      ? FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: _auth.currentUser!.uid)
          .snapshots()
      : const Stream.empty(),
)

var orders = snapshot.data!.docs;

orders = _applyFilters(orders);
orders = _applySorting(orders);

orders.isEmpty
  ? const Center(
      child: Column(
        children: [
          Icon(Icons.inbox_outlined),
          Text('No orders found'),
        ],
      ),
    )
