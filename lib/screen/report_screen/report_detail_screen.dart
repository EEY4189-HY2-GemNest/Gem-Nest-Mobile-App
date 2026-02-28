import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/report_model.dart';
import 'package:gemnest_mobile_app/services/report_service.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Report Details',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<ReportProblem?>(
        stream: ReportService().getReportById(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                  SizedBox(height: 12),
                  Text('Report not found',
                      style: TextStyle(color: AppTheme.mediumGray)),
                ],
              ),
            );
          }

          final report = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status timeline card
                _buildStatusTimeline(report),
                const SizedBox(height: 16),

                // Report info card
                _buildInfoCard(report),
                const SizedBox(height: 16),

                // Description card
                _buildDescriptionCard(report),
                const SizedBox(height: 16),

                // Images section
                if (report.imageUrls.isNotEmpty) ...[
                  _buildImagesSection(context, report),
                  const SizedBox(height: 16),
                ],

                // Admin Solution card
                if (report.adminSolution != null &&
                    report.adminSolution!.isNotEmpty) ...[
                  _buildSolutionCard(report),
                  const SizedBox(height: 16),
                ],

                // Admin responses
                if (report.adminResponses.isNotEmpty) ...[
                  _buildResponsesSection(report),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTimeline(ReportProblem report) {
    final allStatuses = [
      ReportStatus.submitted,
      ReportStatus.review,
      ReportStatus.inProgress,
      ReportStatus.done,
    ];

    int currentStep = allStatuses.indexOf(report.status);
    bool isRejected = report.status == ReportStatus.rejected;

    if (isRejected) {
      currentStep = -1; // Special handling for rejected
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Status Tracking',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray)),
              const Spacer(),
              _buildStatusBadge(report.status),
            ],
          ),
          const SizedBox(height: 20),
          if (isRejected)
            _buildRejectedBanner()
          else
            Row(
              children: List.generate(allStatuses.length, (index) {
                final isCompleted = index <= currentStep;
                final isActive = index == currentStep;
                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (index > 0)
                            Expanded(
                              child: Container(
                                height: 3,
                                color: index <= currentStep
                                    ? _getStatusColor(allStatuses[index])
                                    : AppTheme.borderGray,
                              ),
                            ),
                          Container(
                            width: isActive ? 32 : 24,
                            height: isActive ? 32 : 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? _getStatusColor(allStatuses[index])
                                  : AppTheme.borderGray,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: _getStatusColor(
                                                allStatuses[index])
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check
                                  : _getStatusIcon(allStatuses[index]),
                              color: Colors.white,
                              size: isActive ? 18 : 14,
                            ),
                          ),
                          if (index < allStatuses.length - 1)
                            Expanded(
                              child: Container(
                                height: 3,
                                color: index < currentStep
                                    ? _getStatusColor(
                                        allStatuses[index + 1])
                                    : AppTheme.borderGray,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        allStatuses[index].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isCompleted
                              ? _getStatusColor(allStatuses[index])
                              : AppTheme.lightGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cancel, color: AppTheme.errorRed, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report Rejected',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text(
                    'This report has been reviewed and rejected. Check admin response for details.',
                    style: TextStyle(fontSize: 12, color: AppTheme.mediumGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ReportProblem report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.subject,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.category, 'Category', report.category.label),
          const Divider(height: 20, color: AppTheme.borderGray),
          _buildInfoRow(Icons.flag, 'Priority', report.priority.label,
              valueColor: _getPriorityColor(report.priority)),
          const Divider(height: 20, color: AppTheme.borderGray),
          _buildInfoRow(Icons.person, 'Reported as',
              report.userRole == 'seller' ? 'Seller' : 'Buyer'),
          const Divider(height: 20, color: AppTheme.borderGray),
          _buildInfoRow(Icons.calendar_today, 'Submitted',
              DateFormat('MMM dd, yyyy – hh:mm a').format(report.createdAt)),
          if (report.orderId != null && report.orderId!.isNotEmpty) ...[
            const Divider(height: 20, color: AppTheme.borderGray),
            _buildInfoRow(
                Icons.receipt, 'Order ID', report.orderId!),
          ],
          const Divider(height: 20, color: AppTheme.borderGray),
          _buildInfoRow(Icons.update, 'Last Updated',
              DateFormat('MMM dd, yyyy – hh:mm a').format(report.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.lightGray)),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppTheme.darkGray,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(ReportProblem report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryBlue, size: 20),
              SizedBox(width: 8),
              Text('Problem Description',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mediumGray,
                height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context, ReportProblem report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text('Attachments (${report.imageUrls.length})',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: report.imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullImage(context, report.imageUrls[index]),
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGray),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        report.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image,
                              color: AppTheme.lightGray),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionCard(ReportProblem report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.successGreen.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb,
                    color: AppTheme.successGreen, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Admin Solution',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successGreen)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              report.adminSolution!,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkGray,
                  height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection(ReportProblem report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.forum, color: AppTheme.primaryBlue, size: 20),
            SizedBox(width: 8),
            Text('Admin Responses',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray)),
          ],
        ),
        const SizedBox(height: 12),
        ...report.adminResponses.map((response) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade50,
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          size: 16, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(response.adminName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGray)),
                        Text(
                          DateFormat('MMM dd, yyyy – hh:mm a')
                              .format(response.respondedAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.lightGray),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  response.message,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.mediumGray,
                      height: 1.5),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status),
              size: 14, color: _getStatusColor(status)),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return AppTheme.infoBlue;
      case ReportStatus.review:
        return AppTheme.warningOrange;
      case ReportStatus.inProgress:
        return const Color(0xFF8B5CF6);
      case ReportStatus.done:
        return AppTheme.successGreen;
      case ReportStatus.rejected:
        return AppTheme.errorRed;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return Icons.send;
      case ReportStatus.review:
        return Icons.visibility;
      case ReportStatus.inProgress:
        return Icons.engineering;
      case ReportStatus.done:
        return Icons.check_circle;
      case ReportStatus.rejected:
        return Icons.cancel;
    }
  }

  Color _getPriorityColor(ReportPriority priority) {
    switch (priority) {
      case ReportPriority.low:
        return AppTheme.successGreen;
      case ReportPriority.medium:
        return AppTheme.infoBlue;
      case ReportPriority.high:
        return AppTheme.warningOrange;
      case ReportPriority.urgent:
        return AppTheme.errorRed;
    }
  }
}
