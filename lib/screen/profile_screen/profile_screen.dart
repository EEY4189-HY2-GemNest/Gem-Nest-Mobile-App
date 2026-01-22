// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/screen/auth_screens/login_screen.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:gemnest_mobile_app/widget/shared_app_bar.dart';
import 'package:gemnest_mobile_app/widget/shared_bottom_nav.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  bool isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  File? _profileImage;
  String? imageUrl;

  // Additional user data from Firebase
  Map<String, dynamic>? _userData;
  String? _userRole;
  bool? _isAccountActive;
  DateTime? _registrationDate;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(
          'You must be logged in to view your profile.', AppTheme.errorRed);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    try {
      // First try to fetch from buyers collection
      DocumentSnapshot buyerDoc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(userId)
          .get();

      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(userId)
          .get();

      // Also try to fetch from users collection (legacy support)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      Map<String, dynamic>? data;
      String role = 'buyer';

      if (buyerDoc.exists) {
        data = buyerDoc.data() as Map<String, dynamic>?;
        role = 'buyer';
      } else if (sellerDoc.exists) {
        data = sellerDoc.data() as Map<String, dynamic>?;
        role = 'seller';
      } else if (userDoc.exists) {
        data = userDoc.data() as Map<String, dynamic>?;
        role = data?['role'] ?? 'buyer';
      }

      if (data != null) {
        setState(() {
          _userData = data;
          _userRole = role;
          _isAccountActive = data?['isActive'] ?? true;

          // Handle different field names for backward compatibility
          _nameController.text = data?['displayName'] ?? data?['name'] ?? '';
          _emailController.text = data?['email'] ?? '';
          _phoneController.text = data?['phoneNumber'] ?? data?['phone'] ?? '';
          _addressController.text = data?['address'] ?? '';
          imageUrl = data?['imageUrl'] ?? data?['profileImageUrl'];

          // Parse registration date from Firebase timestamp
          if (data?['createdAt'] != null) {
            if (data?['createdAt'] is Timestamp) {
              _registrationDate = (data!['createdAt'] as Timestamp).toDate();
            }
          } else {
            // Fallback to Firebase Auth user creation time
            _registrationDate =
                FirebaseAuth.instance.currentUser?.metadata.creationTime;
          }
        });

        // Start animations
        _slideController.forward();
        _fadeController.forward();
      } else {
        _showSnackBar(
            'No profile data found. Please complete your registration.',
            AppTheme.warningOrange);
      }
    } catch (e) {
      _showSnackBar('Failed to load profile: $e', AppTheme.errorRed);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildImagePickerBottomSheet(picker),
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildImagePickerBottomSheet(ImagePicker picker) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose Profile Picture',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildBottomSheetTile(
            Icons.camera_alt,
            'Take a Photo',
            AppTheme.primaryBlue,
            () async {
              Navigator.of(
                context,
              ).pop(await picker.pickImage(source: ImageSource.camera));
            },
          ),
          _buildBottomSheetTile(
            Icons.photo_library,
            'Choose from Gallery',
            AppTheme.successGreen,
            () async {
              Navigator.of(
                context,
              ).pop(await picker.pickImage(source: ImageSource.gallery));
            },
          ),
          _buildBottomSheetTile(Icons.cancel, 'Cancel', AppTheme.errorRed, () {
            Navigator.of(context).pop();
          }),
        ],
      ),
    );
  }

  Widget _buildBottomSheetTile(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  Future<String?> _uploadProfileImage(File? imageFile) async {
    if (imageFile == null) return imageUrl;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(
          'You must be logged in to upload an image.', AppTheme.errorRed);
      return null;
    }

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      _showSnackBar('Failed to upload image: $e', AppTheme.errorRed);
      return null;
    }
  }

  Future<void> _saveUserDetails(
    String name,
    String email,
    String phone,
    String address,
    String? newImageUrl,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(
          'You must be logged in to save your profile.', AppTheme.errorRed);
      return;
    }

    try {
      // Determine which collection to update based on user role
      String collectionName = _userRole == 'seller' ? 'sellers' : 'buyers';

      Map<String, dynamic> updateData = {
        'displayName': name,
        'email': email,
        'phoneNumber': phone,
        'address': address,
        'imageUrl': newImageUrl ?? imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Also maintain backward compatibility with old 'users' collection
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userId)
          .set(updateData, SetOptions(merge: true));

      // Update legacy users collection if it exists
      DocumentSnapshot legacyUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (legacyUserDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': name,
          'email': email,
          'phone': phone,
          'imageUrl': newImageUrl ?? imageUrl,
        }, SetOptions(merge: true));
      }

      _showSnackBar('Profile updated successfully', AppTheme.successGreen);
    } catch (e) {
      _showSnackBar('Failed to save profile: $e', AppTheme.errorRed);
    }
  }

  void _logout() {
    final logoutContext = context;
    showDialog(
      context: logoutContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.errorRed),
            SizedBox(width: 10),
            Text(
              'Confirm Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              Navigator.of(logoutContext).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<bool> _onWillPop() async {
    if (_isEditing) {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Unsaved Changes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'You have unsaved changes. Are you sure you want to leave without saving?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.lightGray),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Leave',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: SharedAppBar(
          title: 'My Profile',
          onBackPressed: () => Navigator.of(context).maybePop(),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 26),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    strokeWidth: 3.0,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchUserData,
                  color: AppTheme.primaryBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        _buildPersonalInfoSection(),
                        _buildAccountDetailsSection(),
                        if (_userRole == 'seller')
                          _buildSellerSpecificSection(),
                        _buildActionButtons(),
                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
        ),
        floatingActionButton:
            SharedBottomNavigation.buildFloatingActionButton(context, 3),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: const SharedBottomNavigation(currentIndex: 3),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Hero(
                tag: 'profile_avatar',
                child: GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryBlueDark
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 75,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : (imageUrl != null && imageUrl!.isNotEmpty
                              ? NetworkImage(imageUrl!) as ImageProvider
                              : null),
                      backgroundColor: Colors.grey.shade200,
                      child: _profileImage == null &&
                              (imageUrl == null || imageUrl!.isEmpty)
                          ? Icon(
                              _isEditing ? Icons.camera_alt : Icons.person,
                              color: AppTheme.primaryBlue,
                              size: 60,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _nameController.text.isNotEmpty
                    ? _nameController.text
                    : 'User Name',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _userRole == 'seller'
                        ? [AppTheme.warningOrange, Colors.deepOrange.shade600]
                        : [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_userRole == 'seller'
                              ? AppTheme.warningOrange
                              : AppTheme.primaryBlue)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '${_userRole?.toUpperCase() ?? 'BUYER'} ACCOUNT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isAccountActive == true
                        ? Icons.verified_user
                        : Icons.pending,
                    color:
                        _isAccountActive == true ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isAccountActive == true
                        ? 'Account Active'
                        : 'Pending Verification',
                    style: TextStyle(
                      color: _isAccountActive == true
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF667eea),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: Icons.person,
                    label: 'Full Name',
                    controller: _nameController,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.email,
                    label: 'Email Address',
                    controller: _emailController,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.phone,
                    label: 'Phone Number',
                    controller: _phoneController,
                    enabled: _isEditing,
                  ),
                  if (_userRole == 'seller' ||
                      _addressController.text.isNotEmpty)
                    const SizedBox(height: 16),
                  if (_userRole == 'seller' ||
                      _addressController.text.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.location_on,
                      label: 'Address',
                      controller: _addressController,
                      enabled: _isEditing,
                      maxLines: 2,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_circle_outlined,
                          color: Color(0xFF667eea),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Account Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    icon: Icons.badge,
                    label: 'User ID',
                    value: FirebaseAuth.instance.currentUser?.uid != null
                        ? FirebaseAuth.instance.currentUser!.uid.substring(0, 8)
                        : 'N/A',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Member Since',
                    value: _registrationDate != null
                        ? '${_registrationDate!.day}/${_registrationDate!.month}/${_registrationDate!.year}'
                        : 'N/A',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.security,
                    label: 'Account Status',
                    value: _isAccountActive == true ? 'Active' : 'Pending',
                    valueColor:
                        _isAccountActive == true ? Colors.green : Colors.orange,
                  ),
                  if (_userData?['firebaseUid'] != null)
                    const SizedBox(height: 16),
                  if (_userData?['firebaseUid'] != null)
                    _buildDetailRow(
                      icon: Icons.verified,
                      label: 'Email Verified',
                      value: FirebaseAuth.instance.currentUser?.emailVerified ==
                              true
                          ? 'Yes'
                          : 'No',
                      valueColor:
                          FirebaseAuth.instance.currentUser?.emailVerified ==
                                  true
                              ? Colors.green
                              : Colors.red,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSellerSpecificSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.orange.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_userData?['businessName'] != null)
                    _buildDetailRow(
                      icon: Icons.store,
                      label: 'Business Name',
                      value: _userData?['businessName'] ?? 'N/A',
                    ),
                  if (_userData?['brNumber'] != null)
                    const SizedBox(height: 16),
                  if (_userData?['brNumber'] != null)
                    _buildDetailRow(
                      icon: Icons.confirmation_number,
                      label: 'BR Number',
                      value: _userData?['brNumber'] ?? 'N/A',
                    ),
                  if (_userData?['nicNumber'] != null)
                    const SizedBox(height: 16),
                  if (_userData?['nicNumber'] != null)
                    _buildDetailRow(
                      icon: Icons.credit_card,
                      label: 'NIC Number',
                      value: _userData?['nicNumber'] ?? 'N/A',
                    ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.verified_user,
                    label: 'Verification Status',
                    value:
                        _isAccountActive == true ? 'Verified' : 'Under Review',
                    valueColor:
                        _isAccountActive == true ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_isEditing)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28a745),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: const Color(0xFF28a745).withOpacity(0.3),
                ),
                onPressed: () async {
                  setState(() => isLoading = true);
                  final newImageUrl = await _uploadProfileImage(_profileImage);
                  if (_profileImage != null && newImageUrl == null) {
                    setState(() => isLoading = false);
                    return;
                  }
                  await _saveUserDetails(
                    _nameController.text,
                    _emailController.text,
                    _phoneController.text,
                    _addressController.text,
                    newImageUrl,
                  );
                  setState(() {
                    _isEditing = false;
                    imageUrl = newImageUrl;
                    isLoading = false;
                  });
                },
                icon: const Icon(Icons.save, size: 24),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_isEditing) const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFdc3545),
                foregroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: const Color(0xFFdc3545).withOpacity(0.3),
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 24),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C3E50),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: enabled ? const Color(0xFF667eea) : Colors.grey,
            size: 22,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? const Color(0xFF667eea) : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF667eea),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
