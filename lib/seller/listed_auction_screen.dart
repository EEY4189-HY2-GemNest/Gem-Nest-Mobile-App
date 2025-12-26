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
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
              setState(() => _statusFilter = value);
            },
            itemBuilder: (context) => [
              _buildFilterItem('all', 'All Auctions', Icons.list),
              _buildFilterItem(
                  'active', 'Active Auctions', Icons.play_circle_outline),
              _buildFilterItem(
                  'ended', 'Ended Auctions', Icons.stop_circle_outlined),
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
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No auctions listed yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final now = DateTime.now();

                  final filteredAuctions =
                      snapshot.data!.docs.where((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final endTime = DateTime.parse(
                        data['endTime'] ??
                            DateTime.now().toIso8601String());

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
                        style: const TextStyle(color: Colors.white70),
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
                              DateTime.now().toIso8601String());

                      final isSeller =
                          data['sellerId'] == widget.sellerId;

                      return AuctionCard(
                        title: data['title'] ?? 'Untitled',
                        currentBid:
                            data['currentBid']?.toString() ?? '0',
                        endTime: endTime,
                        imageUrl: data['imagePath'] ?? '',
                        minimumIncrement:
                            data['minimumIncrement']?.toString() ??
                                '0',
                        auctionId: auction.id,
                        isSeller: isSeller,
                        onTap: () {},
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  PopupMenuItem<String> _buildFilterItem(
      String value, String label, IconData icon) {
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

/* ===================== AUCTION CARD ===================== */

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

  String _formatEndTime() {
    return DateFormat('MMM d, yyyy - HH:mm')
        .format(endTime.toLocal());
  }

  String _getTimeRemaining() {
    final diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EditEndTimeDialog(
        auctionId: auctionId,
        currentEndTime: endTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageUrl.isEmpty
                ? const Icon(Icons.image,
                    color: Colors.white54)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Min Inc: Rs. $minimumIncrement',
                  style:
                      const TextStyle(color: Colors.blueAccent),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ends: ${_formatEndTime()}',
                  style:
                      const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs. $currentBid',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _getTimeRemaining(),
                          style: TextStyle(
                            color: endTime.isBefore(DateTime.now())
                                ? Colors.redAccent
                                : Colors.white70,
                          ),
                        ),
                        if (isSeller)
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () =>
                                _showEditDialog(context),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== EDIT END TIME DIALOG ===================== */

class EditEndTimeDialog extends StatefulWidget {
  final String auctionId;
  final DateTime currentEndTime;

  const EditEndTimeDialog({
    super.key,
    required this.auctionId,
    required this.currentEndTime,
  });

  @override
  State<EditEndTimeDialog> createState() =>
      _EditEndTimeDialogState();
}

class _EditEndTimeDialogState extends State<EditEndTimeDialog> {
  late DateTime selectedDateTime;

  @override
  void initState() {
    super.initState();
    selectedDateTime = widget.currentEndTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Edit End Time',
        style: TextStyle(color: Colors.white),
      ),
      content: Text(
        DateFormat('MMM d, yyyy - HH:mm')
            .format(selectedDateTime),
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
