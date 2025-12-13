import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemnest_mobile_app/models/auction_model.dart';

/// Optimized Auction Repository using efficient data structures
class AuctionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuctionCache _cache = AuctionCache();

  // Firestore collection reference
  CollectionReference get _auctionsCollection =>
      _firestore.collection('auctions');

  /// Fetch all auctions with efficient filtering
  /// Time Complexity: O(n) for filtering + O(n log n) for sorting
  Stream<List<Auction>> getAuctionsStream({
    String? category,
    String? status,
    double? minPrice,
    double? maxPrice,
  }) {
    Query query = _auctionsCollection;

    // Apply category filter - O(1) in Firestore
    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    // Apply price range filter - O(1) in Firestore
    if (minPrice != null) {
      query = query.where('currentBid', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      query = query.where('currentBid', isLessThanOrEqualTo: maxPrice);
    }

    return query.snapshots().map((snapshot) {
      final auctions = snapshot.docs
          .map((doc) => Auction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Client-side filtering for status
      final filtered = _filterByStatus(auctions, status);

      // Sort by endTime (soonest first) - O(n log n)
      filtered.sort((a, b) => a.endTime.compareTo(b.endTime));

      // Cache auctions
      for (var auction in filtered) {
        _cache.add(auction);
      }

      return filtered;
    });
  }

  /// Get single auction by ID - O(1) from cache, O(1) from Firestore
  Future<Auction?> getAuctionById(String auctionId) async {
    // Check cache first - O(1)
    if (_cache.contains(auctionId)) {
      return _cache.get(auctionId);
    }

    try {
      final doc = await _auctionsCollection.doc(auctionId).get();
      if (doc.exists) {
        final auction =
            Auction.fromMap(doc.data() as Map<String, dynamic>);
        _cache.add(auction);
        return auction;
      }
    } catch (e) {
      print('Error fetching auction: $e');
    }
    return null;
  }

  /// Search auctions by keyword - O(n) linear search with caching
  Stream<List<Auction>> searchAuctions(String query) {
    final lowerQuery = query.toLowerCase();

    return _auctionsCollection.snapshots().map((snapshot) {
      final results = snapshot.docs
          .map((doc) => Auction.fromMap(doc.data() as Map<String, dynamic>))
          .where((auction) {
            return auction.title.toLowerCase().contains(lowerQuery) ||
                auction.description.toLowerCase().contains(lowerQuery);
          })
          .toList();

      // Sort by relevance (title match first) - O(n log n)
      results.sort((a, b) {
        final aMatches = a.title.toLowerCase().contains(lowerQuery) ? 1 : 0;
        final bMatches = b.title.toLowerCase().contains(lowerQuery) ? 1 : 0;
        return bMatches.compareTo(aMatches);
      });

      return results;
    });
  }

  /// Get active auctions sorted by end time - O(n log n)
  Stream<List<Auction>> getActiveAuctions() {
    final now = DateTime.now();

    return _auctionsCollection.snapshots().map((snapshot) {
      final auctions = snapshot.docs
          .map((doc) => Auction.fromMap(doc.data() as Map<String, dynamic>))
          .where((auction) => auction.isActive)
          .toList();

      // Sort by time remaining (soonest ending first)
      auctions.sort(
          (a, b) => a.timeRemaining.compareTo(b.timeRemaining));

      return auctions;
    });
  }

  /// Get auctions expiring soon - O(n log n) with min heap concept
  Stream<List<Auction>> getAuctionsExpiringIn(Duration duration) {
    final now = DateTime.now();
    final deadline = now.add(duration);

    return _auctionsCollection.snapshots().map((snapshot) {
      final auctions = snapshot.docs
          .map((doc) => Auction.fromMap(doc.data() as Map<String, dynamic>))
          .where((auction) {
            return auction.isActive &&
                auction.endTime.isBefore(deadline);
          })
          .toList();

      // Sort by endTime ascending (soonest first)
      auctions.sort((a, b) => a.endTime.compareTo(b.endTime));

      return auctions;
    });
  }

  /// Get top auctions by bid amount - O(n) with single pass
  Future<List<Auction>> getTopAuctionsByBids({int limit = 10}) async {
    try {
      final snapshot = await _auctionsCollection
          .orderBy('currentBid', descending: true)
          .limit(limit)
          .get();

      final auctions = snapshot.docs
          .map((doc) => Auction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      for (var auction in auctions) {
        _cache.add(auction);
      }

      return auctions;
    } catch (e) {
      print('Error fetching top auctions: $e');
      return [];
    }
  }

  /// Place a bid - O(log n) for array insertion
  Future<bool> placeBid(
    String auctionId,
    String bidderId,
    String bidderName,
    double bidAmount,
  ) async {
    try {
      final auctionDoc = _auctionsCollection.doc(auctionId);
      final snapshot = await auctionDoc.get();

      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>;
      final auction = Auction.fromMap(data);

      // Validate bid
      if (bidAmount <= auction.currentBid) {
        return false;
      }

      // Create new bid
      final newBid = Bid(
        bidderId: bidderId,
        bidAmount: bidAmount,
        timestamp: DateTime.now(),
        bidderName: bidderName,
      );

      // Update auction with new bid - O(log n)
      final updatedBids = List<dynamic>.from(data['bidHistory'] ?? []);
      updatedBids.add(newBid.toMap());

      await auctionDoc.update({
        'currentBid': bidAmount,
        'bidHistory': updatedBids,
        'totalBids': updatedBids.length,
        'winningUserId': bidderId,
      });

      // Update cache
      auction.currentBid = bidAmount;
      auction.winningUserId = bidderId;
      _cache.update(auctionId, auction);

      return true;
    } catch (e) {
      print('Error placing bid: $e');
      return false;
    }
  }

  /// Get bid history for an auction - O(1) retrieval
  Future<List<Bid>> getBidHistory(String auctionId) async {
    try {
      final auction = await getAuctionById(auctionId);
      if (auction != null) {
        // Return bids sorted by timestamp (newest first)
        final bids = List<Bid>.from(auction.bidHistory);
        bids.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return bids;
      }
    } catch (e) {
      print('Error fetching bid history: $e');
    }
    return [];
  }

  /// Filter auctions by status - O(n)
  List<Auction> _filterByStatus(List<Auction> auctions, String? status) {
    if (status == null || status == 'all') {
      return auctions;
    }

    return auctions.where((auction) {
      switch (status) {
        case 'live':
          return auction.isActive;
        case 'ended':
          return !auction.isActive;
        default:
          return true;
      }
    }).toList();
  }

  /// Get auctions by category - O(n) with filtering
  Stream<List<Auction>> getAuctionsByCategory(String category) {
    return _auctionsCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final auctions = snapshot.docs
          .map((doc) => Auction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by end time
      auctions.sort((a, b) => a.endTime.compareTo(b.endTime));

      return auctions;
    });
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Get cache size
  int getCacheSize() {
    return _cache.size;
  }
}
