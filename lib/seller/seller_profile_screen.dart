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
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seller data not found')),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching data: $e')),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
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

  Future<void> _pickAndUploadProfileImage() async {
    setState(() {
      _isUploadingProfilePic = true;
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          final ref = _storage.ref().child('profile_images/$userId.jpg');
          await ref.putFile(File(pickedFile.path));
          final url = await ref.getDownloadURL();

          setState(() {
            _profileImageUrl = url;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile picture'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingProfilePic = false;
      });
    }
  }

  Future<void> _downloadDocument(String url, String fileName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Downloading $fileName...',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Download the file
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Determine file extension from URL or content type
        String fileExtension = '.jpg'; // default
        if (url.toLowerCase().contains('.pdf')) {
          fileExtension = '.pdf';
        } else if (url.toLowerCase().contains('.png')) {
          fileExtension = '.png';
        } else if (url.toLowerCase().contains('.jpeg') ||
            url.toLowerCase().contains('.jpg')) {
          fileExtension = '.jpg';
        }

        // Create filename with proper extension
        final cleanFileName =
            fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final fullFileName = '$cleanFileName$fileExtension';

        // Get app directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fullFileName';

        // Save file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Share the file immediately
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Document: $fileName',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fileName downloaded and shared successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Share Again',
                textColor: Colors.white,
                onPressed: () async {
                  await Share.shareXFiles(
                    [XFile(filePath)],
                    text: 'Document: $fileName',
                  );
                },
              ),
            ),
          );
        }
      } else {
        throw Exception(
            'Failed to download file - Status: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to download $fileName\nError: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Modern gradient background
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
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Animated background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: DashboardPatternPainter(),
                ),
              ),
              SafeArea(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Colors.blueAccent),
                      )
                    : sellerData == null
                        ? const Center(
                            child: Text(
                              'No Data Available',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: RefreshIndicator(
                                onRefresh: _fetchSellerData,
                                color: Colors.blue,
                                backgroundColor: Colors.grey[900],
                                child: CustomScrollView(
                                  slivers: [
                                    // Modern Header
                                    SliverToBoxAdapter(
                                      child: _buildModernHeader(),
                                    ),
                                    // Personal Information Section
                                    SliverToBoxAdapter(
                                      child: _buildPersonalInfoSection(),
                                    ),
                                    // Business Information Section
                                    SliverToBoxAdapter(
                                      child: _buildBusinessInfoSection(),
                                    ),
                                    // Documents Section
                                    SliverToBoxAdapter(
                                      child: _buildDocumentsSection(),
                                    ),
                                    // Account Status Section
                                    SliverToBoxAdapter(
                                      child: _buildAccountStatusSection(),
                                    ),
                                    SliverToBoxAdapter(
                                      child: const SizedBox(height: 100),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const Spacer(),
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 32),
          // Profile Picture Section
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/images/logo_new.png')
                          as ImageProvider,
                  backgroundColor: Colors.grey[800],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingProfilePic
                      ? null
                      : _pickAndUploadProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade500, Colors.blue.shade700],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ],
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            sellerData!['displayName'] ?? 'Unknown Seller',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      delay: 0.ms,
      children: [
        _buildInfoCard('Full Name', sellerData!['displayName'] ?? 'N/A',
            Icons.badge_outlined),
        _buildInfoCard('Email Address', sellerData!['email'] ?? 'N/A',
            Icons.email_outlined),
        _buildInfoCard('Phone Number', sellerData!['phoneNumber'] ?? 'N/A',
            Icons.phone_outlined),
        _buildInfoCard('NIC Number', sellerData!['nicNumber'] ?? 'N/A',
            Icons.credit_card_outlined),
        _buildInfoCard('Address', sellerData!['address'] ?? 'N/A',
            Icons.location_on_outlined),
      ],
    );
  }

  Widget _buildBusinessInfoSection() {
    return _buildSection(
      title: 'Business Information',
      icon: Icons.business_outlined,
      delay: 200.ms,
      children: [
        _buildInfoCard('Business Name', sellerData!['businessName'] ?? 'N/A',
            Icons.business_center_outlined),
        _buildInfoCard('BR Number', sellerData!['brNumber'] ?? 'N/A',
            Icons.numbers_outlined),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return _buildSection(
      title: 'Documents',
      icon: Icons.description_outlined,
      delay: 400.ms,
      children: [
        _buildDocumentCard(
          'Business Registration',
          sellerData!['businessRegistrationUrl'],
          Icons.business_center,
          Colors.blue,
        ),
        _buildDocumentCard(
          'NIC Document',
          sellerData!['nicDocumentUrl'],
          Icons.credit_card,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildAccountStatusSection() {
    final isActive = sellerData!['isActive'] ?? false;
    return _buildSection(
      title: 'Account Status',
      icon: Icons.shield_outlined,
      delay: 600.ms,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [Colors.green.shade800, Colors.green.shade600]
                  : [Colors.orange.shade800, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.green.shade400 : Colors.orange.shade400,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? Icons.verified : Icons.pending,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Account Verified' : 'Verification Pending',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'Your seller account is active and verified'
                          : 'Your account is under review by administrators',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Duration delay,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: delay).slideX(begin: 0.3);
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[900]!.withOpacity(0.8),
            Colors.grey[800]!.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
      String label, String? url, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: url != null ? () => _viewDocument(url, label) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[900]!.withOpacity(0.8),
                Colors.grey[800]!.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url != null
                          ? 'Tap to view document'
                          : 'Document not available',
                      style: TextStyle(
                        fontSize: 14,
                        color: url != null ? Colors.blue : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (url != null) ...[
                IconButton(
                  onPressed: () => _downloadDocument(url, label),
                  icon: Icon(
                    Icons.download_outlined,
                    color: color,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: color.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_outlined),
            activeIcon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _viewDocument(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.description, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load document',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _downloadDocument(url, title),
            child:
                const Text('Download', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

// Custom painter for background pattern
class DashboardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    const spacing = 60.0;

    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      path.moveTo(i, 0);
      path.lineTo(i + size.height, size.height);
    }

    for (double i = 0; i < size.height + spacing; i += spacing) {
      path.moveTo(0, i);
      path.lineTo(size.width, i - size.width);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

