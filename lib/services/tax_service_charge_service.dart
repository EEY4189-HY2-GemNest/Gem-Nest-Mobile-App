import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch tax and service charge configuration from Firebase
/// Admin configures these values via the admin dashboard
class TaxServiceChargeService {
  static final TaxServiceChargeService _instance =
      TaxServiceChargeService._internal();
  factory TaxServiceChargeService() => _instance;
  TaxServiceChargeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cached values
  double _taxPercentage = 0.0;
  double _serviceChargePercentage = 0.0;
  double _codProcessingFee = 50.0;
  bool _isLoaded = false;

  double get taxPercentage => _taxPercentage;
  double get serviceChargePercentage => _serviceChargePercentage;
  double get codProcessingFee => _codProcessingFee;
  double get taxRate => _taxPercentage / 100.0;
  double get serviceChargeRate => _serviceChargePercentage / 100.0;
  bool get isLoaded => _isLoaded;

  /// Load tax and service charge config from Firebase
  Future<void> loadConfig() async {
    try {
      final doc = await _firestore
          .collection('platform_config')
          .doc('tax_service_charge')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _taxPercentage = (data['taxPercentage'] ?? 0.0).toDouble();
        _serviceChargePercentage =
            (data['serviceChargePercentage'] ?? 0.0).toDouble();
        _codProcessingFee = (data['codProcessingFee'] ?? 50.0).toDouble();
      } else {
        // Set defaults and create the document
        _taxPercentage = 18.0; // 18% GST default
        _serviceChargePercentage = 2.0; // 2% service charge default
        _codProcessingFee = 50.0;

        await _firestore
            .collection('platform_config')
            .doc('tax_service_charge')
            .set({
          'taxPercentage': _taxPercentage,
          'serviceChargePercentage': _serviceChargePercentage,
          'codProcessingFee': _codProcessingFee,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': 'system_default',
        });
      }
      _isLoaded = true;
    } catch (e) {
      print('Error loading tax config: $e');
      // Fallback defaults
      _taxPercentage = 18.0;
      _serviceChargePercentage = 2.0;
      _codProcessingFee = 50.0;
      _isLoaded = true;
    }
  }

  /// Force refresh config from Firebase
  Future<void> refreshConfig() async {
    _isLoaded = false;
    await loadConfig();
  }

  /// Calculate tax amount for a given subtotal
  double calculateTax(double subtotal) {
    return subtotal * taxRate;
  }

  /// Calculate service charge for a given subtotal
  double calculateServiceCharge(double subtotal) {
    return subtotal * serviceChargeRate;
  }

  /// Calculate total with tax and service charge
  double calculateTotal({
    required double subtotal,
    double discount = 0.0,
    double deliveryCharge = 0.0,
    double processingFee = 0.0,
  }) {
    final taxableAmount = subtotal - discount;
    final tax = calculateTax(taxableAmount);
    final serviceCharge = calculateServiceCharge(taxableAmount);
    return taxableAmount + tax + serviceCharge + deliveryCharge + processingFee;
  }

  /// Get breakdown map for order storage
  Map<String, dynamic> getBreakdown({
    required double subtotal,
    double discount = 0.0,
    double deliveryCharge = 0.0,
    double processingFee = 0.0,
  }) {
    final taxableAmount = subtotal - discount;
    final tax = calculateTax(taxableAmount);
    final serviceCharge = calculateServiceCharge(taxableAmount);
    final total =
        taxableAmount + tax + serviceCharge + deliveryCharge + processingFee;

    return {
      'subtotal': subtotal,
      'discount': discount,
      'taxableAmount': taxableAmount,
      'taxPercentage': _taxPercentage,
      'taxAmount': tax,
      'serviceChargePercentage': _serviceChargePercentage,
      'serviceChargeAmount': serviceCharge,
      'deliveryCharge': deliveryCharge,
      'processingFee': processingFee,
      'totalAmount': total,
    };
  }

  /// Listen to config changes (real-time)
  Stream<Map<String, dynamic>> configStream() {
    return _firestore
        .collection('platform_config')
        .doc('tax_service_charge')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _taxPercentage = (data['taxPercentage'] ?? 0.0).toDouble();
        _serviceChargePercentage =
            (data['serviceChargePercentage'] ?? 0.0).toDouble();
        _codProcessingFee = (data['codProcessingFee'] ?? 50.0).toDouble();
        _isLoaded = true;
        return data;
      }
      return {};
    });
  }
}
