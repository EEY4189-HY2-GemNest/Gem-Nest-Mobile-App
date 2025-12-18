import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen>
    with TickerProviderStateMixin {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // State variables
  Map<String, dynamic>? sellerData;
  bool _isLoading = true;
  bool _isUploadingProfilePic = false;
  String? _profileImageUrl;

  final ImagePicker _picker = ImagePicker();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Slide animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();

    _fetchSellerData();
    _loadProfileImage();
  }

  // ================= FETCH SELLER DATA =================
  Future<void> _fetchSellerData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc =
          await _firestore.collection('sellers').doc(userId).get();

      if (doc.exists) {
        setState(() {
          sellerData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ================= LOAD PROFILE IMAGE =================
  Future<void> _loadProfileImage() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final ref = _storage.ref('profile_images/$userId.jpg');
      final url = await ref.getDownloadURL();
      setState(() => _profileImageUrl = url);
    } catch (_) {
      _profileImageUrl = null;
    }
  }

  // ================= PICK & UPLOAD PROFILE IMAGE =================
  Future<void> _pickAndUploadProfileImage() async {
    setState(() => _isUploadingProfilePic = true);

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final userId = _auth.currentUser!.uid;
        final ref = _storage.ref('profile_images/$userId.jpg');

        await ref.putFile(File(pickedFile.path));
        final url = await ref.getDownloadURL();

        setState(() => _profileImageUrl = url);
      }
    } finally {
      setState(() => _isUploadingProfilePic = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Colors.black87,
                  ],
                ),
              ),
            ),

            SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    )
                  : sellerData == null
                      ? const Center(
                          child: Text(
                            'No Data Available',
                            style: TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildModernHeader(),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER (COMMIT 13) =================
  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white),
              ),
              const Spacer(),
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),

          const SizedBox(height: 32),

          // Profile image
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[800],
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : const AssetImage(
                            'assets/images/logo_new.png')
                        as ImageProvider,
              ),
              GestureDetector(
                onTap: _isUploadingProfilePic
                    ? null
                    : _pickAndUploadProfileImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white, width: 2),
                  ),
                  child: _isUploadingProfilePic
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                ),
              ),
            ],
          ).animate().scale(duration: 700.ms),

          const SizedBox(height: 16),

          // Seller name
          Text(
            sellerData!['displayName'] ?? 'Unknown Seller',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 8),

          // Verification badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: (sellerData!['isActive'] ?? false)
                  ? Colors.green
                  : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (sellerData!['isActive'] ?? false)
                  ? 'Verified Seller'
                  : 'Pending Verification',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
  return _buildInfoCard(
    'Email',
    sellerData!['email'],
    Icons.email,
  );
}

}
