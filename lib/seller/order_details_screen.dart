// order_details_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/widget/order_status_history_sheet.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedStatus;
  String? _previousStatus;
  final List<String> _statusOptions = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];
  late DocumentSnapshot orderData;

  @override
  void initState() {
    super.initState();
    _fetchOrderData();
  }

  Future<void> _fetchOrderData() async {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();
    setState(() {
      orderData = doc;
      // Convert Timestamp to String if needed
      dynamic deliveryDate = doc['deliveryDate'];
      if (deliveryDate is Timestamp) {
        _deliveryDateController.text =
            DateFormat('yyyy-MM-dd').format(deliveryDate.toDate());
      } else if (deliveryDate is String) {
        _deliveryDateController.text = deliveryDate;
      } else {
        _deliveryDateController.text =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
      _selectedStatus = doc['status'];
      _previousStatus = doc['status']; // Store initial status
    });
  }

  Future<void> _updateOrder() async {
    // If status changed, show comment dialog
    if (_selectedStatus != _previousStatus) {
      _showStatusChangeDialog();
    } else {
      // Just update delivery date
      await _performUpdate(null);
    }
  }

  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  const TextSpan(text: 'Status: '),
                  TextSpan(
                    text: '$_previousStatus → $_selectedStatus',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add a comment (optional):',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., Item shipped from warehouse',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              _performUpdate(_commentController.text);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _performUpdate(String? comment) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final now = DateTime.now();

      // Prepare update data
      Map<String, dynamic> updateData = {
        'deliveryDate': _deliveryDateController.text,
        'lastUpdated': DateFormat('yyyy-MM-dd HH:mm').format(now),
      };

      // If status changed, add status history entry
      if (_selectedStatus != _previousStatus) {
        updateData['status'] = _selectedStatus;

        // Create status change entry
        final statusChangeEntry = {
          'id': '${widget.orderId}_${now.millisecondsSinceEpoch}',
          'orderId': widget.orderId,
          'previousStatus': _previousStatus,
          'newStatus': _selectedStatus,
          'changedAt': Timestamp.fromDate(now),
          'comment': comment?.isEmpty ?? true ? null : comment,
          'changedBy': userId ?? 'unknown',
        };

        // Get existing status history
        final existingDoc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .get();

        // Safely get statusHistory field - use data() method to access fields
        final docData = existingDoc.data() ?? {};
        List<dynamic> statusHistory =
            (docData['statusHistory'] as List<dynamic>?) ?? [];
        statusHistory.add(statusChangeEntry);

        updateData['statusHistory'] = statusHistory;

        // Update previous status for next comparison
        _previousStatus = _selectedStatus;
        _commentController.clear();
      }

      // Perform update
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Order updated successfully',
                style: TextStyle(color: Colors.white))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update order: $e',
                style: const TextStyle(color: Colors.white))),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.parse(_deliveryDateController.text);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900]!,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        _deliveryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _showStatusHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderStatusHistorySheet(
        orderId: widget.orderId,
        currentStatus: _selectedStatus ?? 'N/A',
        orderNumber: widget.orderId.substring(0, 8).toUpperCase(),
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
              colors: [Colors.blueAccent, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        title: const Text(
          'Order Details',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: const ProfessionalAppBarBackButton(),
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
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('orders')
                .doc(widget.orderId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text('Error loading order details',
                        style: TextStyle(color: Colors.white)));
              }

              final order = snapshot.data!.data() as Map<String, dynamic>;
              final items = order['items'] as List<dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[850]!, Colors.grey[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.blue.withOpacity(0.3), width: 1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Order #${widget.orderId.substring(0, 8)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white)),
                                Chip(
                                  label: Text(
                                      _selectedStatus ?? order['status'],
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  backgroundColor: _getStatusColor(
                                      _selectedStatus ?? order['status']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.person, 'Customer:',
                                order['name'] ?? order['customerName']),
                            _buildInfoRow(
                                Icons.phone,
                                'Phone:',
                                order['mobile'] ??
                                    order['phone'] ??
                                    order['phoneNumber']),
                            _buildInfoRow(Icons.calendar_today, 'Order Date:',
                                order['orderDate']),
                            _buildEditableDateRow(
                                Icons.local_shipping, 'Delivery Date:'),
                            _buildInfoRow(Icons.location_on, 'Address:',
                                order['address'] ?? order['shippingAddress']),
                            _buildInfoRow(
                                Icons.payment,
                                'Payment Method:',
                                (order['paymentMethod'] is Map)
                                    ? (order['paymentMethod'] as Map)['name'] ??
                                        'Unknown'
                                    : order['paymentMethod'] ?? order['paymentType']),
                            _buildEditableStatusRow(Icons.update, 'Status:'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[850]!, Colors.grey[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.blue.withOpacity(0.3), width: 1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Items',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                            const SizedBox(height: 12),
                            ...items.map((item) {
                              final title = item['name'] ?? item['title'] ?? 'Unknown Item';
                              final quantity = item['quantity'] ?? 0;
                              final unitPrice = (item['price'] ?? item['totalPrice'] ?? 0.0) as num;
                              final price = (unitPrice * quantity).toDouble();
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white)),
                                          Text('Qty: $quantity',
                                              style: const TextStyle(
                                                  color: Colors.white60)),
                                        ],
                                      ),
                                    ),
                                    Text('Rs. ${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[850]!, Colors.grey[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.blue.withOpacity(0.3), width: 1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white)),
                            Text(
                                'Rs. ${order['totalAmount'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blueAccent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              onPressed: _updateOrder,
                              child: const Text('Save Changes',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.blueAccent, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _showStatusHistory,
                              icon: const Icon(Icons.history,
                                  color: Colors.blueAccent, size: 18),
                              label: const Text('History',
                                  style: TextStyle(
                                      color: Colors.blueAccent, fontSize: 14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    String displayValue = 'N/A';
    if (value != null) {
      if (value is Timestamp) {
        displayValue = DateFormat('yyyy-MM-dd').format(value.toDate());
      } else {
        displayValue = value.toString();
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text('$label ',
              style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Expanded(
            child: Text(displayValue,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDateRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text('$label ',
              style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _deliveryDateController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[850]!,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: Colors.blueAccent),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableStatusRow(IconData icon, String label) {
    // Build dropdown items, ensuring current status is included
    List<String> dropdownItems = List.from(_statusOptions);
    if (_selectedStatus != null && !dropdownItems.contains(_selectedStatus)) {
      dropdownItems.add(_selectedStatus!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text('$label ',
              style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850]!,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: Colors.grey[900]!,
              style: const TextStyle(color: Colors.white),
              items: dropdownItems.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStatus = newValue;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.yellow[900]!.withOpacity(0.8);
      case 'Processing':
        return Colors.blue[800]!.withOpacity(0.8);
      case 'Shipped':
        return Colors.purple[800]!.withOpacity(0.8);
      case 'Delivered':
        return Colors.green[800]!.withOpacity(0.8);
      case 'Cancelled':
        return Colors.red[800]!.withOpacity(0.8);
      default:
        return Colors.grey[800]!.withOpacity(0.8);
    }
  }

  @override
  void dispose() {
    _deliveryDateController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
