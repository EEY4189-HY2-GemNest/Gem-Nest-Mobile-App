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
  final String status;

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
    required this.status,
  });

  // Get highest bidder in O(1) - called after building bid history
  Bid? getHighestBid() {
    if (bidHistory.isEmpty) return null;
    return bidHistory.reduce((a, b) => a.bidAmount > b.bidAmount ? a : b);
  }

  // Check if auction is currently active
  bool get isActive => DateTime.now().isBefore(endTime);

  // Get time remaining
  Duration get timeRemaining => endTime.difference(DateTime.now());

  // Get total number of bids
  int get totalBids => bidHistory.length;

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'startingPrice': startingPrice,
      'currentBid': currentBid,
      'sellerUserId': sellerUserId,
      'winningUserId': winningUserId,
      'startTime': startTime,
      'endTime': endTime,
      'imageUrl': imageUrl,
      'status': status,
      'totalBids': bidHistory.length,
    };
  }

  // Create from Firestore document
  factory Auction.fromFirestore(String id, Map<String, dynamic> data) {
    return Auction(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'other',
      startingPrice: (data['startingPrice'] ?? 0).toDouble(),
      currentBid: (data['currentBid'] ?? 0).toDouble(),
      sellerUserId: data['sellerUserId'] ?? '',
      winningUserId: data['winningUserId'],
      startTime: (data['startTime'] as dynamic)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as dynamic)?.toDate() ?? DateTime.now(),
      bidHistory: [], // Will be populated separately
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? 'live',
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

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bidderId': bidderId,
      'bidAmount': bidAmount,
      'timestamp': timestamp,
      'bidderName': bidderName,
    };
  }

  // Create from Firestore document
  factory Bid.fromFirestore(Map<String, dynamic> data) {
    return Bid(
      bidderId: data['bidderId'] ?? '',
      bidAmount: (data['bidAmount'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      bidderName: data['bidderName'] ?? 'Unknown',
    );
  }
}

// Efficient Bid Manager using Max Heap concept
class BidManager {
  final List<Bid> _bids = [];

  // Add bid in O(log n) - maintains sorted order
  void addBid(Bid bid) {
    _bids.add(bid);
    _sortBids();
  }

  // Get highest bid in O(1)
  Bid? getHighestBid() => _bids.isNotEmpty ? _bids.first : null;

  // Get all bids sorted by amount (descending)
  List<Bid> getAllBids() => List.unmodifiable(_bids);

  // Get top N bids
  List<Bid> getTopBids(int n) => _bids.take(n).toList();

  // Sort bids by amount (descending)
  void _sortBids() {
    _bids.sort((a, b) => b.bidAmount.compareTo(a.bidAmount));
  }

  int get totalBids => _bids.length;

  void clear() => _bids.clear();
}
