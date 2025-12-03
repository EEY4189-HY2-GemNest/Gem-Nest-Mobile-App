// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/auction_screen/auction_payment_screen.dart';

class AuctionScreen extends StatelessWidget {
  const AuctionScreen({super.key});

  DateTime _parseEndTime(dynamic endTime) {
    if (endTime is Timestamp) {
      return endTime.toDate();
    } else if (endTime is String) {
      try {
        return DateTime.parse(endTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Luxury Auction',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 26,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auctions')
            .orderBy('endTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final auctions = snapshot.data!.docs;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;

          // Separate auctions into won, ongoing, and ended
          final now = DateTime.now();
          final wonAuctions = auctions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final endTime = _parseEndTime(data['endTime']);
            return endTime.isBefore(now) &&
                data['winningUserId'] == currentUserId;
          }).toList();

          final ongoingAuctions = auctions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final endTime = _parseEndTime(data['endTime']);
            return endTime.isAfter(now);
          }).toList();

          final endedAuctions = auctions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final endTime = _parseEndTime(data['endTime']);
            return endTime.isBefore(now) &&
                data['winningUserId'] != currentUserId;
          }).toList();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: ListView(
              children: [
                // Won Auctions Section
                if (wonAuctions.isNotEmpty) ...[
                  const Text(
                    'Your Won Auctions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...wonAuctions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: AuctionItemCard(
                        auctionId: doc.id,
                        imagePath: data['imagePath'] ?? '',
                        title: data['title'] ?? 'Untitled',
                        currentBid:
                            (data['currentBid'] as num?)?.toDouble() ?? 0.0,
                        endTime: _parseEndTime(data['endTime']),
                        minimumIncrement:
                            (data['minimumIncrement'] as num?)?.toDouble() ??
                                0.0,
                        paymentStatus: data['paymentStatus'] ??
                            'pending', // Pass payment status
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Ongoing Auctions Section
                if (ongoingAuctions.isNotEmpty) ...[
                  const Text(
                    'Live Bidding',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ongoingAuctions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: AuctionItemCard(
                        auctionId: doc.id,
                        imagePath: data['imagePath'] ?? '',
                        title: data['title'] ?? 'Untitled',
                        currentBid:
                            (data['currentBid'] as num?)?.toDouble() ?? 0.0,
                        endTime: _parseEndTime(data['endTime']),
                        minimumIncrement:
                            (data['minimumIncrement'] as num?)?.toDouble() ??
                                0.0,
                        paymentStatus: data['paymentStatus'] ??
                            'pending', // Pass payment status
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Ended Auctions Section
                if (endedAuctions.isNotEmpty) ...[
                  const Text(
                    'Ended Auctions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...endedAuctions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: AuctionItemCard(
                        auctionId: doc.id,
                        imagePath: data['imagePath'] ?? '',
                        title: data['title'] ?? 'Untitled',
                        currentBid:
                            (data['currentBid'] as num?)?.toDouble() ?? 0.0,
                        endTime: _parseEndTime(data['endTime']),
                        minimumIncrement:
                            (data['minimumIncrement'] as num?)?.toDouble() ??
                                0.0,
                        paymentStatus: data['paymentStatus'] ??
                            'pending', // Pass payment status
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class AuctionItemCard extends StatefulWidget {
  final String auctionId;
  final String imagePath;
  final String title;
  final double currentBid;
  final DateTime endTime;
  final double minimumIncrement;
  final String paymentStatus; // Add paymentStatus field

  const AuctionItemCard({
    super.key,
    required this.auctionId,
    required this.imagePath,
    required this.title,
    required this.currentBid,
    required this.endTime,
    required this.minimumIncrement,
    required this.paymentStatus,
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
    _currentBid = widget.currentBid;
    _remainingTime = widget.endTime.difference(DateTime.now());
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
        .doc(widget.auctionId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentBid =
              (data['currentBid'] as num?)?.toDouble() ?? widget.currentBid;
          _winningUserId = data['winningUserId'];
        });
        if (data['currentBid'] > widget.currentBid) {
          _animationController.forward(from: 0.0);
        }
      }
    }, onError: (error) {
      print("Realtime listener error: $error");
    });
  }

  void _updateTime(Timer timer) {
    final now = DateTime.now();
    if (widget.endTime.isAfter(now)) {
      setState(() {
        _remainingTime = widget.endTime.difference(now);
      });
    } else {
      _timer.cancel();
    }
  }

  Future<void> _placeBid() async {
    final enteredBid = double.tryParse(_bidController.text.trim());
    final currentUser = FirebaseAuth.instance.currentUser;

    print("Current user UID: ${currentUser?.uid ?? 'Not authenticated'}");
    print("Auction ID: ${widget.auctionId}");
    print("Attempting bid: $enteredBid, Current bid: $_currentBid");

    if (currentUser == null) {
      _showSnackBar('Please log in to bid');
      return;
    }

    if (enteredBid == null) {
      _showSnackBar('Please enter a valid number');
      return;
    }

    if (widget.endTime.isBefore(DateTime.now())) {
      _showSnackBar('Auction has ended');
      return;
    }

    if (enteredBid <= _currentBid) {
      _showSnackBar('Bid must exceed current bid');
      return;
    }

    if ((enteredBid - _currentBid) < widget.minimumIncrement) {
      _showSnackBar(
          'Minimum increment: ${_formatCurrency(widget.minimumIncrement)}');
      return;
    }

    final docSnapshot = await FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auctionId)
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
        print(
            "Updating Firestore with: {currentBid: $enteredBid, winningUserId: ${currentUser.uid}}");
        await FirebaseFirestore.instance
            .collection('auctions')
            .doc(widget.auctionId)
            .update({
          'currentBid': enteredBid,
          'winningUserId': currentUser.uid,
          'lastBidTime': FieldValue.serverTimestamp(),
        });
        print("Bid update successful");
        setState(() {
          _currentBid = enteredBid;
          _winningUserId = currentUser.uid;
          _isLoading = false;
        });
        _bidController.clear();
        _showSnackBar('Bid placed successfully!');
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
    print("Auction ID: ${widget.auctionId}");

    if (currentUser == null) {
      _showSnackBar('Please log in to pay');
      return;
    }

    if (_winningUserId != currentUser.uid) {
      _showSnackBar('Only the winner can initiate payment');
      return;
    }

    if (widget.endTime.isAfter(DateTime.now())) {
      _showSnackBar('Auction is still active');
      return;
    }

    if (widget.paymentStatus == 'completed') {
      _showSnackBar('Payment already completed');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionPaymentScreen(
          auctionId: widget.auctionId,
          itemPrice: _currentBid,
          title: widget.title,
          imagePath: widget.imagePath,
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
    bool isPaymentCompleted = widget.paymentStatus == 'completed';

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
                  widget.imagePath.isNotEmpty
                      ? widget.imagePath
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
         
}
