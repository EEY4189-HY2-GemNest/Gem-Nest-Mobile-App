import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BannerData {
  final String id;
  final String imageUrl;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  BannerData({
    required this.id,
    required this.imageUrl,
    this.endDate,
    required this.isActive,
    required this.createdAt,
  });

  factory BannerData.fromFirestore(Map<String, dynamic> data, String docId) {
    return BannerData(
      id: docId,
      imageUrl: data['imageUrl'] ?? '',
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class BannerProvider extends ChangeNotifier {
  List<BannerData> _bannerList = [];
  List<String> _bannerImageUrls = [];
  bool _isLoading = false;
  String? _error;

  List<BannerData> get bannerList => _bannerList;
  List<String> get bannerImageUrls => _bannerImageUrls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBannerImages() async {
    _isLoading = true;
    notifyListeners();
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('banners')
          .orderBy('createdAt', descending: true)
          .get();

      _bannerList = snapshot.docs
          .map((doc) => BannerData.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .where((banner) => banner.isActive == true)
          .toList();

      // Filter out expired banners
      DateTime now = DateTime.now();
      _bannerList = _bannerList.where((banner) {
        if (banner.endDate != null && banner.endDate!.isBefore(now)) {
          return false;
        }
        return true;
      }).toList();

      _bannerImageUrls = _bannerList.map((banner) => banner.imageUrl).toList();
      _error = null;
    } catch (e) {
      print('Banner fetch error: $e');
      _error = 'Failed to load banners';
    }
    _isLoading = false;
    notifyListeners();
  }
}
