// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/widget/bid_history_widget.dart';
import 'package:gemnest_mobile_app/widget/certificate_viewer.dart';
import 'package:gemnest_mobile_app/widget/shared_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class AuctionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> auction;

  const AuctionDetailsScreen({
    super.key,
    required this.auction,
  });

  @override
  State<AuctionDetailsScreen> createState() => _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends State<AuctionDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _auction;
  Map<String, dynamic>? _sellerData;
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _auction = widget.auction;
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _fetchSellerData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSellerData() async {
    try {
      final sellerId = _auction['sellerId'];
      if (sellerId != null) {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .get();

        if (sellerDoc.exists) {
          setState(() {
            _sellerData = sellerDoc.data();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching seller data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _callSeller() async {
    if (_sellerData == null || _sellerData!['phone'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller phone number not available')),
        );
      }
      return;
    }

    final phoneNumber = _sellerData!['phone'];
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calling seller: $e')),
        );
      }
    }
  }

  Future<void> _sendWhatsApp() async {
    if (_sellerData == null || _sellerData!['phone'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller phone number not available')),
        );
      }
      return;
    }

    final phoneNumber = _sellerData!['phone'];
    final String message =
        'Hi, I am interested in bidding for ${_auction['title']}. Can you provide more details?';
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp not installed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening WhatsApp: $e')),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().split('.')[0];
    }
    return timestamp?.toString() ?? 'N/A';
  }

  Duration? _getTimeRemaining() {
    try {
      if (_auction['endTime'] is Timestamp) {
        final endTime = (_auction['endTime'] as Timestamp).toDate();
        final remaining = endTime.difference(DateTime.now());
        return remaining.isNegative ? Duration.zero : remaining;
      } else if (_auction['endTime'] is String) {
        final endTime = DateTime.parse(_auction['endTime']);
        final remaining = endTime.difference(DateTime.now());
        return remaining.isNegative ? Duration.zero : remaining;
      }
    } catch (e) {
      debugPrint('Error calculating time remaining: $e');
    }
    return null;
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) {
      return 'Auction Ended';
    }
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  String _getImageUrl() {
    return _auction['imageUrl'] ??
        _auction['image'] ??
        _auction['imagePath'] ??
        '';
  }

  String _getFormattedPrice(dynamic price) {
    if (price == null) return '0';
    if (price is String) {
      final parsed = double.tryParse(price) ?? 0.0;
      return parsed.toStringAsFixed(0);
    }
    if (price is num) {
      return (price).toStringAsFixed(0);
    }
    return '0';
  }

  IconData _getCertificateIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'gem':
        return Icons.diamond;
      case 'certificate':
        return Icons.verified;
      case 'authentication':
        return Icons.security;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final timeRemaining = _getTimeRemaining();
    final isAuctionEnded = (timeRemaining?.inSeconds ?? 0) <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: SharedAppBar(
        title: _auction['title'] ?? 'Auction Details',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF667eea)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== PREMIUM IMAGE SECTION =====
                  Stack(
                    children: [
                      // Image Container
                      Container(
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF667eea),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Image Could Not Load',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Check your connection',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Image Available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      // Status Badge - Live/Ended
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isAuctionEnded
                                ? const Color(0xFF9E9E9E)
                                : const Color(0xFFFF6B6B),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (isAuctionEnded
                                        ? Colors.grey
                                        : const Color(0xFFFF6B6B))
                                    .withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isAuctionEnded)
                                ScaleTransition(
                                  scale: Tween(begin: 0.8, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                isAuctionEnded ? 'ENDED' : 'LIVE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ===== TITLE & CATEGORY =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _auction['title'] ?? 'Auction Item',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667eea).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.diamond,
                                    size: 14,
                                    color: const Color(0xFF667eea),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _auction['category'] ?? 'Premium Gems',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF667eea),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_auction['lotNumber'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Lot #${_auction['lotNumber']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: isAuctionEnded
                          ? LinearGradient(
                              colors: [
                                Colors.grey[600]!,
                                Colors.grey[700]!,
                              ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [
                                  Color(0xFFFFA500),
                                  Color(0xFFFF8C00),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isAuctionEnded
                                    ? Colors.grey
                                    : const Color(0xFFFFA500))
                                .withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Time Remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(timeRemaining ?? Duration.zero),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              fontFamily: 'Monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ends: ${_formatDate(_auction['endTime'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ===== BIDDING INFORMATION =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bidding Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _buildBidInfoRow(
                                'Current Bid',
                                'Rs. ${_auction['currentBid']?.toStringAsFixed(0) ?? '0'}',
                                const Color(0xFF28a745),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(color: Colors.grey[100]),
                              ),
                              _buildBidInfoRow(
                                'Starting Price',
                                'Rs. ${_getFormattedPrice(_auction['startingPrice'])}',
                                Colors.grey[600]!,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(color: Colors.grey[100]),
                              ),
                              _buildBidInfoRow(
                                'Total Bids',
                                '${_auction['bidHistory']?.length ?? _auction['bidCount']?.toString() ?? '0'} bids',
                                const Color(0xFF667eea),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ===== BID HISTORY =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Bids',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            Icon(
                              Icons.trending_up_rounded,
                              color: const Color(0xFF667eea),
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BidHistoryWidget(
                              auctionId: _auction['id'] ?? '',
                              isSeller: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ===== DESCRIPTION =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _auction['description'] ??
                                'No description available',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.7,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ===== GEM CERTIFICATES =====
                  if (_auction['gemCertificates'] != null &&
                      (_auction['gemCertificates'] is List
                          ? (_auction['gemCertificates'] as List).isNotEmpty
                          : false))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gem Certificates',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  (_auction['gemCertificates'] as List).length,
                              itemBuilder: (context, index) {
                                final cert = (_auction['gemCertificates']
                                    as List)[index];
                                return Column(
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          16, 8, 16, 8),
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9C27B0)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: Icon(
                                          _getCertificateIcon(cert['type']),
                                          color: const Color(0xFF9C27B0),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        cert['fileName'] ?? 'Certificate',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Verified Certificate',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            final String url =
                                                cert['url'] ?? '';
                                            final String certFileName =
                                                cert['fileName'] ??
                                                    'Certificate ${index + 1}';
                                            if (url.isNotEmpty) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CertificateViewerScreen(
                                                    url: url,
                                                    fileName: certFileName,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF667eea)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.open_in_new_rounded,
                                              size: 16,
                                              color: Color(0xFF667eea),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index <
                                        (_auction['gemCertificates'] as List)
                                                .length -
                                            1)
                                      Divider(
                                        color: Colors.grey[100],
                                        height: 1,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ===== SELLER INFORMATION =====
                  if (_sellerData != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seller Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF667eea).withOpacity(0.05),
                                  const Color(0xFF667eea).withOpacity(0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: const Color(0xFF667eea).withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF667eea),
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 32,
                                        backgroundColor: const Color(0xFF667eea)
                                            .withOpacity(0.1),
                                        child: const Icon(
                                          Icons.store,
                                          color: Color(0xFF667eea),
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _sellerData!['name'] ??
                                                _sellerData!['displayName'] ??
                                                'Seller',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (_sellerData!['email'] != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.email_outlined,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    _sellerData!['email'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _callSeller,
                                        icon: const Icon(Icons.call_rounded),
                                        label: const Text('Call'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF28a745),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _sendWhatsApp,
                                        icon: const Icon(Icons.chat_rounded),
                                        label: const Text('WhatsApp'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF25D366),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildBidInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
