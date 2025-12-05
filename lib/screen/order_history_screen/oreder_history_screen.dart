// order_history_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/home_screen.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
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
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
      title: const Text(
        'My Orders',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      leading: ProfessionalAppBarBackButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        ),
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

    // Handle deliveryDate - could be String or Timestamp
    String deliveryDate = 'N/A';
    if (order['deliveryDate'] != null) {
      if (order['deliveryDate'] is String) {
        deliveryDate = order['deliveryDate'];
      } else if (order['deliveryDate'] is Timestamp) {
        deliveryDate = DateFormat('MMM dd, yyyy')
            .format((order['deliveryDate'] as Timestamp).toDate());
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
        paymentMethod = paymentMap['type'] ?? paymentMap['method'] ?? 'N/A';
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
                          onPressed: () => _reorderItems(items),
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
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8F9FA), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with drag handle and close button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Order title with status chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${orderId.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildModernStatusChip(order['status'] ?? 'Pending'),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Order Information', [
                        _buildDetailItem(
                            'Order Date', _formatDate(order['orderDate'])),
                        _buildDetailItem('Delivery Date',
                            _formatDate(order['deliveryDate'])),
                        _buildDetailItem('Status', order['status'] ?? 'N/A'),
                        _buildDetailItem('Payment Method',
                            _formatPaymentMethod(order['paymentMethod'])),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Delivery Information', [
                        _buildDetailItem('Name', order['name'] ?? 'N/A'),
                        _buildDetailItem('Mobile', order['mobile'] ?? 'N/A'),
                        _buildDetailItem('Email', order['email'] ?? 'N/A'),
                        _buildDetailItem(
                            'Address', _formatAddress(order['address'])),
                        _buildDetailItem(
                            'Delivery Note', order['deliveryNote'] ?? 'None'),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        'Items Ordered',
                        (order['items'] as List<dynamic>? ?? [])
                            .map((item) => _buildItemDetail(item))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF28a745).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF28a745).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              'Rs. ${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF28a745),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    IconData sectionIcon;
    Color sectionColor;
    
    switch (title) {
      case 'Order Information':
        sectionIcon = Icons.receipt_long;
        sectionColor = const Color(0xFF667eea);
        break;
      case 'Delivery Information':
        sectionIcon = Icons.local_shipping;
        sectionColor = const Color(0xFF28a745);
        break;
      case 'Items Ordered':
        sectionIcon = Icons.shopping_bag;
        sectionColor = const Color(0xFFf093fb);
        break;
      default:
        sectionIcon = Icons.info;
        sectionColor = const Color(0xFF667eea);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sectionColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                sectionIcon,
                color: sectionColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item['title'] ?? 'Unknown Item',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Qty: ${item['quantity'] ?? 1}',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Rs. ${item['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF28a745),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _reorderItems(List<dynamic> items) {
    // Show reorder confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reorder Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        content: Text(
          'Would you like to add these ${items.length} item(s) to your cart?',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Items added to cart!'),
                  backgroundColor: Color(0xFF28a745),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28a745),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add to Cart',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    if (dateValue is String) {
      return dateValue;
    } else if (dateValue is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(dateValue.toDate());
    }

    return 'N/A';
  }

  String _formatPaymentMethod(dynamic paymentValue) {
    if (paymentValue == null) return 'N/A';

    if (paymentValue is String) {
      return paymentValue;
    } else if (paymentValue is Map) {
      final paymentMap = paymentValue as Map<String, dynamic>;
      return paymentMap['type'] ?? paymentMap['method'] ?? 'N/A';
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
}
