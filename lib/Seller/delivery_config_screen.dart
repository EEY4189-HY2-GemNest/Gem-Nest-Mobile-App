import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';

class DeliveryMethodConfig {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  bool enabled;
  double price;

  DeliveryMethodConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.enabled,
    required this.price,
  });
}

class DeliveryConfigScreen extends StatefulWidget {
  const DeliveryConfigScreen({super.key});

  @override
  State<DeliveryConfigScreen> createState() => _DeliveryConfigScreenState();
}

class _DeliveryConfigScreenState extends State<DeliveryConfigScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  
  // Store initial state for comparison
  final Map<String, Map<String, dynamic>> _initialState = {};

  // Delivery methods configuration
  final Map<String, DeliveryMethodConfig> _deliveryMethods = {
    'pickup': DeliveryMethodConfig(
      id: 'pickup',
      name: 'Pickup',
      icon: Icons.store,
      description: 'Customer picks up from your location',
      enabled: false,
      price: 0.0,
    ),
    'standard': DeliveryMethodConfig(
      id: 'standard',
      name: 'Standard Delivery',
      icon: Icons.local_shipping,
      description: 'Delivery within 5-7 business days',
      enabled: true,
      price: 500.0,
    ),
    'express': DeliveryMethodConfig(
      id: 'express',
      name: 'Express Delivery',
      icon: Icons.bolt,
      description: 'Delivery within 2-3 business days',
      enabled: true,
      price: 1000.0,
    ),
    'fast': DeliveryMethodConfig(
      id: 'fast',
      name: 'Fast Delivery',
      icon: Icons.flash_on,
      description: 'Next day delivery',
      enabled: false,
      price: 1500.0,
    ),
    'overseas': DeliveryMethodConfig(
      id: 'overseas',
      name: 'Overseas Delivery',
      icon: Icons.flight,
      description: 'International shipping',
      enabled: false,
      price: 5000.0,
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadDeliveryConfig();
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
          for (var method in _deliveryMethods.values) {
            if (data.containsKey(method.id)) {
              final methodData = data[method.id] as Map<String, dynamic>;
              method.enabled = methodData['enabled'] ?? false;
              method.price = (methodData['price'] ?? 0.0).toDouble();
            }
            // Store initial state
            _initialState[method.id] = {
              'enabled': method.enabled,
              'price': method.price,
            };
          }
        });
      } else {
        // No existing config, save current defaults as initial state
        for (var method in _deliveryMethods.values) {
          _initialState[method.id] = {
            'enabled': method.enabled,
            'price': method.price,
          };
        }
      }
    } catch (e) {
      print('Error loading delivery config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkForChanges() {
    bool hasChanges = false;
    for (var method in _deliveryMethods.values) {
      final initial = _initialState[method.id];
      if (initial != null) {
        if (method.enabled != initial['enabled'] ||
            method.price != initial['price']) {
          hasChanges = true;
          break;
        }
      }
    }
    setState(() {
      _hasUnsavedChanges = hasChanges;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text(
          'Unsaved Changes',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, false);
              await _saveDeliveryConfig();
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _saveDeliveryConfig() async {
    try {
      setState(() => _isSaving = true);
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Validate that at least one method is enabled
      final hasEnabledMethod = _deliveryMethods.values.any((m) => m.enabled);
      if (!hasEnabledMethod) {
        Fluttertoast.showToast(
          msg: 'Please enable at least one delivery method',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final configData = <String, dynamic>{};
      for (var method in _deliveryMethods.values) {
        configData[method.id] = {
          'enabled': method.enabled,
          'price': method.price,
          'name': method.name,
          'description': method.description,
        };
      }
      configData['sellerId'] = userId;
      configData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('delivery_configs')
          .doc(userId)
          .set(configData, SetOptions(merge: true));

      // Update initial state after save
      for (var method in _deliveryMethods.values) {
        _initialState[method.id] = {
          'enabled': method.enabled,
          'price': method.price,
        };
      }
      
      setState(() {
        _hasUnsavedChanges = false;
      });

      Fluttertoast.showToast(
        msg: 'Delivery configuration saved successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error saving delivery config: $e');
      Fluttertoast.showToast(
        msg: 'Error saving configuration',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _applyToAllProducts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Apply to All Products',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will update all your listed products with these delivery methods. Continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      );

      if (result != true) return;

      setState(() => _isSaving = true);

      // Get enabled delivery methods
      final enabledMethods = _deliveryMethods.values
          .where((m) => m.enabled)
          .map((m) => m.id)
          .toList();

      // Update all products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in productsSnapshot.docs) {
        batch.update(doc.reference, {'deliveryMethods': enabledMethods});
      }
      await batch.commit();

      Fluttertoast.showToast(
        msg: 'Applied to ${productsSnapshot.docs.length} products',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error applying to products: $e');
      Fluttertoast.showToast(
        msg: 'Error applying configuration',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _applyToAllAuctions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Apply to All Auctions',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will update all your listed auctions with these delivery methods. Continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      );

      if (result != true) return;

      setState(() => _isSaving = true);

      // Get enabled delivery methods
      final enabledMethods = _deliveryMethods.values
          .where((m) => m.enabled)
          .map((m) => m.id)
          .toList();

      // Update all auctions
      final auctionsSnapshot = await _firestore
          .collection('auctions')
          .where('sellerId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in auctionsSnapshot.docs) {
        batch.update(doc.reference, {'deliveryMethods': enabledMethods});
      }
      await batch.commit();

      Fluttertoast.showToast(
        msg: 'Applied to ${auctionsSnapshot.docs.length} auctions',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error applying to auctions: $e');
      Fluttertoast.showToast(
        msg: 'Error applying configuration',
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
                colors: [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
          title: Row(
            children: [
              const Text(
                'Delivery Configuration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_hasUnsavedChanges) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Unsaved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
              onPressed: _isSaving ? null : _saveDeliveryConfig,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
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
                            colors: [Colors.blue[900]!, Colors.blue[700]!],
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
                                'Configure delivery methods and prices for your products. Enable/disable methods and set custom prices.',
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

                      // Delivery Methods
                      ..._deliveryMethods.values.map((method) {
                        return _buildDeliveryMethodCard(method);
                      }),

                      const SizedBox(height: 24),

                      // Bulk Actions
                      const Text(
                        'Bulk Actions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildBulkActionButton(
                        icon: Icons.shopping_bag,
                        title: 'Apply to All Products',
                        description: 'Update all products with current config',
                        onTap: _applyToAllProducts,
                      ),
                      const SizedBox(height: 12),

                      _buildBulkActionButton(
                        icon: Icons.gavel,
                        title: 'Apply to All Auctions',
                        description: 'Update all auctions with current config',
                        onTap: _applyToAllAuctions,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
  }

  Widget _buildDeliveryMethodCard(DeliveryMethodConfig method) {
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
              ? Colors.blueAccent.withOpacity(0.3)
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
            activeColor: Colors.blueAccent,
          ),
          if (method.enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextFormField(
                initialValue: method.price.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price (LKR)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                      const Icon(Icons.attach_money, color: Colors.white70),
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
                        const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                onChanged: (value) {
                  method.price = double.tryParse(value) ?? method.price;
                  _checkForChanges();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBulkActionButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Color(0xFF303030), Color(0xFF212121)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
