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
}
