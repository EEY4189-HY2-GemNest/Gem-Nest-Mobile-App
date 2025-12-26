import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListedAuctionScreen extends StatefulWidget {
  final String sellerId;

  const ListedAuctionScreen({super.key, required this.sellerId});

  @override
  State<ListedAuctionScreen> createState() => _ListedAuctionScreenState();
}

class _ListedAuctionScreenState extends State<ListedAuctionScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Listed Auctions',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _ListedAuctionScreenState extends State<ListedAuctionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    print('Passed sellerId: ${widget.sellerId}');
    print('Current Firebase user ID: $currentUserId');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
            ),
          ),
        ),
        title: const Text(
          'Listed Auctions',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
    );
  }
}
