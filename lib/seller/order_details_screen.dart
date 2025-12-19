// order_details_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  String? _selectedStatus;

  final List<String> _statusOptions = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  late DocumentSnapshot orderData;

  @override
  void initState() {
    super.initState();
    _fetchOrderData();
  }

  // ================= FETCH ORDER DATA =================
  Future<void> _fetchOrderData() async {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();

    setState(() {
      orderData = doc;
      _deliveryDateController.text = doc['deliveryDate'];
      _selectedStatus = doc['status'];
    });
  }

  // ================= UPDATE ORDER =================
  Future<void> _updateOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'deliveryDate': _deliveryDateController.text,
        'status': _selectedStatus,
        'lastUpdated':
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }

  // ================= DATE PICKER =================
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate =
        DateTime.parse(_deliveryDateController.text);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != initialDate) {
      setState(() {
        _deliveryDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: const ProfessionalAppBarBackButton(),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .get(),
          builder: (context, snapshot) {
            // ===== Loading =====
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              );
            }

            // ===== Error =====
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error loading order details',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // ===== No Data =====
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'Order not found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final order =
                snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= ORDER SUMMARY =================
                  Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${widget.orderId.substring(0, 8)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Order Date:',
                            order['orderDate'],
                          ),
                          _buildEditableDateRow(
                            Icons.local_shipping,
                            'Delivery Date:',
                          ),
                          _buildInfoRow(
                            Icons.location_on,
                            'Address:',
                            order['address'],
                          ),
                          _buildInfoRow(
                            Icons.payment,
                            'Payment:',
                            order['paymentMethod'],
                          ),
                          _buildEditableStatusRow(
                            Icons.update,
                            'Status:',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= INFO ROW =================
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label ',
            style: const TextStyle(color: Colors.white60),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ================= EDITABLE DATE =================
  Widget _buildEditableDateRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label ',
            style: const TextStyle(color: Colors.white60),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _deliveryDateController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= EDITABLE STATUS =================
  Widget _buildEditableStatusRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label ',
            style: const TextStyle(color: Colors.white60),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

final items = order['items'] as List<dynamic>;

...items.map((item) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(item['title']),
    Text('Qty: ${item['quantity']}'),
    Text('Rs. ${item['totalPrice']}'),
  ],
)),


  @override
  void dispose() {
    _deliveryDateController.dispose();
    super.dispose();
  }
}
