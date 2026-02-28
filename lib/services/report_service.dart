import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/report_model.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get collection reference
  CollectionReference get _reportsCollection =>
      _firestore.collection('reports');

  /// Get current user info
  Future<Map<String, dynamic>> _getCurrentUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String userName = 'User';
    String userEmail = user.email ?? '';
    String userRole = 'buyer';

    // Try to fetch from buyers collection
    try {
      final buyerDoc =
          await _firestore.collection('buyers').doc(user.uid).get();
      if (buyerDoc.exists) {
        final data = buyerDoc.data() as Map<String, dynamic>;
        userName = data['displayName'] ?? data['name'] ?? 'User';
        userEmail = data['email'] ?? userEmail;
        userRole = 'buyer';
      } else {
        // Try sellers collection
        final sellerDoc =
            await _firestore.collection('sellers').doc(user.uid).get();
        if (sellerDoc.exists) {
          final data = sellerDoc.data() as Map<String, dynamic>;
          userName = data['displayName'] ?? data['name'] ?? 'User';
          userEmail = data['email'] ?? userEmail;
          userRole = 'seller';
        } else {
          // Try users collection
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            userName = data['displayName'] ?? data['name'] ?? 'User';
            userEmail = data['email'] ?? userEmail;
            userRole = data['role'] ?? 'buyer';
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }

    return {
      'uid': user.uid,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
    };
  }

  /// Submit a new report
  Future<String> submitReport({
    required String subject,
    required String description,
    required ReportCategory category,
    required ReportPriority priority,
    List<File> images = const [],
    String? orderId,
    String? productId,
    String? auctionId,
    String? overrideRole,
  }) async {
    try {
      final userInfo = await _getCurrentUserInfo();
      final now = DateTime.now();

      // Upload images if any
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final ref = _storage.ref().child(
              'report_images/${userInfo['uid']}/${now.millisecondsSinceEpoch}_$i.jpg');
          await ref.putFile(images[i]);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      final report = ReportProblem(
        id: '',
        userId: userInfo['uid'],
        userName: userInfo['userName'],
        userEmail: userInfo['userEmail'],
        userRole: overrideRole ?? userInfo['userRole'],
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        status: ReportStatus.submitted,
        imageUrls: imageUrls,
        orderId: orderId,
        productId: productId,
        auctionId: auctionId,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _reportsCollection.add(report.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting report: $e');
      rethrow;
    }
  }

  /// Get reports for current user (stream)
  Stream<List<ReportProblem>> getUserReports({String? roleFilter}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _reportsCollection.where('userId', isEqualTo: user.uid);

    return query.snapshots().map((snapshot) {
      List<ReportProblem> reports = snapshot.docs
          .map((doc) => ReportProblem.fromFirestore(doc))
          .toList();

      // Filter by role client-side to avoid composite index requirement
      if (roleFilter != null) {
        reports = reports.where((r) => r.userRole == roleFilter).toList();
      }

      // Sort client-side by createdAt descending
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  /// Get a single report by ID (stream)
  Stream<ReportProblem?> getReportById(String reportId) {
    return _reportsCollection.doc(reportId).snapshots().map((doc) {
      if (doc.exists) {
        return ReportProblem.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get all reports (for admin)
  Stream<List<ReportProblem>> getAllReports({
    ReportStatus? statusFilter,
    String? roleFilter,
    String? categoryFilter,
  }) {
    Query query = _reportsCollection.orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.value);
    }

    if (roleFilter != null) {
      query = query.where('userRole', isEqualTo: roleFilter);
    }

    if (categoryFilter != null) {
      query = query.where('category', isEqualTo: categoryFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportProblem.fromFirestore(doc))
          .toList();
    });
  }

  /// Update report status (admin)
  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    await _reportsCollection.doc(reportId).update({
      'status': status.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Add admin response
  Future<void> addAdminResponse(
      String reportId, String message, String adminName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = AdminResponse(
      adminId: user.uid,
      adminName: adminName,
      message: message,
      respondedAt: DateTime.now(),
    );

    await _reportsCollection.doc(reportId).update({
      'adminResponses': FieldValue.arrayUnion([response.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Set admin solution & optionally update status
  Future<void> setAdminSolution(
      String reportId, String solution, ReportStatus newStatus) async {
    await _reportsCollection.doc(reportId).update({
      'adminSolution': solution,
      'status': newStatus.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get report counts by status (for admin dashboard)
  Future<Map<String, int>> getReportCounts() async {
    final snapshot = await _reportsCollection.get();
    final Map<String, int> counts = {
      'total': 0,
      'submitted': 0,
      'review': 0,
      'inProgress': 0,
      'done': 0,
      'rejected': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'submitted';
      counts['total'] = (counts['total'] ?? 0) + 1;
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }
}
