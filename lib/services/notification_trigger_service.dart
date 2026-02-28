import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/services/notification_service.dart';

/// Service for triggering notifications from the Flutter app side.
/// These notifications are saved to Firestore, which trigger Cloud Functions
/// to send FCM push notifications.
class NotificationTriggerService {
  static final NotificationTriggerService _instance =
      NotificationTriggerService._internal();
  factory NotificationTriggerService() => _instance;
  NotificationTriggerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // ========================================================================
  // REGISTRATION NOTIFICATIONS
  // ========================================================================

  /// Trigger welcome notification for a new buyer
  Future<void> triggerBuyerRegistrationNotification({
    required String userId,
    required String email,
  }) async {
    try {
      // Create welcome notification for the buyer
      await _notificationService.createNotification(
        userId: userId,
        title: '🎉 Welcome to GemNest!',
        body:
            'Your buyer account has been created successfully. Start exploring our gemstone collection!',
        type: 'welcomeRegistration',
        extraData: {'email': email},
      );

      // Also write trigger document for Cloud Function to send FCM
      await _firestore.collection('notification_triggers').add({
        'type': 'welcomeRegistration',
        'userId': userId,
        'email': email,
        'role': 'buyer',
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Buyer registration notification triggered for $userId');
    } catch (e) {
      debugPrint('Error triggering buyer registration notification: $e');
    }
  }

  /// Trigger seller registration pending notification
  Future<void> triggerSellerRegistrationNotification({
    required String userId,
    required String email,
    required String businessName,
  }) async {
    try {
      // Create pending notification for the seller
      await _notificationService.createNotification(
        userId: userId,
        title: '📋 Account Under Review',
        body:
            'Your seller account for "$businessName" has been submitted for review. We\'ll notify you once it\'s approved.',
        type: 'sellerRegistrationPending',
        extraData: {'email': email, 'businessName': businessName},
      );

      // Notify all admins about new seller registration
      await _notificationService.notifyAdmins(
        title: '👤 New Seller Registration',
        body: 'New seller "$businessName" ($email) needs account verification.',
        type: 'newSellerRegistration',
        actionUrl: 'admin/sellers',
        extraData: {
          'sellerId': userId,
          'email': email,
          'businessName': businessName,
        },
      );

      // Write trigger document for Cloud Function
      await _firestore.collection('notification_triggers').add({
        'type': 'sellerRegistrationPending',
        'userId': userId,
        'email': email,
        'businessName': businessName,
        'role': 'seller',
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Seller registration notification triggered for $userId');
    } catch (e) {
      debugPrint('Error triggering seller registration notification: $e');
    }
  }

  // ========================================================================
  // REPORT NOTIFICATIONS
  // ========================================================================

  /// Trigger notification when a report is submitted
  Future<void> triggerReportSubmittedNotification({
    required String reportId,
    required String subject,
    required String category,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Notify the user that report was submitted
      await _notificationService.createNotification(
        userId: currentUserId,
        title: '📝 Report Submitted',
        body:
            'Your report "$subject" has been submitted. We\'ll review it shortly.',
        type: 'reportSubmitted',
        extraData: {
          'reportId': reportId,
          'category': category,
        },
      );

      // Notify all admins
      await _notificationService.notifyAdmins(
        title: '🚨 New Report Submitted',
        body: 'New report: "$subject" (Category: $category) needs review.',
        type: 'newReportAdmin',
        actionUrl: 'admin/reports/$reportId',
        extraData: {
          'reportId': reportId,
          'reporterId': currentUserId,
          'category': category,
        },
      );

      // Write trigger document for Cloud Function
      await _firestore.collection('notification_triggers').add({
        'type': 'reportSubmitted',
        'reportId': reportId,
        'userId': currentUserId,
        'subject': subject,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Report submitted notification triggered for $reportId');
    } catch (e) {
      debugPrint('Error triggering report submitted notification: $e');
    }
  }

  /// Trigger notification when report status changes
  Future<void> triggerReportStatusChangeNotification({
    required String reportId,
    required String userId,
    required String newStatus,
    required String subject,
  }) async {
    try {
      String title;
      String body;

      switch (newStatus) {
        case 'review':
          title = '🔍 Report Under Review';
          body = 'Your report "$subject" is now being reviewed by our team.';
          break;
        case 'inProgress':
          title = '⚙️ Report In Progress';
          body =
              'Your report "$subject" is being processed. We\'re working on it.';
          break;
        case 'done':
          title = '✅ Report Resolved';
          body =
              'Your report "$subject" has been resolved. Check the response.';
          break;
        case 'rejected':
          title = '❌ Report Closed';
          body =
              'Your report "$subject" has been closed. Check the response for details.';
          break;
        default:
          title = '📋 Report Updated';
          body =
              'Your report "$subject" status has been updated to $newStatus.';
      }

      await _notificationService.createNotification(
        userId: userId,
        title: title,
        body: body,
        type: 'reportStatusChanged',
        extraData: {
          'reportId': reportId,
          'newStatus': newStatus,
        },
      );

      // Write trigger for Cloud Function
      await _firestore.collection('notification_triggers').add({
        'type': 'reportStatusChanged',
        'reportId': reportId,
        'userId': userId,
        'newStatus': newStatus,
        'subject': subject,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint(
          'Report status change notification triggered for $reportId -> $newStatus');
    } catch (e) {
      debugPrint('Error triggering report status change notification: $e');
    }
  }

  /// Trigger notification when admin responds to a report
  Future<void> triggerReportResponseNotification({
    required String reportId,
    required String userId,
    required String subject,
    required String adminName,
  }) async {
    try {
      await _notificationService.createNotification(
        userId: userId,
        title: '💬 Admin Response',
        body:
            '$adminName responded to your report "$subject". Check the details.',
        type: 'reportResponseAdded',
        extraData: {
          'reportId': reportId,
          'adminName': adminName,
        },
      );

      // Write trigger for Cloud Function
      await _firestore.collection('notification_triggers').add({
        'type': 'reportResponseAdded',
        'reportId': reportId,
        'userId': userId,
        'subject': subject,
        'adminName': adminName,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Report response notification triggered for $reportId');
    } catch (e) {
      debugPrint('Error triggering report response notification: $e');
    }
  }

  // ========================================================================
  // AUCTION BID REMINDER NOTIFICATIONS
  // ========================================================================

  /// Schedule a bid reminder notification (5 min before auction ends)
  /// This writes a trigger document that Cloud Functions will process
  Future<void> scheduleBidReminder({
    required String auctionId,
    required String auctionTitle,
    required DateTime endTime,
  }) async {
    try {
      final reminderTime = endTime.subtract(const Duration(minutes: 5));

      // Only schedule if the reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        await _firestore.collection('bid_reminders').doc(auctionId).set({
          'auctionId': auctionId,
          'auctionTitle': auctionTitle,
          'endTime': Timestamp.fromDate(endTime),
          'reminderTime': Timestamp.fromDate(reminderTime),
          'processed': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint(
            'Bid reminder scheduled for auction $auctionId at $reminderTime');
      }
    } catch (e) {
      debugPrint('Error scheduling bid reminder: $e');
    }
  }

  // ========================================================================
  // SELLER ACCOUNT ACTIVATION NOTIFICATION
  // ========================================================================

  /// Trigger notification when seller account is activated
  Future<void> triggerSellerActivatedNotification({
    required String sellerId,
    required String displayName,
  }) async {
    try {
      await _notificationService.createNotification(
        userId: sellerId,
        title: '🎉 Account Activated!',
        body:
            'Congratulations $displayName! Your seller account has been verified and activated. You can now list products and create auctions.',
        type: 'sellerAccountActivated',
      );

      // Write trigger for Cloud Function
      await _firestore.collection('notification_triggers').add({
        'type': 'sellerAccountActivated',
        'userId': sellerId,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Seller activation notification triggered for $sellerId');
    } catch (e) {
      debugPrint('Error triggering seller activation notification: $e');
    }
  }
}
