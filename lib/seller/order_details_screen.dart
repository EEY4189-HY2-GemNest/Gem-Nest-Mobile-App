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
    _deliveryDateController.text = doc['deliveryDate'];
    _selectedStatus = doc['status'];
  });
}
Future<void> _updateOrder() async {
  try {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
      'deliveryDate': _deliveryDateController.text,
      'status': _selectedStatus,
      'lastUpdated': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
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

}
