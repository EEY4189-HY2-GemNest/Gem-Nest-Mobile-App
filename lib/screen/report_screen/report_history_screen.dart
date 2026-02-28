// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/report_model.dart';
import 'package:gemnest_mobile_app/screen/report_screen/report_detail_screen.dart';
import 'package:gemnest_mobile_app/screen/report_screen/submit_report_screen.dart';
import 'package:gemnest_mobile_app/services/report_service.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ReportHistoryScreen extends StatefulWidget {
  final String userRole; // 'buyer' or 'seller'

  const ReportHistoryScreen({super.key, required this.userRole});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Reports',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SubmitReportScreen(userRole: widget.userRole),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<ReportProblem>>(
        stream: _reportService.getUserReports(roleFilter: widget.userRole),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 64, color: AppTheme.lightGray.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Something went wrong',
                      style: TextStyle(
                          color: AppTheme.mediumGray.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Please try again later',
                      style: TextStyle(
                          color: AppTheme.lightGray.withOpacity(0.6),
                          fontSize: 13)),
                ],
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_off_outlined,
                      size: 72, color: AppTheme.lightGray.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No Reports Found',
                      style: TextStyle(
                          color: AppTheme.mediumGray.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('You haven\'t submitted any reports yet',
                      style: TextStyle(
                          color: AppTheme.lightGray.withOpacity(0.6),
                          fontSize: 14)),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SubmitReportScreen(userRole: widget.userRole),
                        ),
                      );
                      if (result == true) setState(() {});
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Submit a Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _buildReportCard(reports[index], index);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(ReportProblem report, int index) {
    final statusColor = _getStatusColor(report.status);
    final statusIcon = _getStatusIcon(report.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(reportId: report.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGray.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status badge in top-right corner
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(14),
                  ),
                  border: Border(
                    left: BorderSide(
                        color: statusColor.withOpacity(0.2), width: 1),
                    bottom: BorderSide(
                        color: statusColor.withOpacity(0.2), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      report.status.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Priority row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(report.category),
                                size: 12, color: AppTheme.primaryBlue),
                            const SizedBox(width: 5),
                            Text(
                              report.category.label,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityIndicator(report.priority),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Subject
                  Text(
                    report.subject,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description preview
                  Text(
                    report.description,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.mediumGray, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Bottom: Date + Responses
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: AppTheme.lightGray.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy – hh:mm a')
                            .format(report.createdAt),
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.lightGray.withOpacity(0.8)),
                      ),
                      const Spacer(),
                      if (report.adminResponses.isNotEmpty) ...[
                        Icon(Icons.reply,
                            size: 14,
                            color: AppTheme.successGreen.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '${report.adminResponses.length} response(s)',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.successGreen.withOpacity(0.8),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (report.imageUrls.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.image,
                            size: 14,
                            color: AppTheme.lightGray.withOpacity(0.6)),
                        const SizedBox(width: 2),
                        Text('${report.imageUrls.length}',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.lightGray.withOpacity(0.6))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.payment:
        return Icons.payment;
      case ReportCategory.delivery:
        return Icons.local_shipping;
      case ReportCategory.product:
        return Icons.diamond;
      case ReportCategory.account:
        return Icons.person;
      case ReportCategory.auction:
        return Icons.gavel;
      case ReportCategory.technical:
        return Icons.build;
      case ReportCategory.other:
        return Icons.more_horiz;
    }
  }

  Widget _buildPriorityIndicator(ReportPriority priority) {
    Color color;
    switch (priority) {
      case ReportPriority.low:
        color = AppTheme.successGreen;
        break;
      case ReportPriority.medium:
        color = AppTheme.infoBlue;
        break;
      case ReportPriority.high:
        color = AppTheme.warningOrange;
        break;
      case ReportPriority.urgent:
        color = AppTheme.errorRed;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          priority.label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
