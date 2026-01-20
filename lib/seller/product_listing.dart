import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:image_picker/image_picker.dart';

class ProductListing extends StatefulWidget {
  const ProductListing({super.key});

  @override
  State<ProductListing> createState() => _ProductListingState();
}

class _ProductListingState extends State<ProductListing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<File?> _images = List.filled(3, null);
  final List<File> _certificateFiles = [];
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _pricingController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  final bool _isBulkUploading = false;
  final bool _isDownloadingTemplate = false;
  bool _isDeliveryExpanded = false;
  bool _isPaymentExpanded = false;

  Map<String, Map<String, dynamic>> _availableDeliveryMethods = {};
  final Set<String> _selectedDeliveryMethods = {};

  Map<String, Map<String, dynamic>> _availablePaymentMethods = {};
  final Set<String> _selectedPaymentMethods = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> _loadDeliveryConfig() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc =
          await _firestore.collection('delivery_configs').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _availableDeliveryMethods = {};
          data.forEach((key, value) {
            if (key != 'sellerId' && key != 'updatedAt' && value is Map) {
              final methodData = value as Map<String, dynamic>;
              if (methodData['enabled'] == true) {
                _availableDeliveryMethods[key] = methodData;
              }
            }
          });
        });
      }
    } catch (e) {
      print('Error loading delivery config: $e');
    }
  }

  Future<void> _loadPaymentConfig() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc =
          await _firestore.collection('payment_configs').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _availablePaymentMethods = {};
          data.forEach((key, value) {
            if (key != 'sellerId' && key != 'updatedAt' && value is Map) {
              final methodData = value as Map<String, dynamic>;
              if (methodData['enabled'] == true) {
                _availablePaymentMethods[key] = methodData;
              }
            }
          });
        });
      }
    } catch (e) {
      print('Error loading payment config: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _pricingController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images[index] = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          for (var file in pickedFiles) {
            _certificateFiles.add(File(file.path));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error picking certificates: $e');
      }
    }
  }

  void _removeCertificate(int index) {
    setState(() {
      _certificateFiles.removeAt(index);
    });
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Product Listing'),
        content: const Text('Are you sure you want to list this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadProductToFirebase();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadProductToFirebase() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog('Please fill all required fields');
      return;
    }

    if (_images.first == null) {
      _showErrorDialog('Please upload at least one product image');
      return;
    }

    if (_certificateFiles.isEmpty) {
      _showErrorDialog('Please upload at least one gem certificate');
      return;
    }

    if (_selectedDeliveryMethods.isEmpty) {
      _showErrorDialog('Please select at least one delivery method');
      return;
    }

    if (_selectedPaymentMethods.isEmpty) {
      _showErrorDialog('Please select at least one payment method');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading product...'),
            ],
          ),
        ),
      );

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        Navigator.pop(context);
        _showErrorDialog('User not authenticated');
        return;
      }

      final storage = FirebaseStorage.instance;
      List<String> imageUrls = [];

      // Upload images
      for (int i = 0; i < _images.length; i++) {
        if (_images[i] != null) {
          final fileName =
              'products/$userId/${DateTime.now().millisecondsSinceEpoch}_image_$i.jpg';
          final uploadTask = await storage.ref(fileName).putFile(_images[i]!);
          final url = await uploadTask.ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      // Upload certificates with standardized naming
      List<Map<String, String>> certificateMetadata = [];
      for (int i = 0; i < _certificateFiles.length; i++) {
        final originalFileName = _certificateFiles[i].path.split('/').last;
        final fileExtension = originalFileName.contains('.')
            ? originalFileName.split('.').last
            : 'jpg';
        final standardFileName =
            '${_titleController.text.replaceAll(' ', '_')}_certificate_${i + 1}.$fileExtension';
        final fileName =
            'certificates/$userId/$standardFileName';
        final uploadTask =
            await storage.ref(fileName).putFile(_certificateFiles[i]);
        final url = await uploadTask.ref.getDownloadURL();
        certificateMetadata.add({
          'url': url,
          'fileName': standardFileName,
          'type': fileExtension.toLowerCase(),
        });
      }

      // Build full delivery method details with prices
      final deliveryMethodsData = <String, dynamic>{};
      for (final methodId in _selectedDeliveryMethods) {
        if (_availableDeliveryMethods.containsKey(methodId)) {
          deliveryMethodsData[methodId] = _availableDeliveryMethods[methodId];
        }
      }
      print('=== SELLER PRODUCT LISTING ===');
      print('Selected Delivery Methods: $_selectedDeliveryMethods');
      print('Available Delivery Methods: $_availableDeliveryMethods');
      print('Delivery Methods Data to Save: $deliveryMethodsData');

      // Build full payment method details
      final paymentMethodsData = <String, dynamic>{};
      for (final methodId in _selectedPaymentMethods) {
        if (_availablePaymentMethods.containsKey(methodId)) {
          paymentMethodsData[methodId] = _availablePaymentMethods[methodId];
        }
      }
      print('Selected Payment Methods: $_selectedPaymentMethods');
      print('Available Payment Methods: $_availablePaymentMethods');
      print('Payment Methods Data to Save: $paymentMethodsData');

      // Create product document
      final productData = {
        'sellerId': userId,
        'title': _titleController.text,
        'category': _selectedCategory,
        'pricing': double.parse(_pricingController.text),
        'quantity': int.parse(_quantityController.text),
        'description': _descriptionController.text,
        'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
        'imageUrls': imageUrls,
        'gemCertificates': certificateMetadata,
        'deliveryMethods': deliveryMethodsData,
        'paymentMethods': paymentMethodsData,
        'approvalStatus': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Add product to Firestore
      final docRef = await _firestore.collection('products').add(productData);

      Navigator.pop(context); // Close loading dialog
      _showSuccessDialog(
          message: 'Product listed successfully with ID: ${docRef.id}');

      // Clear form
      _formKey.currentState?.reset();
      _titleController.clear();
      _pricingController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      _selectedCategory = null;
      _certificateFiles.clear();
      _selectedDeliveryMethods.clear();
      _selectedPaymentMethods.clear();
      setState(() {
        _images.fillRange(0, 3, null);
      });
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Error uploading product: $e');
    }
  }

  void _handleBulkUpload() {
    _showErrorDialog('Bulk upload feature coming soon!');
  }

  Future<void> _downloadCsvTemplate() async {
    _showErrorDialog('CSV template download coming soon!');
  }

  void _showSuccessDialog({String? message}) {
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
        content: Text(
          message ?? 'Your product has been listed successfully!',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (message != null) {
                Navigator.pop(context);
              }
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
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
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
          'Product Listing',
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
                    'Photos (select first image to upload)',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          3,
                          (index) => GestureDetector(
                                onTap: () => _pickImage(index),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[900]!,
                                        Colors.grey[800]!
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.blue, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _images[index] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Image.file(
                                            _images[index]!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.camera_alt,
                                              color: Colors.white, size: 40),
                                        ),
                                ),
                              )),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInputField(
                    label: 'Title',
                    hint: 'Enter product title',
                    controller: _titleController,
                    validator: (value) =>
                        value!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    label: 'Category',
                    hint: 'Select category',
                    value: _selectedCategory,
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    validator: (value) =>
                        value == null ? 'Category is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Pricing',
                    hint: 'Enter price',
                    controller: _pricingController,
                    validator: (value) =>
                        value!.isEmpty ? 'Pricing is required' : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Product quantity',
                    hint: 'Enter quantity',
                    controller: _quantityController,
                    validator: (value) =>
                        value!.isEmpty ? 'Quantity is required' : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Description',
                    hint: 'Enter product description',
                    controller: _descriptionController,
                    validator: (value) =>
                        value!.isEmpty ? 'Description is required' : null,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  _buildCertificateSection(),
                  const SizedBox(height: 20),
                  _buildDeliveryMethodsSection(),
                  const SizedBox(height: 20),
                  _buildPaymentMethodsSection(),
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
                              'ALL DONE, SELL IT',
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
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: ElevatedButton(
                        onPressed: _isBulkUploading ? null : _handleBulkUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: Colors.green.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isBulkUploading
                                  ? 'UPLOADING...'
                                  : 'BULK PRODUCT LISTING',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            _isBulkUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file,
                                    size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: ElevatedButton(
                        onPressed: _isDownloadingTemplate
                            ? null
                            : _downloadCsvTemplate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: Colors.orange.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isDownloadingTemplate
                                  ? 'DOWNLOADING...'
                                  : 'DOWNLOAD CSV TEMPLATE',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            _isDownloadingTemplate
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download,
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

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
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
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: const [
            DropdownMenuItem(
                value: 'Blue Sapphires', child: Text('Blue Sapphires')),
            DropdownMenuItem(
                value: 'White Sapphires', child: Text('White Sapphires')),
            DropdownMenuItem(
                value: 'Yellow Sapphires', child: Text('Yellow Sapphires')),
          ],
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCertificateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gem Authorize Certification *Required',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickCertificate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purple, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _certificateFiles.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Certificates Selected',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_certificateFiles.length} certificate${_certificateFiles.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _certificateFiles.length,
                        itemBuilder: (context, index) {
                          final fileName =
                              _certificateFiles[index].path.split('/').last;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeCertificate(index),
                                  child: const Icon(Icons.close,
                                      color: Colors.red, size: 16),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickCertificate,
                        child: Text(
                          'Tap to add more certificates',
                          style: TextStyle(
                            color: Colors.blue.withOpacity(0.8),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.upload_file,
                          color: Colors.purple, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload Gem Certificate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF, JPG, PNG (Required)',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
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
