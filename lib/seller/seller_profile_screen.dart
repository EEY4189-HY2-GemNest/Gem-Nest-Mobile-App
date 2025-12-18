import 'dart:io';
import 'package:flutter/material.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  // Seller data
  Map<String, dynamic>? sellerData;
  bool _isLoading = true;
  bool _isUploadingProfilePic = false;
}
