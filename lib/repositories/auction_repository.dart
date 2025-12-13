import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemnest_mobile_app/models/auction_model.dart';

class AuctionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for active auctions using HashMap - O(1) lookup
  final Map<String, Auction> _auctionCache = {};

  // Index auctions by category - for fast filtering
  final Map<String, List<Auction>> _auctionsByCategory = {};

  // Index auctions by status - for quick status filtering
  final Map<String, List<Auction>> _auctionsByStatus = {};

  // Bid manager for efficient bid tracking
  final Map<String, BidManager> _bidManagers = {};

  /// Get auction stream with efficient filtering
  Stream<List<Auction>> getFilteredAuctions({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? status,
  }) {
    Query query = _firestore.collection('auctions');

    // Apply filters
    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    if (minPrice != null) {
      query = query.where('currentBid', isGreaterThanOrEqualTo: minPrice);
    }

    if (maxPrice != null) {
      query = query.where('currentBid', isLessThanOrEqualTo: maxPrice);
    }

    return query.snapshots().map((snapshot) {
      List<Auction> auctions = [];
      for (var doc in snapshot.docs) {
        final auction = Auction.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

        // Cache it
        _auctionCache[auction.id] = auction;

        // Apply status filter in-memory (more efficient than Firestore query)
        if (status == null ||
            status == 'all' ||
            _matchesStatus(auction, status)) {
          auctions.add(auction);
        }
      }

      // Sort by endTime (soonest ending first) - O(n log n)
      auctions.sort((a, b) => a.endTime.compareTo(b.endTime));

      return auctions;
    });
  }

  /// Get single auction with bid history
  Future<Auction?> getAuctionWithBids(String auctionId) async {
    try {
      // Check cache first - O(1)
      if (_auctionCache.containsKey(auctionId)) {
        return _auctionCache[auctionId];
      }

      // Fetch from Firestore
      final doc = await _firestore.collection('auctions').doc(auctionId).get();
      if (!doc.exists) return null;

      final auction = Auction.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );

      // Fetch bids and sort them
      final bidsSnapshot = await _firestore
          .collection('auctions')
          .doc(auctionId)
          .collection('bids')
          .orderBy('bidAmount', descending: true)
          .get();

      auction.bidHistory.clear();
      for (var bidDoc in bidsSnapshot.docs) {
        auction.bidHistory.add(
          Bid.fromFirestore(bidDoc.data()),
        );
      }

      // Cache it
      _auctionCache[auctionId] = auction;

      return auction;
    } catch (e) {
      print('Error fetching auction: $e');
      return null;
    }
  }

  /// Get auctions by category using index - O(1) lookup
  List<Auction> getAuctionsByCategory(String category) {
    return _auctionsByCategory[category] ?? [];
  }

  /// Search auctions by keyword - O(n) but optimized with early exit
  List<Auction> searchAuctions(String query, List<Auction> auctions) {
    final lowerQuery = query.toLowerCase();
    return auctions
        .where((auction) =>
            auction.title.toLowerCase().contains(lowerQuery) ||
            auction.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get top bids for an auction - O(1) with BidManager
  List<Bid> getTopBids(String auctionId, int count) {
    final bidManager = _bidManagers[auctionId];
    if (bidManager == null) return [];
    return bidManager.getTopBids(count);
  }

  /// Get highest bid for auction - O(1)
  Bid? getHighestBid(String auctionId) {
    return _bidManagers[auctionId]?.getHighestBid();
  }

  /// Add new bid - O(log n)
  Future<bool> placeBid({
    required String auctionId,
    required String bidderId,
    required String bidderName,
    required double bidAmount,
  }) async {
    try {
      final bid = Bid(
        bidderId: bidderId,
        bidAmount: bidAmount,
        timestamp: DateTime.now(),
        bidderName: bidderName,
      );

      // Add to Firestore
      await _firestore
          .collection('auctions')
          .doc(auctionId)
          .collection('bids')
          .add(bid.toFirestore());

      // Update auction's current bid
      await _firestore.collection('auctions').doc(auctionId).update({
        'currentBid': bidAmount,
        'winningUserId': bidderId,
      });

      // Update bid manager
      _bidManagers.putIfAbsent(auctionId, () => BidManager());
      _bidManagers[auctionId]!.addBid(bid);

      // Update cache
      if (_auctionCache.containsKey(auctionId)) {
        _auctionCache[auctionId]!.currentBid = bidAmount;
        _auctionCache[auctionId]!.winningUserId = bidderId;
        _auctionCache[auctionId]!.bidHistory.add(bid);
      }

      return true;
    } catch (e) {
      print('Error placing bid: $e');
      return false;
    }
  }

  /// Get auctions expiring soon - useful for notifications
  List<Auction> getExpiringAuctions(Duration within) {
    final now = DateTime.now();
    final threshold = now.add(within);

    return _auctionCache.values
        .where((auction) =>
            auction.isActive &&
            auction.endTime.isBefore(threshold) &&
            auction.endTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.endTime.compareTo(b.endTime));
  }

  /// Clear cache
  void clearCache() {
    _auctionCache.clear();
    _auctionsByCategory.clear();
    _auctionsByStatus.clear();
    _bidManagers.clear();
  }

  // Helper method to match auction status
  bool _matchesStatus(Auction auction, String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return auction.isActive;
      case 'ended':
        return !auction.isActive && auction.winningUserId == null;
      case 'won':
        return !auction.isActive && auction.winningUserId != null;
      default:
        return true;
    }
  }
}
