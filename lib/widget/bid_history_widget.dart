import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A reusable widget that displays bid history for an auction.
///
/// - **Seller view** (`isSeller: true`): shows bidder full name (or email if
///   name is empty).
/// - **Buyer view** (`isSeller: false`): shows masked names/emails
///   (first 2 chars + ***** + last 2 chars).
class BidHistoryWidget extends StatelessWidget {
  final String auctionId;
  final bool isSeller;

  const BidHistoryWidget({
    super.key,
    required this.auctionId,
    this.isSeller = false,
  });

  // ---------------------------------------------------------------------------
  // Name / email masking helpers
  // ---------------------------------------------------------------------------

  /// Masks a string: first 2 chars + ***** + last 2 chars.
  /// If the string is 4 characters or shorter it shows first char + *****.
  static String maskIdentity(String value) {
    if (value.isEmpty) return 'Unknown';
    if (value.length <= 4) {
      return '${value.substring(0, 1)}*****';
    }
    final first = value.substring(0, 2);
    final last = value.substring(value.length - 2);
    return '$first*****$last';
  }

  /// Returns the display name for a bid entry, applying masking rules for
  /// buyers and showing full names for sellers.
  static String getDisplayName(
    Map<String, dynamic> bid, {
    required bool isSeller,
  }) {
    final name = (bid['bidderName'] ?? '').toString().trim();
    final email = (bid['bidderEmail'] ?? '').toString().trim();

    if (isSeller) {
      // Seller: show full name, fallback to email, then fallback label
      if (name.isNotEmpty && name != 'Unknown') return name;
      if (email.isNotEmpty) return email;
      return 'Unknown Bidder';
    } else {
      // Buyer: mask name / email
      if (name.isNotEmpty && name != 'Unknown') return maskIdentity(name);
      if (email.isNotEmpty) return maskIdentity(email);
      return 'An*****er';
    }
  }

  // ---------------------------------------------------------------------------
  // Bottom-sheet launcher (can be called from anywhere)
  // ---------------------------------------------------------------------------

  /// Opens a draggable bottom sheet showing the bid history.
  static void showBidHistorySheet(
    BuildContext context,
    String auctionId, {
    required bool isSeller,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Bid History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Bid list
              Expanded(
                child: BidHistoryWidget(
                  auctionId: auctionId,
                  isSeller: isSeller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('auctions')
          .doc(auctionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No auction data available'),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bidHistory = (data['bidHistory'] as List<dynamic>?) ?? [];

        if (bidHistory.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No bids yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Sort bids: highest amount first
        final sortedBids = List<Map<String, dynamic>>.from(
          bidHistory.map((b) => Map<String, dynamic>.from(b as Map)),
        )..sort((a, b) => ((b['bidAmount'] ?? 0) as num)
            .compareTo((a['bidAmount'] ?? 0) as num));

        return ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sortedBids.length,
          itemBuilder: (context, index) {
            final bid = sortedBids[index];
            final isHighest = index == 0;
            return _buildBidTile(bid, isHighest, index + 1);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Single bid tile
  // ---------------------------------------------------------------------------

  Widget _buildBidTile(Map<String, dynamic> bid, bool isHighest, int rank) {
    final displayName = getDisplayName(bid, isSeller: isSeller);
    final amount = (bid['bidAmount'] as num?)?.toDouble() ?? 0;

    // Parse timestamp
    String timeStr = '';
    try {
      if (bid['timestamp'] is Timestamp) {
        final dt = (bid['timestamp'] as Timestamp).toDate();
        timeStr = DateFormat('MMM d, yyyy – HH:mm').format(dt);
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighest ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighest ? Colors.green[300]! : Colors.grey[200]!,
          width: isHighest ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isHighest
                  ? [Colors.green[400]!, Colors.green[600]!]
                  : [Colors.blue[300]!, Colors.blue[500]!],
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontWeight: isHighest ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        subtitle: timeStr.isNotEmpty
            ? Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs. ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isHighest ? Colors.green[700] : Colors.blue[700],
              ),
            ),
            if (isHighest)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HIGHEST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
