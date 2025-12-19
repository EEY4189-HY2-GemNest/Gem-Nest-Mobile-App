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
  final List<File> _certificateFiles = [];
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

  // Delivery methods state
  Map<String, Map<String, dynamic>> _availableDeliveryMethods = {};
  final Set<String> _selectedDeliveryMethods = {};
  bool _isLoadingDeliveryConfig = false;
  bool _isDeliveryExpanded = false;

  // Payment methods state
  Map<String, Map<String, dynamic>> _availablePaymentMethods = {};
  final Set<String> _selectedPaymentMethods = {};
  bool _isLoadingPaymentConfig = false;
  bool _isPaymentExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _loadDeliveryConfig();
    _loadPaymentConfig();
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

  Future<void> _pickCertificates() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _certificateFiles.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeCertificate(int index) {
    setState(() {
      _certificateFiles.removeAt(index);
    });
  }

  Future<List<Map<String, String>>?> _uploadCertificates() async {
    if (_certificateFiles.isEmpty) return null;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _showErrorDialog('User not authenticated');
        return null;
      }

      List<Map<String, String>> certificates = [];

      for (final certFile in _certificateFiles) {
        String fileName =
            'gem_certificates_auction/${DateTime.now().millisecondsSinceEpoch}_${certFile.path.split('/').last}';
        UploadTask uploadTask = _storage.ref(fileName).putFile(certFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        certificates.add({
          'url': downloadUrl,
          'fileName': certFile.path.split('/').last,
          'type': certFile.path.split('.').last,
          'uploadedAt': DateTime.now().toIso8601String(),
          'status': 'pending',
        });
      }

      return certificates;
    } catch (e) {
      _showErrorDialog('Error uploading certificates: $e');
      return null;
    }
  }

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
          // Format for display
          _endTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedEndTime!);
        });
      }
    }
  }

  Future<void> _saveAuctionToFirestore(
      String? imageUrl, List<Map<String, String>>? certificates) async {
    try {
      // Convert to ISO 8601 format for Firebase
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
        'gemCertificates': certificates ?? [],
        'certificateVerificationStatus':
            certificates != null && certificates.isNotEmpty
                ? 'pending'
                : 'none',
        'sellerId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showErrorDialog('Error saving auction: $e');
    }
  }

  void _showConfirmationDialog() {
    // Validate delivery methods selection
    if (_selectedDeliveryMethods.isEmpty &&
        _availableDeliveryMethods.isNotEmpty) {
      _showErrorDialog('Please select at least one delivery method.');
      return;
    }

    // Validate payment methods selection
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
                List<Map<String, String>>? certificates =
                    await _uploadCertificates();
                await _saveAuctionToFirestore(imageUrl, certificates);
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
                  const Text(
                    'Photo (First image will be displayed)',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[900]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Icon(Icons.camera_alt,
                                  color: Colors.white, size: 40),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInputField(
                    label: 'Title',
                    hint: 'Enter auction title',
                    controller: _titleController,
                    validator: (value) =>
                        value!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Current Bid',
                    hint: 'Enter current bid',
                    controller: _currentBidController,
                    validator: (value) =>
                        value!.isEmpty ? 'Current bid is required' : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Minimum Increment',
                    hint: 'Enter minimum increment',
                    controller: _minimumIncrementController,
                    validator: (value) =>
                        value!.isEmpty ? 'Minimum increment is required' : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Time',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _selectDateTime(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _endTimeController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[900],
                              hintText: 'Select date and time',
                              hintStyle: const TextStyle(
                                  color: Colors.white54, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 2),
                              ),
                              errorStyle: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                              suffixIcon: const Icon(Icons.calendar_today,
                                  color: Colors.blue),
                            ),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            validator: (value) =>
                                value!.isEmpty ? 'End time is required' : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDeliveryMethodsSection(),
                  const SizedBox(height: 20),
                  _buildPaymentMethodsSection(),
                  const SizedBox(height: 32),
                  _buildCertificateSection(),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: ElevatedButton(
                        onPressed: _showConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: Colors.blue.withOpacity(0.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ALL DONE',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle,
                                size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDeliveryMethodsSection() {
    if (_availableDeliveryMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Delivery Methods Configured',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Go to Delivery Config to set up delivery methods',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accepted Delivery Methods',
          style: TextStyle(
              color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDeliveryExpanded = !_isDeliveryExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Delivery Methods',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedDeliveryMethods.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${_selectedDeliveryMethods.length} method${_selectedDeliveryMethods.length > 1 ? 's' : ''} selected',
                                  style: TextStyle(
                                    color: Colors.blueAccent.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        _isDeliveryExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isDeliveryExpanded) ...[
                const Divider(color: Colors.white24, height: 0),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: _availableDeliveryMethods.entries.map((entry) {
                      final methodId = entry.key;
                      final methodData = entry.value;
                      final isSelected =
                          _selectedDeliveryMethods.contains(methodId);

                      return CheckboxListTile(
                        title: Text(
                          methodData['name'] ?? methodId,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          'LKR ${(methodData['price'] ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedDeliveryMethods.add(methodId);
                            } else {
                              _selectedDeliveryMethods.remove(methodId);
                            }
                          });
                        },
                        activeColor: Colors.blue,
                        checkColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_selectedDeliveryMethods.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one delivery method',
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection() {
    if (_availablePaymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Payment Methods Configured',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Go to Payment Config to set up payment methods',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accepted Payment Methods',
          style: TextStyle(
              color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPaymentExpanded = !_isPaymentExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Payment Methods',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedPaymentMethods.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${_selectedPaymentMethods.length} method${_selectedPaymentMethods.length > 1 ? 's' : ''} selected',
                                  style: TextStyle(
                                    color: Colors.blueAccent.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        _isPaymentExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isPaymentExpanded) ...[
                const Divider(color: Colors.white24, height: 0),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: _availablePaymentMethods.entries.map((entry) {
                      final methodId = entry.key;
                      final methodData = entry.value;
                      final isSelected =
                          _selectedPaymentMethods.contains(methodId);

                      return CheckboxListTile(
                        title: Text(
                          methodData['name'] ?? methodId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          methodData['description'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedPaymentMethods.add(methodId);
                            } else {
                              _selectedPaymentMethods.remove(methodId);
                            }
                          });
                        },
                        activeColor: Colors.blueAccent,
                        checkColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_selectedPaymentMethods.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one payment method',
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
