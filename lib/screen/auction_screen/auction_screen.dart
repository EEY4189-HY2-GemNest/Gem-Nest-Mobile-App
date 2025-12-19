// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/auction_model.dart';
import 'package:gemnest_mobile_app/repositories/auction_repository.dart';
import 'package:gemnest_mobile_app/screen/auction_screen/auction_payment_screen.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:gemnest_mobile_app/widget/shared_bottom_nav.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  // Repository with optimized data structures
  final AuctionRepository _auctionRepository = AuctionRepository();

  // Filter Controllers
  final TextEditingController _filterController = TextEditingController();

  // Filter State Variables
  bool _isFilterExpanded = false;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  double _minPrice = 0;
  double _maxPrice = 10000;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
      title: const Text(
        'Auctions',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      leading: ProfessionalAppBarBackButton(
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () {
            setState(() {
              _isFilterExpanded = !_isFilterExpanded;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isFilterExpanded ? 320 : 0,
      child: _isFilterExpanded
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Filter
                    TextField(
                      controller: _filterController,
                      decoration: const InputDecoration(
                        labelText: 'Search auctions...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status Filter
                    Row(
                      children: [
                        const Text('Status: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children:
                                ['all', 'live', 'ended', 'won'].map((status) {
                              final isSelected = _selectedStatus == status;
                              return FilterChip(
                                label: Text(status.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                },
                                selectedColor: Colors.blue.shade100,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category Filter
                    Row(
                      children: [
                        const Text('Category: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            items: [
                              'all',
                              'electronics',
                              'jewelry',
                              'art',
                              'collectibles',
                              'antiques',
                              'other'
                            ]
                                .map((category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Price Range Filter
                    Row(
                      children: [
                        const Text('Price Range: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: RangeSlider(
                            values: RangeValues(_minPrice, _maxPrice),
                            min: 0,
                            max: 10000,
                            divisions: 100,
                            labels: RangeLabels('Rs.${_minPrice.toInt()}',
                                'Rs.${_maxPrice.toInt()}'),
                            onChanged: (values) {
                              setState(() {
                                _minPrice = values.start;
                                _maxPrice = values.end;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Stream<List<Auction>> _getFilteredAuctionsStream() {
    // Use optimized repository with efficient filtering
    if (_searchQuery.isNotEmpty) {
      return _auctionRepository.searchAuctions(_searchQuery);
    }

    return _auctionRepository.getAuctionsStream(
      category: _selectedCategory,
      status: _selectedStatus,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    );
  }

  List<Auction> _filterAuctionsByStatus(List<Auction> auctions) {
    // Auctions are already filtered by repository
    // Apply additional client-side search filter if needed
    if (_searchQuery.isEmpty) {
      return auctions;
    }

    final query = _searchQuery.toLowerCase();
    return auctions.where((auction) {
      return auction.title.toLowerCase().contains(query) ||
          auction.description.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildAuctionsList() {
    return StreamBuilder<List<Auction>>(
      stream: _getFilteredAuctionsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Refresh
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final auctions = snapshot.data ?? [];

        if (auctions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No auctions found',
                    style:
                        TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text('Try adjusting your filters',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final auction = auctions[index];
            return AuctionItemCard(
              auction: auction,
              auctionRepository: _auctionRepository,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(
            child: _buildAuctionsList(),
          ),
        ],
      ),
      bottomNavigationBar: const SharedBottomNavigation(currentIndex: 4),
    );
  }
}

class AuctionItemCard extends StatefulWidget {
  final Auction auction;
  final AuctionRepository auctionRepository;

  const AuctionItemCard({
    super.key,
    required this.auction,
    required this.auctionRepository,
  });

  @override
  _AuctionItemCardState createState() => _AuctionItemCardState();
}

class _AuctionItemCardState extends State<AuctionItemCard>
    with SingleTickerProviderStateMixin {
  late double _currentBid;
  late Duration _remainingTime;
  late Timer _timer;
  final TextEditingController _bidController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _bidAnimation;
  String? _winningUserId;
  late StreamSubscription<DocumentSnapshot> _auctionSubscription;

  @override
  void initState() {
    super.initState();
    _currentBid = widget.auction.currentBid;
    _remainingTime = widget.auction.timeRemaining;
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTime);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bidAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _auctionSubscription = FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auction.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentBid = (data['currentBid'] as num?)?.toDouble() ??
              widget.auction.currentBid;
          _winningUserId = data['winningUserId'];
        });
        if (data['currentBid'] > widget.auction.currentBid) {
          _animationController.forward(from: 0.0);
        }
      }
    }, onError: (error) {
      print("Realtime listener error: $error");
    });
  }

  void _updateTime(Timer timer) {
    final now = DateTime.now();
    if (widget.auction.endTime.isAfter(now)) {
      setState(() {
        _remainingTime = widget.auction.endTime.difference(now);
      });
    } else {
      _timer.cancel();
    }
  }

  Future<void> _placeBid() async {
    final enteredBid = double.tryParse(_bidController.text.trim());
    final currentUser = FirebaseAuth.instance.currentUser;

    print("Current user UID: ${currentUser?.uid ?? 'Not authenticated'}");
    print("Auction ID: ${widget.auction.id}");
    print("Attempting bid: $enteredBid, Current bid: $_currentBid");

    if (currentUser == null) {
      _showSnackBar('Please log in to bid');
      return;
    }

    if (enteredBid == null) {
      _showSnackBar('Please enter a valid number');
      return;
    }

    if (widget.auction.endTime.isBefore(DateTime.now())) {
      _showSnackBar('Auction has ended');
      return;
    }

    if (enteredBid <= _currentBid) {
      _showSnackBar('Bid must exceed current bid');
      return;
    }

    if ((enteredBid - _currentBid) < widget.auction.minimumNextBid) {
      _showSnackBar(
          'Minimum increment: ${_formatCurrency(widget.auction.minimumNextBid)}');
      return;
    }

    final docSnapshot = await FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auction.id)
        .get();
    if (!docSnapshot.exists) {
      _showSnackBar('Auction not found');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                  ),
                ),
                child: const Icon(
                  Icons.gavel,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Bid',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Place bid of:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(enteredBid),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm ?? false) {
      setState(() => _isLoading = true);
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Use optimized repository method
          final success = await widget.auctionRepository.placeBid(
            widget.auction.id,
            currentUser.uid,
            currentUser.displayName ?? 'Anonymous',
            enteredBid,
          );

          if (success) {
            setState(() {
              _currentBid = enteredBid;
              _winningUserId = currentUser.uid;
              _isLoading = false;
            });
            _bidController.clear();
            _showSnackBar('Bid placed successfully!');
          } else {
            setState(() => _isLoading = false);
            _showSnackBar('Bid placement failed. Try again.');
          }
        }
      } catch (e) {
        print("Bid placement error: $e");
        setState(() => _isLoading = false);
        _showSnackBar('Error placing bid: $e');
      }
    }
  }

  Future<void> _handlePayment() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    print("Current user UID: ${currentUser?.uid ?? 'Not authenticated'}");
    print("Auction ID: ${widget.auction.id}");

    if (currentUser == null) {
      _showSnackBar('Please log in to pay');
      return;
    }

    if (_winningUserId != currentUser.uid) {
      _showSnackBar('Only the winner can initiate payment');
      return;
    }

    if (widget.auction.endTime.isAfter(DateTime.now())) {
      _showSnackBar('Auction is still active');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionPaymentScreen(
          auctionId: widget.auction.id,
          itemPrice: _currentBid,
          title: widget.auction.title,
          imagePath: widget.auction.imageUrl,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blue[800],
        elevation: 6,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatTime(Duration duration) {
    if (duration.inSeconds <= 0) {
      return '00d : 00h : 00m : 00s';
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return '${days}d : ${hours}h : ${minutes}m : ${seconds}s';
  }

  String _formatCurrency(double amount) {
    return 'Rs.${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  void dispose() {
    _auctionSubscription.cancel();
    _timer.cancel();
    _bidController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAuctionActive = _remainingTime.inSeconds > 0;
    bool isCurrentUserWinner =
        _winningUserId == FirebaseAuth.instance.currentUser?.uid;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            isAuctionActive ? Colors.blue[50]! : Colors.grey[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.network(
                  widget.auction.imageUrl.isNotEmpty
                      ? widget.auction.imageUrl
                      : 'assets/placeholder.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAuctionActive
                            ? [Colors.green[600]!, Colors.green[400]!]
                            : [Colors.red[600]!, Colors.red[400]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAuctionActive ? 'LIVE' : 'ENDED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.auction.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lot #${widget.auction.title.hashCode.toString().substring(0, 4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ScaleTransition(
                  scale: _bidAnimation,
                  child: Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.green[700], size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Current Bid: ${_formatCurrency(_currentBid)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: _remainingTime.inSeconds < 300
                          ? Colors.red[700]
                          : Colors.grey[600],
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time Left: ${_formatTime(_remainingTime)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _remainingTime.inSeconds < 300
                            ? Colors.red[700]
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Colors.grey[600], size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Min. Inc: ${_formatCurrency(widget.auction.minimumNextBid)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!isAuctionActive && _winningUserId != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCurrentUserWinner
                            ? [Colors.green[100]!, Colors.green[50]!]
                            : [Colors.grey[200]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrentUserWinner ? Icons.celebration : Icons.info,
                          color: isCurrentUserWinner
                              ? Colors.green[800]
                              : Colors.grey[800],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isCurrentUserWinner
                                ? 'You Won! Congratulations!'
                                : 'Won by another bidder',
                            style: TextStyle(
                              color: isCurrentUserWinner
                                  ? Colors.green[800]
                                  : Colors.grey[800],
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (widget.auction.gemCertificates != null &&
                    (widget.auction.gemCertificates as List).isNotEmpty) ...[
                  _buildCertificateSection(),
                  const SizedBox(height: 20),
                ],
                if (isAuctionActive) ...[
                  TextField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      hintText: 'Enter your bid',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon:
                          Icon(Icons.monetization_on, color: Colors.blue[600]),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () => _bidController.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue[200]!, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue[700]!, width: 2),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _getButtonAction(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _getButtonColor(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isAuctionActive && isCurrentUserWinner)
                                const Icon(Icons.payment, size: 20),
                              if (!isAuctionActive && isCurrentUserWinner)
                                const SizedBox(width: 8),
                              Text(
                                _getButtonText(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_remainingTime.inSeconds > 0) {
      return 'Place Bid';
    } else if (_winningUserId == FirebaseAuth.instance.currentUser?.uid) {
      return 'Pay Now';
    } else {
      return 'Auction Ended';
    }
  }

  Color _getButtonColor() {
    if (_remainingTime.inSeconds > 0) {
      return Colors.blue[700]!; // Active auction - blue for bidding
    } else if (_winningUserId == FirebaseAuth.instance.currentUser?.uid) {
      return Colors.blue[700]!; // Pay Now - blue
    } else {
      return Colors.grey[600]!; // Ended auction - grey
    }
  }

  VoidCallback? _getButtonAction() {
    if (_remainingTime.inSeconds > 0 && !_isLoading) {
      return _placeBid;
    } else if (_winningUserId == FirebaseAuth.instance.currentUser?.uid &&
        !_isLoading) {
      return _handlePayment;
    } else {
      return null; // Disable button if user is not the winner
    }
  }

  Widget _buildCertificateSection() {
    final certificates = widget.auction.gemCertificates as List?;
    if (certificates == null || certificates.isEmpty) {
      return const SizedBox.shrink();
    }

    final verificationStatus =
        widget.auction.certificateVerificationStatus ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.blue[700], size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gem Certificates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue[900],
                  ),
                ),
              ),
              _buildStatusBadge(verificationStatus),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: certificates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cert = certificates[index] as Map<String, dynamic>;
              final certUrl = cert['url'] ?? '';
              final fileName = cert['fileName'] ?? 'Certificate ${index + 1}';
              final type = cert['type'] ?? 'pdf';

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _showCertificateDetails(context, certUrl, type),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          type == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fileName,
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.visibility,
                          color: Colors.blue[400],
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'verified':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCertificateDetails(
      BuildContext context, String certUrl, String type) {
    if (type == 'pdf') {
      _showPDFViewer(context, certUrl);
    } else {
      _showImageViewer(context, certUrl);
    }
  }

  void _showPDFViewer(BuildContext context, String pdfUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.blue[700],
                title: const Text('Certificate PDF'),
                automaticallyImplyLeading: true,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 64, color: Colors.blue[700]),
                    const SizedBox(height: 16),
                    const Text('PDF Viewer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Tap the button below to open', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open PDF in browser/external app
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening certificate...')),
                        );
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open Certificate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.blue[700],
              title: const Text('Certificate Image'),
              automaticallyImplyLeading: true,
            ),
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
