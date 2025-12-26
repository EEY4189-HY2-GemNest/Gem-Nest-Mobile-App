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
              _buildFilterItem(
                value: 'all',
                label: 'All Auctions',
                icon: Icons.list,
              ),
              _buildFilterItem(
                value: 'active',
                label: 'Active Auctions',
                icon: Icons.play_circle_outline,
              ),
              _buildFilterItem(
                value: 'ended',
                label: 'Ended Auctions',
                icon: Icons.stop_circle_outlined,
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: currentUserId == null
            ? const Center(
                child: Text(
                  'User not logged in',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('auctions')
                    .where('sellerId', isEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No auctions listed yet',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  final now = DateTime.now();

                  /// Filter auctions based on selected status
                  final filteredAuctions =
                      snapshot.data!.docs.where((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final endTime = DateTime.parse(
                      data['endTime'] ??
                          DateTime.now().toIso8601String(),
                    );

                    if (_statusFilter == 'active') {
                      return endTime.isAfter(now);
                    } else if (_statusFilter == 'ended') {
                      return endTime.isBefore(now);
                    }
                    return true;
                  }).toList();

                  if (filteredAuctions.isEmpty) {
                    return Center(
                      child: Text(
                        'No $_statusFilter auctions found',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAuctions.length,
                    itemBuilder: (context, index) {
                      final auction = filteredAuctions[index];
                      final data =
                          auction.data() as Map<String, dynamic>;

                      final endTime = DateTime.parse(
                        data['endTime'] ??
                            DateTime.now().toIso8601String(),
                      );

                      return Card(
                        color: Colors.grey[900],
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            data['title'] ?? 'Untitled Auction',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Ends: ${DateFormat('MMM d, yyyy - HH:mm').format(endTime)}',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          trailing: Text(
                            'Rs. ${data['currentBid'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  /// Helper for popup menu items
  PopupMenuItem<String> _buildFilterItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _statusFilter == value;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color:
                isSelected ? Colors.blueAccent : Colors.white70,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color:
                  isSelected ? Colors.blueAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class AuctionCard extends StatelessWidget {
  final String title;

  const AuctionCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(title, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

String formatEndTime(DateTime endTime) {
  return DateFormat('MMM d, yyyy - HH:mm').format(endTime);
}

