import 'package:cloud_firestore/cloud_firestore.dart';

/// Report status enum
enum ReportStatus {
  submitted,
  review,
  inProgress,
  done,
  rejected,
}

/// Report category enum
enum ReportCategory {
  payment,
  delivery,
  product,
  account,
  auction,
  technical,
  other,
}

/// Priority enum
enum ReportPriority {
  low,
  medium,
  high,
  urgent,
}

/// Extension for ReportStatus
extension ReportStatusExtension on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.review:
        return 'Under Review';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.done:
        return 'Done';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  String get value {
    switch (this) {
      case ReportStatus.submitted:
        return 'submitted';
      case ReportStatus.review:
        return 'review';
      case ReportStatus.inProgress:
        return 'inProgress';
      case ReportStatus.done:
        return 'done';
      case ReportStatus.rejected:
        return 'rejected';
    }
  }

  static ReportStatus fromString(String value) {
    switch (value) {
      case 'submitted':
        return ReportStatus.submitted;
      case 'review':
        return ReportStatus.review;
      case 'inProgress':
        return ReportStatus.inProgress;
      case 'done':
        return ReportStatus.done;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.submitted;
    }
  }
}

/// Extension for ReportCategory
extension ReportCategoryExtension on ReportCategory {
  String get label {
    switch (this) {
      case ReportCategory.payment:
        return 'Payment Issue';
      case ReportCategory.delivery:
        return 'Delivery Issue';
      case ReportCategory.product:
        return 'Product Issue';
      case ReportCategory.account:
        return 'Account Issue';
      case ReportCategory.auction:
        return 'Auction Issue';
      case ReportCategory.technical:
        return 'Technical Issue';
      case ReportCategory.other:
        return 'Other';
    }
  }

  String get value {
    switch (this) {
      case ReportCategory.payment:
        return 'payment';
      case ReportCategory.delivery:
        return 'delivery';
      case ReportCategory.product:
        return 'product';
      case ReportCategory.account:
        return 'account';
      case ReportCategory.auction:
        return 'auction';
      case ReportCategory.technical:
        return 'technical';
      case ReportCategory.other:
        return 'other';
    }
  }

  static ReportCategory fromString(String value) {
    switch (value) {
      case 'payment':
        return ReportCategory.payment;
      case 'delivery':
        return ReportCategory.delivery;
      case 'product':
        return ReportCategory.product;
      case 'account':
        return ReportCategory.account;
      case 'auction':
        return ReportCategory.auction;
      case 'technical':
        return ReportCategory.technical;
      case 'other':
        return ReportCategory.other;
      default:
        return ReportCategory.other;
    }
  }
}

/// Extension for ReportPriority
extension ReportPriorityExtension on ReportPriority {
  String get label {
    switch (this) {
      case ReportPriority.low:
        return 'Low';
      case ReportPriority.medium:
        return 'Medium';
      case ReportPriority.high:
        return 'High';
      case ReportPriority.urgent:
        return 'Urgent';
    }
  }

  String get value {
    switch (this) {
      case ReportPriority.low:
        return 'low';
      case ReportPriority.medium:
        return 'medium';
      case ReportPriority.high:
        return 'high';
      case ReportPriority.urgent:
        return 'urgent';
    }
  }

  static ReportPriority fromString(String value) {
    switch (value) {
      case 'low':
        return ReportPriority.low;
      case 'medium':
        return ReportPriority.medium;
      case 'high':
        return ReportPriority.high;
      case 'urgent':
        return ReportPriority.urgent;
      default:
        return ReportPriority.medium;
    }
  }
}

/// Admin response model
class AdminResponse {
  final String adminId;
  final String adminName;
  final String message;
  final DateTime respondedAt;

  AdminResponse({
    required this.adminId,
    required this.adminName,
    required this.message,
    required this.respondedAt,
  });

  factory AdminResponse.fromMap(Map<String, dynamic> map) {
    return AdminResponse(
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? 'Admin',
      message: map['message'] ?? '',
      respondedAt: map['respondedAt'] is Timestamp
          ? (map['respondedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['respondedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'message': message,
      'respondedAt': Timestamp.fromDate(respondedAt),
    };
  }
}

/// Report Problem model
class ReportProblem {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole; // 'buyer' or 'seller'
  final String subject;
  final String description;
  final ReportCategory category;
  final ReportPriority priority;
  final ReportStatus status;
  final List<String> imageUrls;
  final String? orderId;
  final String? productId;
  final String? auctionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminResponse> adminResponses;
  final String? adminSolution;

  ReportProblem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    this.status = ReportStatus.submitted,
    this.imageUrls = const [],
    this.orderId,
    this.productId,
    this.auctionId,
    required this.createdAt,
    required this.updatedAt,
    this.adminResponses = const [],
    this.adminSolution,
  });

  factory ReportProblem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportProblem(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userRole: data['userRole'] ?? 'buyer',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      category: ReportCategoryExtension.fromString(data['category'] ?? 'other'),
      priority:
          ReportPriorityExtension.fromString(data['priority'] ?? 'medium'),
      status: ReportStatusExtension.fromString(data['status'] ?? 'submitted'),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      orderId: data['orderId'],
      productId: data['productId'],
      auctionId: data['auctionId'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      adminResponses: (data['adminResponses'] as List<dynamic>?)
              ?.map((e) => AdminResponse.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      adminSolution: data['adminSolution'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'subject': subject,
      'description': description,
      'category': category.value,
      'priority': priority.value,
      'status': status.value,
      'imageUrls': imageUrls,
      'orderId': orderId,
      'productId': productId,
      'auctionId': auctionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminResponses': adminResponses.map((e) => e.toMap()).toList(),
      'adminSolution': adminSolution,
    };
  }

  ReportProblem copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userRole,
    String? subject,
    String? description,
    ReportCategory? category,
    ReportPriority? priority,
    ReportStatus? status,
    List<String>? imageUrls,
    String? orderId,
    String? productId,
    String? auctionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AdminResponse>? adminResponses,
    String? adminSolution,
  }) {
    return ReportProblem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userRole: userRole ?? this.userRole,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      auctionId: auctionId ?? this.auctionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponses: adminResponses ?? this.adminResponses,
      adminSolution: adminSolution ?? this.adminSolution,
    );
  }
}
