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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Seller data
  Map<String, dynamic>? sellerData;
  bool _isLoading = true;
  bool _isUploadingProfilePic = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
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
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fetchSellerData();
    _loadProfileImage();

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    Future<void> _fetchSellerData() async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return;

  try {
    final doc =
        await _firestore.collection('sellers').doc(userId).get();

    if (doc.exists) {
      setState(() {
        sellerData = doc.data();
        _isLoading = false;
      });
    } else {
      _isLoading = false;
    }
  } catch (e) {
    _isLoading = false;
  }
}

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

Future<void> _pickAndUploadProfileImage() async {
  setState(() => _isUploadingProfilePic = true);

  final pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );

  if (pickedFile != null) {
    final userId = _auth.currentUser!.uid;
    final ref = _storage.ref('profile_images/$userId.jpg');
    await ref.putFile(File(pickedFile.path));
    _profileImageUrl = await ref.getDownloadURL();
  }

  setState(() => _isUploadingProfilePic = false);
}

Future<void> _downloadDocument(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  final dir = await getApplicationDocumentsDirectory();

  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(response.bodyBytes);

  await Share.shareXFiles(
  [XFile(file.path)],
  text: 'Document: $fileName',
);

}

@override
void dispose() {
  _fadeController.dispose();
  _slideController.dispose();
  super.dispose();
}



  }

  return Scaffold(
  backgroundColor: Colors.black,
  body: Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1A1A2E), Colors.black],
          ),
        ),
      ),
    ],
  ),
);

}
