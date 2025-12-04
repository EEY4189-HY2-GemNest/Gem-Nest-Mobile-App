import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for animations
import 'package:image_picker/image_picker.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _profileImageUrl;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Seller data and form controllers
  Map<String, dynamic>? sellerData;
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
    _loadProfileImage();
  }

  Future<void> _fetchSellerData() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        DocumentSnapshot doc =
            await _firestore.collection('sellers').doc(userId).get();
        if (doc.exists) {
          setState(() {
            sellerData = doc.data() as Map<String, dynamic>;
            _displayNameController.text = sellerData!['displayName'] ?? '';
            _addressController.text = sellerData!['address'] ?? '';
            _emailController.text = sellerData!['email'] ?? '';
            _usernameController.text = sellerData!['username'] ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seller data not found')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Future<void> _loadProfileImage() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final ref = _storage.ref().child('profile_images/$userId.jpg');
        final url = await ref.getDownloadURL();
        setState(() {
          _profileImageUrl = url;
        });
      } catch (e) {
        setState(() {
          _profileImageUrl = null;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage != null) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        try {
          final ref = _storage.ref().child('profile_images/$userId.jpg');
          await ref.putFile(_selectedImage!);
          final url = await ref.getDownloadURL();
          setState(() {
            _profileImageUrl = url;
            _selectedImage = null;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    }
  }

  
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.black87],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey[400],
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              currentIndex: 2,
              onTap: (index) {
                if (index == 2) return;
                Navigator.pop(context);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: 'Notifications',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout),
                  label: 'Logout',
                ),
              ],
              selectedLabelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              showUnselectedLabels: true,
              selectedIconTheme:
                  const IconThemeData(size: 32, color: Colors.blueAccent),
              unselectedIconTheme:
                  const IconThemeData(size: 28, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
