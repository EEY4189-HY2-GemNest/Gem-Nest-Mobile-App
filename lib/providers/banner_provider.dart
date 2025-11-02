import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerProvider extends ChangeNotifier {
  List<String> _bannerList = [];
  bool _isLoading = false;
  String? _error;

  List<String> get bannerList => _bannerList;
  bool get isLoading => _isLoading;
  String? get error => _error;


}
