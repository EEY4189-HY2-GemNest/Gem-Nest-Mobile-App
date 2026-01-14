import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to manage seller payment configurations from Firebase
class PaymentConfigHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch seller's payment configuration
  static Future<Map<String, dynamic>?> getSellerPaymentConfig(String sellerId) async {
    try {
      final doc = await _firestore
          .collection('payment_configs')
          .doc(sellerId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error fetching payment config: $e');
      return null;
    }
  }

  /// Get enabled payment methods for a seller
  static Future<List<String>> getEnabledPaymentMethods(String sellerId) async {
    try {
      final config = await getSellerPaymentConfig(sellerId);
      if (config == null) return ['card', 'cod'];

      final enabledMethods = <String>[];
      for (var method in ['card', 'cod', 'bank_transfer']) {
        if (config[method]?['enabled'] == true) {
          enabledMethods.add(method);
        }
      }

      return enabledMethods.isEmpty ? ['card', 'cod'] : enabledMethods;
    } catch (e) {
      return ['card', 'cod'];
    }
  }

  /// Get bank transfer details for a seller
  static Future<Map<String, dynamic>?> getBankTransferDetails(String sellerId) async {
    try {
      final config = await getSellerPaymentConfig(sellerId);
      if (config == null) return null;

      final bankTransfer = config['bank_transfer'];
      if (bankTransfer != null && bankTransfer['enabled'] == true) {
        return bankTransfer['details'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error fetching bank transfer details: $e');
      return null;
    }
  }

  /// Validate bank transfer details
  static bool validateBankTransferDetails(Map<String, dynamic> details) {
    return (details['accountHolderName']?.toString().isNotEmpty ?? false) &&
        (details['accountNumber']?.toString().isNotEmpty ?? false) &&
        (details['ifscCode']?.toString().isNotEmpty ?? false) &&
        (details['bankName']?.toString().isNotEmpty ?? false);
  }
}
