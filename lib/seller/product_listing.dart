import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  File? _certificateFile;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _pricingController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isBulkUploading = false;
  bool _isDownloadingTemplate = false;

  // Delivery methods
  Map<String, Map<String, dynamic>> _availableDeliveryMethods = {};
  final Set<String> _selectedDeliveryMethods = {};
  bool _isLoadingDeliveryConfig = true;
  bool _isDeliveryExpanded = false;

  // Payment methods
  Map<String, Map<String, dynamic>> _availablePaymentMethods = {};
  final Set<String> _selectedPaymentMethods = {};
  bool _isLoadingPaymentConfig = true;
  bool _isPaymentExpanded = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
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
    } finally {
      setState(() => _isLoadingDeliveryConfig = false);
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
    } finally {
      setState(() => _isLoadingPaymentConfig = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _pricingController.dispose();
    _unitController.dispose();
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _certificateFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking certificate: $e');
    }
  }

  Future<String?> _uploadFirstImage() async {
    if (_auth.currentUser == null) {
      _showErrorDialog('You must be signed in to upload images.');
      return null;
    }

    File? firstImage =
        _images.firstWhere((image) => image != null, orElse: () => null);

    if (firstImage == null) {
      _showErrorDialog('Please select at least one image.');
      return null;
    }

    String fileName =
        'product_images/${DateTime.now().millisecondsSinceEpoch}_${firstImage.path.split('/').last}';

    try {
      SettableMetadata metadata = SettableMetadata(
        cacheControl: 'public,max-age=31536000',
        contentType: 'image/jpeg',
      );

      UploadTask uploadTask =
          _storage.ref(fileName).putFile(firstImage, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Error uploading image: ${e.message}';
      if (e.code == 'permission-denied') {
        errorMessage =
            'Permission denied. Check your authentication status or storage rules.';
      }
      _showErrorDialog(errorMessage);
      return null;
    } catch (e) {
      _showErrorDialog('Unexpected error uploading image: $e');
      return null;
    }
  }

  Future<String?> _uploadCertificate() async {
    if (_auth.currentUser == null) {
      _showErrorDialog('You must be signed in to upload certificates.');
      return null;
    }

    if (_certificateFile == null) {
      // Certificate is optional, return empty string
      return '';
    }

    String fileExtension = _certificateFile!.path.split('.').last;
    String fileName =
        'gem_certificates/${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser!.uid}_certificate.$fileExtension';

    try {
      SettableMetadata metadata = SettableMetadata(
        cacheControl: 'public,max-age=31536000',
        contentType: fileExtension == 'pdf' ? 'application/pdf' : 'image/jpeg',
      );

      UploadTask uploadTask =
          _storage.ref(fileName).putFile(_certificateFile!, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Error uploading certificate: ${e.message}';
      if (e.code == 'permission-denied') {
        errorMessage =
            'Permission denied. Check your authentication status or storage rules.';
      }
      _showErrorDialog(errorMessage);
      return null;
    } catch (e) {
      _showErrorDialog('Unexpected error uploading certificate: $e');
      return null;
    }
  }

  Future<void> _saveProductToFirestore(String? imageUrl, String? certificateUrl) async {
    if (imageUrl == null) {
      _showErrorDialog('Image upload failed. Please try again.');
      return;
    }

    try {
      await _firestore.collection('products').add({
        'title': _titleController.text,
        'category': _selectedCategory,
        'pricing': double.tryParse(_pricingController.text) ?? 0.0,
        'unit': _unitController.text,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'gemCertificateUrl': certificateUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'sellerId': _auth.currentUser?.uid,
        'userId': _auth.currentUser?.uid,
        'deliveryMethods': _selectedDeliveryMethods.toList(),
        'paymentMethods': _selectedPaymentMethods.toList(),
      });
    } catch (e) {
      _showErrorDialog('Error saving product: $e');
    }
  }

  Future<void> _downloadCsvTemplate() async {
    try {
      setState(() => _isDownloadingTemplate = true);

      // Define the CSV headers
      List<List<dynamic>> csvData = [
        [
          'title',
          'category',
          'pricing',
          'quantity',
          'unit',
          'deliveryMethods',
          'description',
          'imageUrl',
          'gemCertificateUrl'
        ],
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get the temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/product_template.csv';
      final file = File(filePath);

      // Write the CSV string to the file
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles([XFile(filePath)],
          text: 'Product Listing CSV Template');
    } catch (e) {
      _showErrorDialog('Error generating CSV template: $e');
    } finally {
      setState(() => _isDownloadingTemplate = false);
    }
  }

  Future<void> _handleBulkUpload() async {
    try {
      setState(() => _isBulkUploading = true);

      // Check if the user is authenticated
      if (_auth.currentUser == null) {
        _showErrorDialog('You must be signed in to upload products.');
        return;
      }

      // Pick the CSV file
      FilePickerResult? csvResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (csvResult == null || csvResult.files.single.path == null) {
        _showErrorDialog('No CSV file selected.');
        setState(() => _isBulkUploading = false);
        return;
      }

      // Read the CSV file
      final csvFile = File(csvResult.files.single.path!);
      final input = await csvFile.readAsString();
      final List<List<dynamic>> csvData =
          const CsvToListConverter().convert(input);

      // Validate CSV headers
      if (csvData.isEmpty) {
        _showErrorDialog('CSV file is empty.');
        setState(() => _isBulkUploading = false);
        return;
      }

      List<String> expectedHeaders = [
        'title',
        'category',
        'pricing',
        'quantity',
        'unit',
        'deliveryMethods',
        'description',
        'imageUrl',
        'gemCertificateUrl'
      ];

      List<String> actualHeaders =
          csvData[0].map((e) => e.toString().trim()).toList();

      // Check number of columns
      if (actualHeaders.length != expectedHeaders.length) {
        _showErrorDialog(
            'Header mismatch: Expected ${expectedHeaders.length} columns but found ${actualHeaders.length} columns.\n\n'
            'Expected headers: ${expectedHeaders.join(", ")}\n'
            'Found headers: ${actualHeaders.join(", ")}');
        setState(() => _isBulkUploading = false);
        return;
      }

      // Check each header for an exact match
      StringBuffer headerErrors = StringBuffer();
      for (int i = 0; i < expectedHeaders.length; i++) {
        if (actualHeaders[i] != expectedHeaders[i]) {
          headerErrors.writeln(
              'Column ${i + 1}: Expected "${expectedHeaders[i]}", but found "${actualHeaders[i]}"');
        }
      }

      if (headerErrors.isNotEmpty) {
        _showErrorDialog(
            'Header mismatch detected:\n\n${headerErrors.toString()}\n\n'
            'Please ensure the CSV headers match exactly: ${expectedHeaders.join(", ")}');
        setState(() => _isBulkUploading = false);
        return;
      }

      // If headers are correct, proceed with data validation
      List<Map<String, dynamic>> products = [];
      StringBuffer errorMessages = StringBuffer();
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length != 8) {
          errorMessages.writeln(
              'Row ${i + 1}: Invalid number of columns. Expected 8, found ${row.length}');
          continue;
        }

        String title = row[0].toString().trim();
        String category = row[1].toString().trim();
        String pricingStr = row[2].toString().trim();
        String quantityStr = row[3].toString().trim();
        String unit = row[4].toString().trim();
        String deliveryMethodsStr = row[5].toString().trim();
        String description = row[6].toString().trim();
        String imageUrl = row[7].toString().trim();

        // Parse delivery methods (comma-separated)
        List<String> deliveryMethods = [];
        if (deliveryMethodsStr.isNotEmpty) {
          deliveryMethods = deliveryMethodsStr
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        // Validate each field
        bool hasErrors = false;
        if (title.isEmpty) {
          errorMessages.writeln('Row ${i + 1}: Title is empty');
          hasErrors = true;
        }
        if (category.isEmpty ||
            !['Blue Sapphires', 'White Sapphires', 'Yellow Sapphires']
                .contains(category)) {
          errorMessages.writeln(
              'Row ${i + 1}: Category is empty or invalid. Must be Blue Sapphires, White Sapphires, or Yellow Sapphires');
          hasErrors = true;
        }
        double? pricing = double.tryParse(pricingStr);
        if (pricingStr.isEmpty || pricing == null) {
          errorMessages.writeln('Row ${i + 1}: Pricing is empty or invalid');
          hasErrors = true;
        }
        int? quantity = int.tryParse(quantityStr);
        if (quantityStr.isEmpty || quantity == null) {
          errorMessages.writeln('Row ${i + 1}: Quantity is empty or invalid');
          hasErrors = true;
        }
        if (description.isEmpty) {
          errorMessages.writeln('Row ${i + 1}: Description is empty');
          hasErrors = true;
        }

        if (!hasErrors) {
          products.add({
            'title': title,
            'category': category,
            'pricing': pricing!,
            'quantity': quantity!,
            'unit': unit,
            'deliveryMethods': deliveryMethods,
            'description': description,
            'imageUrl': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': _auth.currentUser!.uid,
            'sellerId': _auth.currentUser!.uid,
          });
        }
      }

      if (products.isEmpty) {
        if (errorMessages.isNotEmpty) {
          _showErrorDialog(
              'Upload failed due to the following errors:\n${errorMessages.toString()}');
        } else {
          _showErrorDialog(
              'No valid products to upload. CSV file contains only headers or all rows are invalid.');
        }
        setState(() => _isBulkUploading = false);
        return;
      }

      // Batch write to Firestore
      WriteBatch batch = _firestore.batch();
      for (var product in products) {
        DocumentReference docRef = _firestore.collection('products').doc();
        batch.set(docRef, product);
      }

      await batch.commit();
      _showSuccessDialog(
          message: 'Successfully uploaded ${products.length} products');
    } catch (e) {
      _showErrorDialog('Error uploading bulk products: $e');
    } finally {
      setState(() => _isBulkUploading = false);
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
        _images.any((image) => image != null)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirm Listing',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to list this product?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                String? imageUrl = await _uploadFirstImage();
                if (imageUrl != null) {
                  await _saveProductToFirestore(imageUrl);
                  _showSuccessDialog();
                }
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
      _showErrorDialog('Please fill all fields and upload at least one photo.');
    }
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
              if (message == null) {
                Navigator.pop(
                  context,
                  {
                    'title': _titleController.text,
                    'quantity': int.tryParse(_quantityController.text) ?? 0,
                    'imagePath':
                        _images.firstWhere((image) => image != null)?.path,
                    'type': 'product',
                  },
                );
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
