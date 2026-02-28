import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Result of a bulk upload operation
class BulkUploadResult {
  final int totalRows;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  BulkUploadResult({
    required this.totalRows,
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });
}

/// Service handling CSV template generation and bulk product upload
class BulkUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── CSV Template columns ───────────────────────────────────────────
  static const List<String> templateHeaders = [
    'title',
    'category',
    'pricing',
    'quantity',
    'description',
    'certificate_url',
    'image_url_1',
    'image_url_2',
    'image_url_3',
    'weight_carats',
    'cut',
    'clarity',
    'color_grade',
    'origin',
    'treatment',
    'dimensions_mm',
    'delivery_methods',
    'payment_methods',
  ];

  // Human-friendly header descriptions (row 2 of the template)
  static const List<String> templateDescriptions = [
    'Product name (required)',
    'Blue Sapphires | White Sapphires | Yellow Sapphires (required)',
    'Price in LKR e.g. 25000 (required)',
    'Stock quantity e.g. 5 (required)',
    'Detailed product description (required)',
    'URL to gem certificate (optional)',
    'Primary image URL (required)',
    'Second image URL (optional)',
    'Third image URL (optional)',
    'Weight in carats e.g. 2.5 (optional)',
    'Cut type e.g. Oval, Round, Cushion, Pear, Emerald, Heart (optional)',
    'Clarity grade e.g. IF, VVS1, VVS2, VS1, VS2, SI1 (optional)',
    'Color grade e.g. AAA, AA, A, B (optional)',
    'Country of origin e.g. Sri Lanka (optional)',
    'Treatment e.g. Heated, Unheated, Diffusion (optional)',
    'Dimensions in mm e.g. 8.5x6.2x4.1 (optional)',
    'Pipe-separated method IDs from your config (optional)',
    'Pipe-separated method IDs from your config (optional)',
  ];

  // Example data row
  static const List<String> templateExample = [
    'Natural Blue Sapphire 2ct',
    'Blue Sapphires',
    '150000',
    '3',
    'A stunning natural blue sapphire from Sri Lanka with excellent clarity.',
    'https://example.com/cert123',
    'https://example.com/img1.jpg',
    'https://example.com/img2.jpg',
    '',
    '2.05',
    'Oval',
    'VVS1',
    'AAA',
    'Sri Lanka',
    'Unheated',
    '8.5x6.2x4.1',
    'standard_delivery|express_delivery',
    'bank_transfer|cash_on_delivery',
  ];

  // ─── Generate & share CSV template ──────────────────────────────────
  Future<File> generateCsvTemplate() async {
    final rows = <List<String>>[
      templateHeaders,
      templateDescriptions,
      templateExample,
    ];

    final csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/gemnest_bulk_upload_template.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);

    return file;
  }

  Future<void> shareTemplate() async {
    final file = await generateCsvTemplate();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'GemNest Bulk Upload Template',
    );
  }

  // ─── Pick & parse CSV file ──────────────────────────────────────────
  Future<List<List<dynamic>>?> pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final filePath = result.files.single.path;
    if (filePath == null) return null;

    final file = File(filePath);
    final csvString = await file.readAsString();
    final rows =
        const CsvToListConverter(eol: '\n').convert(csvString);

    return rows;
  }

  // ─── Validate a single product row ──────────────────────────────────
  String? _validateRow(Map<String, String> row, int rowIndex) {
    final errors = <String>[];

    if ((row['title'] ?? '').trim().isEmpty) {
      errors.add('title is required');
    }
    if ((row['category'] ?? '').trim().isEmpty) {
      errors.add('category is required');
    } else {
      final validCategories = [
        'Blue Sapphires',
        'White Sapphires',
        'Yellow Sapphires'
      ];
      if (!validCategories.contains(row['category']!.trim())) {
        errors.add(
            'category must be one of: ${validCategories.join(', ')}');
      }
    }
    if ((row['pricing'] ?? '').trim().isEmpty) {
      errors.add('pricing is required');
    } else if (double.tryParse(row['pricing']!.trim()) == null) {
      errors.add('pricing must be a valid number');
    }
    if ((row['quantity'] ?? '').trim().isEmpty) {
      errors.add('quantity is required');
    } else if (int.tryParse(row['quantity']!.trim()) == null) {
      errors.add('quantity must be a whole number');
    }
    if ((row['description'] ?? '').trim().isEmpty) {
      errors.add('description is required');
    }
    if ((row['image_url_1'] ?? '').trim().isEmpty) {
      errors.add('image_url_1 (primary image) is required');
    }

    // Validate optional numeric fields
    final weight = (row['weight_carats'] ?? '').trim();
    if (weight.isNotEmpty && double.tryParse(weight) == null) {
      errors.add('weight_carats must be a valid number');
    }

    if (errors.isEmpty) return null;
    return 'Row $rowIndex: ${errors.join('; ')}';
  }

  // ─── Build Firestore document from a parsed row ─────────────────────
  Map<String, dynamic> _buildProductData(
    Map<String, String> row,
    String userId,
    Map<String, Map<String, dynamic>> sellerDeliveryMethods,
    Map<String, Map<String, dynamic>> sellerPaymentMethods,
  ) {
    // Collect image URLs
    final imageUrls = <String>[];
    for (final key in ['image_url_1', 'image_url_2', 'image_url_3']) {
      final url = (row[key] ?? '').trim();
      if (url.isNotEmpty) imageUrls.add(url);
    }

    // Resolve delivery methods
    final deliveryMethodsData = <String, dynamic>{};
    final deliveryIds =
        (row['delivery_methods'] ?? '').split('|').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final id in deliveryIds) {
      if (sellerDeliveryMethods.containsKey(id)) {
        deliveryMethodsData[id] = sellerDeliveryMethods[id];
      }
    }
    // If none specified, use all available
    if (deliveryMethodsData.isEmpty && sellerDeliveryMethods.isNotEmpty) {
      deliveryMethodsData.addAll(sellerDeliveryMethods);
    }

    // Resolve payment methods
    final paymentMethodsData = <String, dynamic>{};
    final paymentIds =
        (row['payment_methods'] ?? '').split('|').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final id in paymentIds) {
      if (sellerPaymentMethods.containsKey(id)) {
        paymentMethodsData[id] = sellerPaymentMethods[id];
      }
    }
    if (paymentMethodsData.isEmpty && sellerPaymentMethods.isNotEmpty) {
      paymentMethodsData.addAll(sellerPaymentMethods);
    }

    return {
      'sellerId': userId,
      'title': row['title']!.trim(),
      'category': row['category']!.trim(),
      'pricing': double.parse(row['pricing']!.trim()),
      'quantity': int.parse(row['quantity']!.trim()),
      'description': row['description']!.trim(),
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
      'imageUrls': imageUrls,
      'gemCertificates': <Map<String, String>>[],
      'certificateUrl': (row['certificate_url'] ?? '').trim(),
      // New gem detail fields
      'weightCarats': (row['weight_carats'] ?? '').trim().isNotEmpty
          ? double.parse(row['weight_carats']!.trim())
          : null,
      'cut': (row['cut'] ?? '').trim().isNotEmpty ? row['cut']!.trim() : null,
      'clarity': (row['clarity'] ?? '').trim().isNotEmpty
          ? row['clarity']!.trim()
          : null,
      'colorGrade': (row['color_grade'] ?? '').trim().isNotEmpty
          ? row['color_grade']!.trim()
          : null,
      'origin': (row['origin'] ?? '').trim().isNotEmpty
          ? row['origin']!.trim()
          : null,
      'treatment': (row['treatment'] ?? '').trim().isNotEmpty
          ? row['treatment']!.trim()
          : null,
      'dimensionsMm': (row['dimensions_mm'] ?? '').trim().isNotEmpty
          ? row['dimensions_mm']!.trim()
          : null,
      'deliveryMethods': deliveryMethodsData,
      'paymentMethods': paymentMethodsData,
      'approvalStatus': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now().toIso8601String(),
      'uploadMethod': 'bulk_csv',
    };
  }

  // ─── Fetch seller's configured delivery & payment methods ───────────
  Future<Map<String, Map<String, dynamic>>> _loadSellerDeliveryMethods(
      String userId) async {
    final methods = <String, Map<String, dynamic>>{};
    try {
      final doc =
          await _firestore.collection('delivery_configs').doc(userId).get();
      if (doc.exists) {
        doc.data()!.forEach((key, value) {
          if (key != 'sellerId' && key != 'updatedAt' && value is Map) {
            final methodData = value as Map<String, dynamic>;
            if (methodData['enabled'] == true) {
              methods[key] = methodData;
            }
          }
        });
      }
    } catch (_) {}
    return methods;
  }

  Future<Map<String, Map<String, dynamic>>> _loadSellerPaymentMethods(
      String userId) async {
    final methods = <String, Map<String, dynamic>>{};
    try {
      final doc =
          await _firestore.collection('payment_configs').doc(userId).get();
      if (doc.exists) {
        doc.data()!.forEach((key, value) {
          if (key != 'sellerId' &&
              key != 'updatedAt' &&
              key != 'stripeAccountId' &&
              key != 'stripeOnboarded' &&
              value is Map) {
            final methodData = value as Map<String, dynamic>;
            if (methodData['enabled'] == true) {
              methods[key] = methodData;
            }
          }
        });
      }
    } catch (_) {}
    return methods;
  }

  // ─── Main bulk upload entry point ───────────────────────────────────
  Future<BulkUploadResult> processBulkUpload() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return BulkUploadResult(
        totalRows: 0,
        successCount: 0,
        failureCount: 0,
        errors: ['User not authenticated'],
      );
    }

    // 1. Pick CSV
    final rows = await pickCsvFile();
    if (rows == null || rows.isEmpty) {
      return BulkUploadResult(
        totalRows: 0,
        successCount: 0,
        failureCount: 0,
        errors: ['No file selected or file is empty'],
      );
    }

    // 2. Parse headers from the first row
    final headers =
        rows.first.map((h) => h.toString().trim().toLowerCase()).toList();

    // Skip description/example rows that start with known description text
    final dataRows = <List<dynamic>>[];
    for (int i = 1; i < rows.length; i++) {
      final firstCell = rows[i].isNotEmpty ? rows[i][0].toString().trim() : '';
      // Skip if it looks like a description/instruction row
      if (firstCell.toLowerCase().startsWith('product name') ||
          firstCell.toLowerCase().startsWith('natural blue sapphire') &&
              i <= 2) {
        continue;
      }
      // Skip empty rows
      if (rows[i].every(
          (cell) => cell == null || cell.toString().trim().isEmpty)) {
        continue;
      }
      dataRows.add(rows[i]);
    }

    if (dataRows.isEmpty) {
      return BulkUploadResult(
        totalRows: 0,
        successCount: 0,
        failureCount: 0,
        errors: ['No product data rows found in the CSV'],
      );
    }

    // 3. Load seller delivery & payment configs
    final sellerDelivery = await _loadSellerDeliveryMethods(userId);
    final sellerPayment = await _loadSellerPaymentMethods(userId);

    // 4. Process each data row
    int success = 0;
    int failure = 0;
    final errors = <String>[];

    for (int i = 0; i < dataRows.length; i++) {
      try {
        // Map row cells to header keys
        final rowMap = <String, String>{};
        for (int j = 0; j < headers.length && j < dataRows[i].length; j++) {
          rowMap[headers[j]] = dataRows[i][j].toString();
        }

        // Validate
        final validationError = _validateRow(rowMap, i + 1);
        if (validationError != null) {
          errors.add(validationError);
          failure++;
          continue;
        }

        // Build product data
        final productData = _buildProductData(
          rowMap,
          userId,
          sellerDelivery,
          sellerPayment,
        );

        // Write to Firestore
        await _firestore.collection('products').add(productData);
        success++;
      } catch (e) {
        errors.add('Row ${i + 1}: $e');
        failure++;
      }
    }

    return BulkUploadResult(
      totalRows: dataRows.length,
      successCount: success,
      failureCount: failure,
      errors: errors,
    );
  }
}
