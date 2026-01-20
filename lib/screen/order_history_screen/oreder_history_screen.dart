// order_history_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/home_screen.dart';
import 'package:gemnest_mobile_app/widget/shared_app_bar.dart';
import 'package:gemnest_mobile_app/widget/shared_bottom_nav.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with TickerProviderStateMixin {
  String? _selectedStatusFilter;
  DateTimeRange? _selectedDateRange;
  String _selectedSortBy = 'date_desc';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Filter and sort options
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  final Map<String, String> _sortOptions = {
    'date_desc': 'Newest First',
    'date_asc': 'Oldest First',
    'amount_desc': 'Highest Amount',
    'amount_asc': 'Lowest Amount',
    'status': 'By Status',
  };

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = 'All';

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildFiltersSection(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                      ),
                    )
                  : _buildOrdersList(),
            ),
          ],
        ),
      ),
      floatingActionButton:
          SharedBottomNavigation.buildFloatingActionButton(context, 2),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const SharedBottomNavigation(currentIndex: 2),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return SharedAppBar(
      title: 'My Orders',
      onBackPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 26),
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            // Reset filters
            setState(() {
              _selectedStatusFilter = 'All';
              _selectedDateRange = null;
              _selectedSortBy = 'date_desc';
              _isLoading = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter & Sort Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusFilter(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSortDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateFilter(),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatusFilter = 'All';
                      _selectedDateRange = null;
                      _selectedSortBy = 'date_desc';
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatusFilter,
          isExpanded: true,
          hint: const Text('All Statuses'),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: _statusOptions.map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Row(
                children: [
                  _getStatusIcon(status),
                  const SizedBox(width: 8),
                  Text(status),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedStatusFilter = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSortBy,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: _sortOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedSortBy = value ?? 'date_desc';
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return GestureDetector(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          initialDateRange: _selectedDateRange,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF667eea),
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
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Color(0xFF667eea), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}'
                    : 'Select Date Range',
                style: TextStyle(
                  color: _selectedDateRange != null
                      ? Colors.black
                      : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildEmptyState(
        Icons.login,
        'Please log in to view your orders',
        'You need to be logged in to see your order history.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredOrdersStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            Icons.error,
            'Something went wrong',
            'Please try again later or contact support if the problem persists.',
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            Icons.shopping_bag_outlined,
            'No orders found',
            _selectedStatusFilter != 'All' || _selectedDateRange != null
                ? 'No orders match your current filters. Try adjusting your search criteria.'
                : 'You haven\'t placed any orders yet. Start shopping to see your orders here!',
          );
        }

        List<QueryDocumentSnapshot> orders = snapshot.data!.docs;
        orders = _applySorting(orders);

        return SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(seconds: 1));
            },
            color: const Color(0xFF667eea),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index].data() as Map<String, dynamic>;
                final orderId = orders[index].id;

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildOrderCard(order, orderId, index),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(
      Map<String, dynamic> order, String orderId, int index) {
    final status = order['status'] ?? 'Pending';

    // Handle orderDate - could be String or Timestamp
    String orderDate = 'N/A';
    if (order['orderDate'] != null) {
      if (order['orderDate'] is String) {
        orderDate = order['orderDate'];
      } else if (order['orderDate'] is Timestamp) {
        orderDate = DateFormat('MMM dd, yyyy')
            .format((order['orderDate'] as Timestamp).toDate());
      }
    }

    // Handle deliveryDate - could be String, DateTime or Timestamp
    String deliveryDate = 'N/A';
    if (order['deliveryDate'] != null) {
      if (order['deliveryDate'] is String) {
        deliveryDate = order['deliveryDate'];
      } else if (order['deliveryDate'] is Timestamp) {
        deliveryDate = DateFormat('MMM dd, yyyy')
            .format((order['deliveryDate'] as Timestamp).toDate());
      } else if (order['deliveryDate'] is DateTime) {
        deliveryDate = DateFormat('MMM dd, yyyy')
            .format(order['deliveryDate'] as DateTime);
      }
    }

    final totalAmount = order['totalAmount'] ?? 0.0;

    // Handle address - could be String or Map
    String address = 'N/A';
    if (order['address'] != null) {
      if (order['address'] is String) {
        address = order['address'];
      } else if (order['address'] is Map) {
        final addressMap = order['address'] as Map<String, dynamic>;
        address =
            '${addressMap['street'] ?? ''} ${addressMap['city'] ?? ''} ${addressMap['postalCode'] ?? ''}'
                .trim();
        if (address.isEmpty) address = 'N/A';
      }
    }

    // Handle paymentMethod - could be String or Map
    String paymentMethod = 'N/A';
    if (order['paymentMethod'] != null) {
      if (order['paymentMethod'] is String) {
        paymentMethod = order['paymentMethod'];
      } else if (order['paymentMethod'] is Map) {
        final paymentMap = order['paymentMethod'] as Map<String, dynamic>;
        // Try multiple field names for payment method
        String? methodName = paymentMap['name'];
        if (methodName == null || methodName.isEmpty) {
          methodName = paymentMap['type'] ?? paymentMap['method'] ?? paymentMap['id'];
        }
        if (methodName != null && methodName.isNotEmpty) {
          paymentMethod = methodName;
        }
      }
    }

    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${orderId.substring(0, 8)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed on $orderDate',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 16),

                // Order items summary
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items (${items.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...items.take(2).map((item) {
                          final itemMap = item as Map<String, dynamic>;
                          final quantity = itemMap['quantity'] ?? 1;
                          final title = itemMap['title'] ??
                              itemMap['name'] ??
                              'Unknown Item';
                          final totalPrice =
                              itemMap['totalPrice'] ?? itemMap['price'] ?? 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${quantity}x $title',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'Rs. ${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (items.length > 2)
                          Text(
                            'and ${items.length - 2} more item(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Order details
                _buildInfoRow(
                    Icons.local_shipping, 'Delivery Date', deliveryDate),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, 'Address', address,
                    maxLines: 2),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.payment, 'Payment Method', paymentMethod),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      'Rs. ${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF28a745),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showOrderDetails(order, orderId),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667eea),
                          side: const BorderSide(color: Color(0xFF667eea)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (status.toLowerCase() == 'delivered')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Items added to cart!'),
                                backgroundColor: Color(0xFF28a745),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reorder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28a745),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.pending;
        break;
      case 'processing':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.autorenew;
        break;
      case 'shipped':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF667eea),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String message) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: const Color(0xFF667eea),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (icon == Icons.shopping_bag_outlined)
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  ),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Start Shopping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return const Icon(Icons.all_inclusive,
            size: 18, color: Color(0xFF667eea));
      case 'pending':
        return Icon(Icons.pending, size: 18, color: Colors.orange.shade700);
      case 'processing':
        return Icon(Icons.autorenew, size: 18, color: Colors.blue.shade700);
      case 'shipped':
        return Icon(Icons.local_shipping,
            size: 18, color: Colors.purple.shade700);
      case 'delivered':
        return Icon(Icons.check_circle, size: 18, color: Colors.green.shade700);
      case 'cancelled':
        return Icon(Icons.cancel, size: 18, color: Colors.red.shade700);
      default:
        return Icon(Icons.help, size: 18, color: Colors.grey.shade700);
    }
  }

  Stream<QuerySnapshot> _getFilteredOrdersStream(String userId) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId);

    // Apply status filter
    if (_selectedStatusFilter != null && _selectedStatusFilter != 'All') {
      query = query.where('status', isEqualTo: _selectedStatusFilter);
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      final startDate =
          DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      final endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      query = query.where('orderDate', isGreaterThanOrEqualTo: startDate);
      query = query.where('orderDate', isLessThanOrEqualTo: endDate);
    }

    return query.snapshots();
  }

  List<QueryDocumentSnapshot> _applySorting(
      List<QueryDocumentSnapshot> orders) {
    switch (_selectedSortBy) {
      case 'date_desc':
        orders.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          DateTime? aDate, bDate;

          if (aData['orderDate'] is Timestamp) {
            aDate = (aData['orderDate'] as Timestamp).toDate();
          } else if (aData['orderDate'] is String) {
            try {
              aDate = DateTime.parse(aData['orderDate']);
            } catch (e) {
              aDate = DateTime.now();
            }
          } else {
            aDate = DateTime.now();
          }

          if (bData['orderDate'] is Timestamp) {
            bDate = (bData['orderDate'] as Timestamp).toDate();
          } else if (bData['orderDate'] is String) {
            try {
              bDate = DateTime.parse(bData['orderDate']);
            } catch (e) {
              bDate = DateTime.now();
            }
          } else {
            bDate = DateTime.now();
          }

          return bDate.compareTo(aDate);
        });
        break;
      case 'date_asc':
        orders.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          DateTime? aDate, bDate;

          if (aData['orderDate'] is Timestamp) {
            aDate = (aData['orderDate'] as Timestamp).toDate();
          } else if (aData['orderDate'] is String) {
            try {
              aDate = DateTime.parse(aData['orderDate']);
            } catch (e) {
              aDate = DateTime.now();
            }
          } else {
            aDate = DateTime.now();
          }

          if (bData['orderDate'] is Timestamp) {
            bDate = (bData['orderDate'] as Timestamp).toDate();
          } else if (bData['orderDate'] is String) {
            try {
              bDate = DateTime.parse(bData['orderDate']);
            } catch (e) {
              bDate = DateTime.now();
            }
          } else {
            bDate = DateTime.now();
          }

          return aDate.compareTo(bDate);
        });
        break;
      case 'amount_desc':
        orders.sort((a, b) {
          final aAmount =
              (a.data() as Map<String, dynamic>)['totalAmount'] ?? 0.0;
          final bAmount =
              (b.data() as Map<String, dynamic>)['totalAmount'] ?? 0.0;
          return bAmount.compareTo(aAmount);
        });
        break;
      case 'amount_asc':
        orders.sort((a, b) {
          final aAmount =
              (a.data() as Map<String, dynamic>)['totalAmount'] ?? 0.0;
          final bAmount =
              (b.data() as Map<String, dynamic>)['totalAmount'] ?? 0.0;
          return aAmount.compareTo(bAmount);
        });
        break;
      case 'status':
        orders.sort((a, b) {
          final aStatus = (a.data() as Map<String, dynamic>)['status'] ?? '';
          final bStatus = (b.data() as Map<String, dynamic>)['status'] ?? '';
          return aStatus.compareTo(bStatus);
        });
        break;
    }
    return orders;
  }

  void _showOrderDetails(Map<String, dynamic> order, String orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Minimal drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Compact header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${orderId.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(order['orderDate']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildModernStatusChip(order['status'] ?? 'Pending'),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick info cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickInfoCard(
                              icon: Icons.calendar_today,
                              label: 'Order Date',
                              value: _formatDate(order['orderDate']),
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickInfoCard(
                              icon: Icons.local_shipping,
                              label: 'Delivery',
                              value: _formatDate(order['deliveryDate']),
                              color: const Color(0xFF00BCD4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Customer info compact
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCompactInfoRow(
                              'Name:',
                              order['name'] ?? 'N/A',
                            ),
                            _buildCompactInfoRow(
                              'Mobile:',
                              order['mobile'] ?? 'N/A',
                            ),
                            _buildCompactInfoRow(
                              'Address:',
                              _formatAddress(order['address']),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Items section
                      if (order['items'] != null && (order['items'] as List).isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(order['items'] as List<dynamic>?)
                                      ?.asMap()
                                      .entries
                                      .map((e) {
                                    final isLast = e.key ==
                                        (order['items'] as List).length - 1;
                                    return _buildCompactInfoRow(
                                      '${e.value['title'] ?? 'Item'}:',
                                      'Qty: ${e.value['quantity'] ?? 1}',
                                      isLast: isLast,
                                    );
                                  }).toList() ??
                                  [],
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Payment info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCompactInfoRow(
                              'Method:',
                              _formatPaymentMethod(order['paymentMethod']),
                            ),
                            _buildCompactInfoRow(
                              'Status:',
                              order['status'] ?? 'N/A',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Total amount footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${order['totalAmount']?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1E88E5),
                            Color(0xFF1565C0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(
              height: 0,
              color: Colors.grey.shade300,
            ),
          )
        else
          const SizedBox(height: 0),
      ],
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    if (dateValue is String) {
      return dateValue;
    } else if (dateValue is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(dateValue.toDate());
    } else if (dateValue is DateTime) {
      return DateFormat('MMM dd, yyyy').format(dateValue);
    }

    return 'N/A';
  }

  String _formatPaymentMethod(dynamic paymentValue) {
    if (paymentValue == null) return 'N/A';

    if (paymentValue is String) {
      return paymentValue.isEmpty ? 'N/A' : paymentValue;
    } else if (paymentValue is Map) {
      final paymentMap = paymentValue as Map<String, dynamic>;
      // Try multiple field names for payment method
      String? methodName = paymentMap['name'];
      if (methodName == null || methodName.isEmpty) {
        methodName = paymentMap['type'] ?? paymentMap['method'] ?? paymentMap['id'];
      }
      return (methodName != null && methodName.isNotEmpty) ? methodName : 'N/A';
    }

    return 'N/A';
  }

  String _formatAddress(dynamic addressValue) {
    if (addressValue == null) return 'N/A';

    if (addressValue is String) {
      return addressValue;
    } else if (addressValue is Map) {
      final addressMap = addressValue as Map<String, dynamic>;
      final street = addressMap['street'] ?? '';
      final city = addressMap['city'] ?? '';
      final postalCode = addressMap['postalCode'] ?? '';
      final state = addressMap['state'] ?? '';

      final parts = [street, city, state, postalCode]
          .where((part) => part.toString().isNotEmpty)
          .toList();
      return parts.isNotEmpty ? parts.join(', ') : 'N/A';
    }

    return 'N/A';
  }

  Widget _buildModernStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'delivered':
        backgroundColor = const Color(0xFF28a745);
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'shipped':
      case 'in transit':
        backgroundColor = const Color(0xFF007bff);
        textColor = Colors.white;
        icon = Icons.local_shipping;
        break;
      case 'processing':
        backgroundColor = const Color(0xFFffc107);
        textColor = Colors.white;
        icon = Icons.hourglass_empty;
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFdc3545);
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        backgroundColor = const Color(0xFF6c757d);
        textColor = Colors.white;
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Order History Screen – Architectural & Design Notes
|--------------------------------------------------------------------------
|
| This screen is responsible for presenting a complete, user-centric view
| of a customer's historical orders. It combines Firestore real-time data,
| local UI state (filters, sorting, animations), and adaptive rendering
| logic to support inconsistent backend data formats.
|
| Key Responsibilities:
| ---------------------
| 1. Fetch user-specific orders from Firestore using FirebaseAuth UID.
| 2. Apply client-side filtering (status, date range) and sorting
|    (date, amount, status) without mutating backend data.
| 3. Handle multiple Firestore data representations gracefully:
|      - Dates may be stored as String or Timestamp
|      - Address and paymentMethod may be String or Map
|      - Items may vary in structure depending on order source
| 4. Provide a modern, responsive UI with animations, gradients,
|    and meaningful empty/error states.
|
| Data Handling Strategy:
| -----------------------
| Firestore queries are intentionally kept minimal (userId + optional
| status/date constraints). All complex sorting logic is applied on the
| client to avoid Firestore composite index overhead and to keep the
| UI flexible.
|
| Defensive parsing is used throughout the screen to prevent runtime
| crashes caused by:
|  - Legacy orders
|  - Partial documents
|  - Schema evolution over time
|
| UI/UX Considerations:
| --------------------
| - Status chips use consistent color semantics across the app
|   (green = success, red = cancelled, yellow = processing, etc.).
| - Animations (fade + slide) are subtle and purpose-driven to enhance
|   perceived performance rather than distract the user.
| - Empty states provide actionable guidance instead of dead ends.
| - Order cards prioritize scannability: ID, date, status, amount first.
|
| Extensibility Notes:
| -------------------
| - New order statuses can be added by updating:
|     _statusOptions
|     _getStatusIcon()
|     _buildStatusChip()
|     _buildModernStatusChip()
| - Pagination can be introduced later by replacing ListView.builder
|   with Firestore query cursors.
| - Reorder logic is currently UI-only and should be connected to
|   cart persistence in future iterations.
|
| Maintenance Guidance:
| ---------------------
| This file is intentionally verbose to keep business logic explicit
| and readable. Refactoring into smaller widgets or services should
| be done only when reuse or testability demands it.
|
|--------------------------------------------------------------------------
*/
