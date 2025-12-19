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
        'lastUpdated': DateFormat('yyyy-MM-dd HH:mm')
            .format(DateTime.now()),
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
            // ===== Loading State =====
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              );
            }

            // ===== Error State =====
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

            // ===== Data Loaded =====
            final order =
                snapshot.data!.data() as Map<String, dynamic>;

            // UI content will be added in next commits
            return Center(
              child: Text(
                'Order data loaded successfully',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Text('Order #${widget.orderId.substring(0, 8)}'),
Chip(
  label: Text(_selectedStatus ?? order['status']),
  backgroundColor:
      _getStatusColor(_selectedStatus ?? order['status']),
),

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon),
      const SizedBox(width: 12),
      Text('$label $value'),
    ],
  );
}

Widget _buildEditableDateRow(IconData icon, String label) {
  return GestureDetector(
    onTap: () => _selectDate(context),
    child: TextField(
      controller: _deliveryDateController,
      enabled: false,
    ),
  );
}



  @override
  void dispose() {
    _deliveryDateController.dispose();
    super.dispose();
  }
}
