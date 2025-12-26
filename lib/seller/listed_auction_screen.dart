import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:intl/intl.dart';

class ListedAuctionScreen extends StatefulWidget {
  final String sellerId;

  const ListedAuctionScreen({super.key, required this.sellerId});

  @override
  State<ListedAuctionScreen> createState() => _ListedAuctionScreenState();
}

class _ListedAuctionScreenState extends State<ListedAuctionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Auction filter state: all | active | ended
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    // Debug logs
    print('Passed sellerId: ${widget.sellerId}');
    print('Current Firebase user ID: $currentUserId');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black26,
        centerTitle: true,
        leading: const ProfessionalAppBarBackButton(),
        title: const Text(
          'Listed Auctions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            color: Colors.grey[850],
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: _statusFilter == 'all'
                          ? Colors.blueAccent
                          : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Auctions',
                      style: TextStyle(
                        color: _statusFilter == 'all'
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'active',
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: _statusFilter == 'active'
                          ? Colors.blueAccent
                          : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Auctions',
                      style: TextStyle(
                        color: _statusFilter == 'active'
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ended',
                child: Row(
                  children: [
                    Icon(
                      Icons.stop_circle_outlined,
                      color: _statusFilter == 'ended'
                          ? Colors.blueAccent
                          : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ended Auctions',
                      style: TextStyle(
                        color: _statusFilter == 'ended'
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Auction list will be displayed here',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
