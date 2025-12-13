import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AuctionProduct extends StatefulWidget {
  const AuctionProduct({super.key});

  @override
  State<AuctionProduct> createState() => _AuctionProductState();
}

class _AuctionProductState extends State<AuctionProduct>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  File? _image;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _currentBidController = TextEditingController();
  final TextEditingController _minimumIncrementController =
      TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime? _selectedEndTime;

  // Add to state variables
  Map<String, Map<String, dynamic>> _availableDeliveryMethods = {};
  final Set<String> _selectedDeliveryMethods = {};
  bool _isLoadingDeliveryConfig = false;
  bool _isDeliveryExpanded = false;

  // Add to state variables
  Map<String, Map<String, dynamic>> _availablePaymentMethods = {};
  final Set<String> _selectedPaymentMethods = {};
  bool _isLoadingPaymentConfig = false;
  bool _isPaymentExpanded = false;

  // Add to initState
  _loadPaymentConfig();

  Future<void> _loadPaymentConfig() async {
    setState(() => _isLoadingPaymentConfig = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc =
          await _firestore.collection('payment_configs').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final enabledMethods = <String, Map<String, dynamic>>{};

        data.forEach((key, value) {
          if (key != 'sellerId' && key != 'updatedAt') {
            final methodData = value as Map<String, dynamic>;
            if (methodData['enabled'] == true) {
              enabledMethods[key] = methodData;
            }
          }
        });

        setState(() {
          _availablePaymentMethods = enabledMethods;
        });
      }
    } catch (e) {
      print('Error loading payment config: $e');
    } finally {
      setState(() => _isLoadingPaymentConfig = false);
    }
  }

  // Add to initState
  _loadDeliveryConfig();

  Future<void> _loadDeliveryConfig() async {
    setState(() => _isLoadingDeliveryConfig = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc =
          await _firestore.collection('delivery_configs').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final enabledMethods = <String, Map<String, dynamic>>{};

        data.forEach((key, value) {
          if (key != 'sellerId' && key != 'updatedAt') {
            final methodData = value as Map<String, dynamic>;
            if (methodData['enabled'] == true) {
              enabledMethods[key] = methodData;
            }
          }
        });

        setState(() {
          _availableDeliveryMethods = enabledMethods;
        });
      }
    } catch (e) {
      print('Error loading delivery config: $e');
    } finally {
      setState(() => _isLoadingDeliveryConfig = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _currentBidController.dispose();
    _minimumIncrementController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_image != null) {
      String fileName =
          'auction_images/${DateTime.now().millisecondsSinceEpoch}_${_image!.path.split('/').last}';
      UploadTask uploadTask = _storage.ref(fileName).putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    }
    return null;
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedEndTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _endTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedEndTime!);
        });
      }
    }
  }

  Future<void> _saveAuctionToFirestore(String? imageUrl) async {
    try {
      String endTimeIso = _selectedEndTime != null
          ? _selectedEndTime!.toUtc().toIso8601String()
          : DateTime.now().toUtc().toIso8601String();

      final userId = _auth.currentUser?.uid;
      await _firestore.collection('auctions').add({
        'title': _titleController.text,
        'currentBid': double.tryParse(_currentBidController.text) ?? 0.0,
        'endTime': endTimeIso,
        'imagePath': imageUrl,
        'lastBidTime': FieldValue.serverTimestamp(),
        'minimumIncrement':
            double.tryParse(_minimumIncrementController.text) ?? 0.0,
        'paymentInitiatedAt': null,
        'paymentStatus': 'pending',
        'winningUserId': null,
        'deliveryMethods': _selectedDeliveryMethods.toList(),
        'paymentMethods': _selectedPaymentMethods.toList(),
        'sellerId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showErrorDialog('Error saving auction: $e');
    }
  }

  void _showConfirmationDialog() {
    if (_selectedDeliveryMethods.isEmpty &&
        _availableDeliveryMethods.isNotEmpty) {
      _showErrorDialog('Please select at least one delivery method.');
      return;
    }

    if (_selectedPaymentMethods.isEmpty &&
        _availablePaymentMethods.isNotEmpty) {
      _showErrorDialog('Please select at least one payment method.');
      return;
    }

    if (_formKey.currentState!.validate() &&
        _image != null &&
        _selectedEndTime != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirm Auction',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to start this auction?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                String? imageUrl = await _uploadImage();
                await _saveAuctionToFirestore(imageUrl);
                _showSuccessDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      _showErrorDialog(
          'Please fill all fields, upload an image, and select an end time.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Success!',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your auction has been created successfully!',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'title': _titleController.text,
                'imagePath': _image?.path,
                'type': 'auction',
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Error',
          style: TextStyle(
              color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
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
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        title: const Text(
          'Auction Product',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: const ProfessionalAppBarBackButton(),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Content will be added in next commits
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
