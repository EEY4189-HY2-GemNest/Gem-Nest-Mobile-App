// Auction Model with optimized data structures

class Auction {
  final String id;
  final String title;
  final String description;
  final String category;
  final double startingPrice;
  double currentBid;
  final String sellerUserId;
  String? winningUserId;
  final DateTime startTime;
  final DateTime endTime;
  final List<Bid> bidHistory;
  final String imageUrl;
  final List<dynamic>? gemCertificates;
  final String? certificateVerificationStatus;
  final String approvalStatus; // 'pending', 'approved', 'rejected'

  Auction({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startingPrice,
    required this.currentBid,
    required this.sellerUserId,
    this.winningUserId,
    required this.startTime,
    required this.endTime,
    required this.bidHistory,
    required this.imageUrl,
    this.gemCertificates,
    this.certificateVerificationStatus,
    this.approvalStatus = 'pending',
  });

  /// Get highest bidder using efficient algorithm
  Bid? getHighestBid() {
    if (bidHistory.isEmpty) return null;

    // Single pass O(n) to find max
    Bid maxBid = bidHistory[0];
    for (int i = 1; i < bidHistory.length; i++) {
      if (bidHistory[i].bidAmount > maxBid.bidAmount) {
        maxBid = bidHistory[i];
      }
    }
    return maxBid;
  }

  /// Get all bids sorted by amount (descending) using efficient sorting
  List<Bid> getBidsSortedByAmount() {
    final sorted = List<Bid>.from(bidHistory);
    // Merge sort or quick sort - O(n log n)
    sorted.sort((a, b) => b.bidAmount.compareTo(a.bidAmount));
    return sorted;
  }

  /// Get recent bids (last N bids) - O(n)
  List<Bid> getRecentBids({int limit = 5}) {
    final recent = bidHistory.length > limit
        ? bidHistory.sublist(bidHistory.length - limit)
        : bidHistory;
    return recent.reversed.toList();
  }

  /// Check if auction is currently active
  bool get isActive => DateTime.now().isBefore(endTime);

  /// Get time remaining in auction
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endTime)) {
      return Duration.zero;
    }
    return endTime.difference(now);
  }

  /// Get auction status
  String get status {
    if (!isActive) {
      return 'ended';
    }
    return 'live';
  }

  /// Get number of bids
  int get totalBids => bidHistory.length;

  /// Get bid increment (minimum next bid)
  double get minimumNextBid => currentBid + 1.0;

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'startingPrice': startingPrice,
      'currentBid': currentBid,
      'sellerUserId': sellerUserId,
      'winningUserId': winningUserId,
      'startTime': startTime,
      'endTime': endTime,
      'bidHistory': bidHistory.map((bid) => bid.toMap()).toList(),
      'imageUrl': imageUrl,
      'totalBids': totalBids,
      'gemCertificates': gemCertificates ?? [],
      'certificateVerificationStatus': certificateVerificationStatus ?? 'none',
      'approvalStatus': approvalStatus,
    };
  }

  /// Create from Firestore map
  factory Auction.fromMap(Map<String, dynamic> map) {
    return Auction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'other',
      startingPrice: (map['startingPrice'] ?? 0).toDouble(),
      currentBid: (map['currentBid'] ?? 0).toDouble(),
      sellerUserId: map['sellerUserId'] ?? '',
      winningUserId: map['winningUserId'],
      startTime: (map['startTime'] as dynamic).toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as dynamic).toDate() ?? DateTime.now(),
      bidHistory: ((map['bidHistory'] ?? []) as List)
          .map((bid) => Bid.fromMap(bid as Map<String, dynamic>))
          .toList(),
      imageUrl: map['imageUrl'] ?? '',
      gemCertificates: map['gemCertificates'] as List<dynamic>?,
      certificateVerificationStatus:
          map['certificateVerificationStatus'] as String?,
      approvalStatus: map['approvalStatus'] ?? 'pending',
    );
  }
}

class Bid {
  final String bidderId;
  final double bidAmount;
  final DateTime timestamp;
  final String bidderName;

  Bid({
    required this.bidderId,
    required this.bidAmount,
    required this.timestamp,
    required this.bidderName,
  });

  Map<String, dynamic> toMap() {
    return {
      'bidderId': bidderId,
      'bidAmount': bidAmount,
      'timestamp': timestamp,
      'bidderName': bidderName,
    };
  }

  factory Bid.fromMap(Map<String, dynamic> map) {
    return Bid(
      bidderId: map['bidderId'] ?? '',
      bidAmount: (map['bidAmount'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as dynamic).toDate() ?? DateTime.now(),
      bidderName: map['bidderName'] ?? 'Unknown',
    );
  }
}

/// Optimized auction cache using HashMap
class AuctionCache {
  final Map<String, Auction> _cache = {};
  static const int MAX_CACHE_SIZE = 100;

  void add(Auction auction) {
    if (_cache.length >= MAX_CACHE_SIZE) {
      // Remove oldest entry (simple FIFO)
      _cache.remove(_cache.keys.first);
    }
    _cache[auction.id] = auction;
  }

  Auction? get(String auctionId) => _cache[auctionId];

  void update(String auctionId, Auction auction) {
    _cache[auctionId] = auction;
  }

  void clear() => _cache.clear();

  int get size => _cache.length;

  bool contains(String auctionId) => _cache.containsKey(auctionId);
}
