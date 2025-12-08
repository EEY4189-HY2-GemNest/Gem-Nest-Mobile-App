import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';

class PaymentMethodConfig {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  bool enabled;
  Map<String, dynamic> details;

  PaymentMethodConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.enabled,
    required this.details,
  });
}

class PaymentConfigScreen extends StatefulWidget {
  const PaymentConfigScreen({super.key});

  @override
  State<PaymentConfigScreen> createState() => _PaymentConfigScreenState();
}

class _PaymentConfigScreenState extends State<PaymentConfigScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  // Store initial state for comparison
  final Map<String, Map<String, dynamic>> _initialState = {};

  // Payment methods configuration
  late Map<String, PaymentMethodConfig> _paymentMethods;

  @override
  void initState() {
    super.initState();
    _initializePaymentMethods();
    _loadPaymentConfig();
  }

  void _initializePaymentMethods() {
    _paymentMethods = {
      'card': PaymentMethodConfig(
        id: 'card',
        name: 'Card Payment',
        icon: Icons.credit_card,
        description: 'Credit/Debit card payments',
        enabled: true,
        details: {},
      ),
      'cod': PaymentMethodConfig(
        id: 'cod',
        name: 'Cash on Delivery',
        icon: Icons.local_atm,
        description: 'Payment on delivery',
        enabled: true,
        details: {},
      ),
      'bank_transfer': PaymentMethodConfig(
        id: 'bank_transfer',
        name: 'Bank Transfer',
        icon: Icons.account_balance,
        description: 'Direct bank transfer',
        enabled: false,
        details: {
          'accountHolderName': '',
          'accountNumber': '',
          'ifscCode': '',
          'bankName': '',
          'accountType': 'Savings', // Savings or Current
        },
      ),
    };
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
          for (var method in _paymentMethods.values) {
            if (data.containsKey(method.id)) {
              final methodData = data[method.id] as Map<String, dynamic>;
              method.enabled = methodData['enabled'] ?? false;
              method.details = Map<String, dynamic>.from(
                methodData['details'] as Map<String, dynamic>? ?? {},
              );
            }
            // Store initial state
            _initialState[method.id] = {
              'enabled': method.enabled,
              'details': Map<String, dynamic>.from(method.details),
            };
          }
        });
      } else {
        // No existing config, save current defaults as initial state
        for (var method in _paymentMethods.values) {
          _initialState[method.id] = {
            'enabled': method.enabled,
            'details': Map<String, dynamic>.from(method.details),
          };
        }
      }
    } catch (e) {
      print('Error loading payment config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkForChanges() {
    bool hasChanges = false;
    for (var method in _paymentMethods.values) {
      final initial = _initialState[method.id];
      if (initial != null) {
        if (method.enabled != initial['enabled'] ||
            _mapEquals(method.details, initial['details'])) {
          hasChanges = true;
          break;
        }
      }
    }
    print('_checkForChanges: hasChanges=$hasChanges');
    setState(() {
      _hasUnsavedChanges = hasChanges;
    });
  }

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return true;
    for (var key in a.keys) {
      if (a[key] != b[key]) return true;
    }
    return false;
  }

  Future<bool> _onWillPop() async {
    print('_onWillPop called, _hasUnsavedChanges: $_hasUnsavedChanges');

    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orangeAccent, width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Unsaved Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, false);
              await _savePaymentConfig();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save & Exit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _savePaymentConfig() async {
    try {
      setState(() => _isSaving = true);
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Validate that at least one method is enabled
      final hasEnabledMethod = _paymentMethods.values.any((m) => m.enabled);
      if (!hasEnabledMethod) {
        Fluttertoast.showToast(
          msg: 'Please enable at least one payment method',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Validate bank transfer details if enabled
      final bankTransfer = _paymentMethods['bank_transfer'];
      if (bankTransfer != null && bankTransfer.enabled) {
        if (bankTransfer.details['accountHolderName']?.toString().isEmpty ??
            true) {
          Fluttertoast.showToast(
            msg: 'Please enter account holder name for bank transfer',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return;
        }
        if (bankTransfer.details['accountNumber']?.toString().isEmpty ?? true) {
          Fluttertoast.showToast(
            msg: 'Please enter account number for bank transfer',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return;
        }
        if (bankTransfer.details['ifscCode']?.toString().isEmpty ?? true) {
          Fluttertoast.showToast(
            msg: 'Please enter IFSC code for bank transfer',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return;
        }
        if (bankTransfer.details['bankName']?.toString().isEmpty ?? true) {
          Fluttertoast.showToast(
            msg: 'Please enter bank name for bank transfer',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return;
        }
      }

      final configData = <String, dynamic>{};
      for (var method in _paymentMethods.values) {
        configData[method.id] = {
          'enabled': method.enabled,
          'details': method.details,
          'name': method.name,
          'description': method.description,
        };
      }
      configData['sellerId'] = userId;
      configData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('payment_configs')
          .doc(userId)
          .set(configData, SetOptions(merge: true));

      // Update initial state after save
      for (var method in _paymentMethods.values) {
        _initialState[method.id] = {
          'enabled': method.enabled,
          'details': Map<String, dynamic>.from(method.details),
        };
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      Fluttertoast.showToast(
        msg: 'Payment configuration saved successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error saving payment config: $e');
      Fluttertoast.showToast(
        msg: 'Error saving configuration',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purpleAccent, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(
                child: Text(
                  'Payment Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_hasUnsavedChanges) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Unsaved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          centerTitle: false,
          leading: const ProfessionalAppBarBackButton(),
          actions: [
            if (!_isLoading)
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                onPressed: _isSaving ? null : _savePaymentConfig,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: Colors.purpleAccent),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple[900]!,
                                Colors.purple[700]!
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Configure payment methods accepted by your store. Enable/disable methods and provide bank details if needed.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Payment Methods
                        ..._paymentMethods.values.map((method) {
                          return _buildPaymentMethodCard(method);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodConfig method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: method.enabled
              ? [const Color(0xFF303030), const Color(0xFF212121)]
              : [const Color(0xFF212121), const Color(0xFF121212)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method.enabled
              ? Colors.purpleAccent.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: method.enabled,
            onChanged: (value) {
              setState(() {
                method.enabled = value;
              });
              _checkForChanges();
            },
            title: Row(
              children: [
                Icon(method.icon, color: Colors.white70, size: 24),
                const SizedBox(width: 12),
                Text(
                  method.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 36, top: 4),
              child: Text(
                method.description,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            activeColor: Colors.purpleAccent,
          ),
          if (method.enabled && method.id == 'bank_transfer')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text(
                    'Bank Account Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBankDetailField(
                    label: 'Account Holder Name',
                    hint: 'Enter full name',
                    value: method.details['accountHolderName'] ?? '',
                    onChanged: (value) {
                      setState(() {
                        method.details['accountHolderName'] = value;
                      });
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBankDetailField(
                    label: 'Account Number',
                    hint: 'Enter account number',
                    value: method.details['accountNumber'] ?? '',
                    onChanged: (value) {
                      setState(() {
                        method.details['accountNumber'] = value;
                      });
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBankDetailField(
                    label: 'IFSC Code',
                    hint: 'e.g., SBIN0001234',
                    value: method.details['ifscCode'] ?? '',
                    onChanged: (value) {
                      setState(() {
                        method.details['ifscCode'] = value;
                      });
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBankDetailField(
                    label: 'Bank Name',
                    hint: 'e.g., State Bank of India',
                    value: method.details['bankName'] ?? '',
                    onChanged: (value) {
                      setState(() {
                        method.details['bankName'] = value;
                      });
                      _checkForChanges();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAccountTypeDropdown(method),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBankDetailField({
    required String label,
    required String hint,
    required String value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF424242),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF616161)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Colors.purpleAccent, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildAccountTypeDropdown(PaymentMethodConfig method) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Type',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: method.details['accountType'] ?? 'Savings',
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF424242),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF616161)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Colors.purpleAccent, width: 2),
            ),
          ),
          dropdownColor: const Color(0xFF424242),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: const [
            DropdownMenuItem(value: 'Savings', child: Text('Savings')),
            DropdownMenuItem(value: 'Current', child: Text('Current')),
          ],
          onChanged: (value) {
            setState(() {
              method.details['accountType'] = value ?? 'Savings';
            });
            _checkForChanges();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
