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
          'Order History',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: const ProfessionalAppBarBackButton(),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
            itemBuilder: (context) => _statusOptions
                .map((status) => PopupMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            _selectedStatus == status
                                ? Icons.check
                                : Icons.circle_outlined,
                            color: _selectedStatus == status
                                ? Colors.blue
                                : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(status),
                        ],
                      ),
                    ))
                .toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _isAscending = !_isAscending;
                } else {
                  _sortBy = value;
                  _isAscending = false;
                }
              });
            },
            itemBuilder: (context) => _sortOptions
                .map((sort) => PopupMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == sort
                                ? (_isAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward)
                                : Icons.sort,
                            color: _sortBy == sort ? Colors.blue : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(sort),
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () => _pickDateRange(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          // SELLER-SPECIFIC FILTERING - Only show current seller's orders
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
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getFilterStatusText(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                // Orders list
                Expanded(
                  child: orders.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 80, color: Colors.white54),
                              SizedBox(height: 16),
                              Text('No orders found',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 18)),
                              Text(
                                  'Orders will appear here when customers place them',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order =
                                orders[index].data() as Map<String, dynamic>;
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
                                        : [
                                            Colors.grey[850]!,
                                            Colors.grey[900]!
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isOverdue ? Colors.red : Colors.blue)
                                              .withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          (isOverdue ? Colors.red : Colors.blue)
                                              .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isOverdue
                                          ? Icons.warning
                                          : Icons.shopping_bag,
                                      color:
                                          isOverdue ? Colors.red : Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    'Order #${orderId.substring(0, 8)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        'Customer: ${order['customerName'] ?? 'N/A'}',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Amount: Rs. ${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                  order['status']),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              order['status'] ?? 'N/A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (isOverdue) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'OVERDUE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Delivery: ${order['deliveryDate'] ?? 'N/A'}',
                                        style: TextStyle(
                                          color: isOverdue
                                              ? Colors.red[300]
                                              : Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OrderDetailsScreen(
                                                orderId: orderId),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
