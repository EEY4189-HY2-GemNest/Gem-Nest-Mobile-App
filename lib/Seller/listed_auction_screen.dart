import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListedAuctionScreen extends StatelessWidget {
  final String sellerId;

  const ListedAuctionScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    // Get current user ID for additional verification
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    print('Passed sellerId: $sellerId');
    print('Current Firebase user ID: $currentUserId');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        title: const Text(
          'Listed Auctions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('auctions')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 3,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gavel_outlined, color: Colors.white70, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'No auctions listed yet',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var auction = snapshot.data!.docs[index];
                Map<String, dynamic> auctionData =
                    auction.data() as Map<String, dynamic>;

                // Enhanced debugging
                print('Auction ID: ${auction.id}');
                print('Auction data: $auctionData');
                bool hasSellerId = auctionData.containsKey('sellerId');
                print('Has sellerId field: $hasSellerId');
                if (hasSellerId) {
                  print('Auction sellerId: ${auctionData['sellerId']}');
                }

                bool isSeller =
                    hasSellerId && auctionData['sellerId'] == sellerId;
                print('isSeller for ${auction.id}: $isSeller');

                return AuctionCard(
                  title: auctionData['title'] ?? 'Untitled',
                  currentBid: auctionData['currentBid']?.toString() ?? '0',
                  endTime: DateTime.parse(auctionData['endTime'] ??
                      DateTime.now().toIso8601String()),
                  imageUrl: auctionData['imagePath'] ?? '',
                  minimumIncrement:
                      auctionData['minimumIncrement']?.toString() ?? '0',
                  auctionId: auction.id,
                  isSeller: isSeller,
                  onTap: () {
                    // Add navigation to detail screen if needed
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AuctionCard extends StatelessWidget {
  final String title;
  final String currentBid;
  final DateTime endTime;
  final String imageUrl;
  final String minimumIncrement;
  final VoidCallback onTap;
  final String auctionId;
  final bool isSeller;

  const AuctionCard({
    super.key,
    required this.title,
    required this.currentBid,
    required this.endTime,
    required this.imageUrl,
    required this.minimumIncrement,
    required this.onTap,
    required this.auctionId,
    required this.isSeller,
  });

  String _formatEndTime(DateTime endTime) {
    return DateFormat('MMM d, yyyy - HH:mm').format(endTime.toLocal());
  }

  String _getTimeRemaining() {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    if (difference.isNegative) {
      return 'Ended';
    }
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    if (days > 0) {
      return '$days:${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  
