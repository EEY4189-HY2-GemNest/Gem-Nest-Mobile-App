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
}
