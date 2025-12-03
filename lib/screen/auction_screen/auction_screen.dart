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

  
}
