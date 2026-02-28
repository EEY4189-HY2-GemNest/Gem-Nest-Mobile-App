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

class _ReportHistoryScreenState extends State<ReportHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();

  final List<ReportStatus?> _statusFilters = [
    null, // All
    ReportStatus.submitted,
    ReportStatus.review,
    ReportStatus.inProgress,
    ReportStatus.done,
    ReportStatus.rejected,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Submitted'),
            Tab(text: 'Review'),
            Tab(text: 'In Progress'),
            Tab(text: 'Done'),
            Tab(text: 'Rejected'),
          ],
        ),
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
            setState(() {}); // Refresh
          }
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statusFilters.map((statusFilter) {
          return _buildReportList(statusFilter);
        }).toList(),
      ),
    );
  }

  Widget _buildReportList(ReportStatus? statusFilter) {
    return StreamBuilder<List<ReportProblem>>(
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
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                Text('Error loading reports',
                    style: TextStyle(
                        color: AppTheme.mediumGray.withOpacity(0.8),
                        fontSize: 15)),
              ],
            ),
          );
        }

        List<ReportProblem> reports = snapshot.data ?? [];

        // Apply status filter
        if (statusFilter != null) {
          reports = reports.where((r) => r.status == statusFilter).toList();
        }

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 64, color: AppTheme.lightGray.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('No reports found',
                    style: TextStyle(
                        color: AppTheme.mediumGray.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('Tap + to submit a new report',
                    style: TextStyle(
                        color: AppTheme.lightGray.withOpacity(0.6),
                        fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            return _buildReportCard(reports[index], index);
          },
        );
      },
    );
  }

  Widget _buildReportCard(ReportProblem report, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(reportId: report.id),
          ),
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 50)),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Status + Priority
              Row(
                children: [
                  _buildStatusChip(report.status),
                  const Spacer(),
                  _buildPriorityIndicator(report.priority),
                ],
              ),
              const SizedBox(height: 12),

              // Subject
              Text(
                report.subject,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Category chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.category.label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 10),

              // Description preview
              Text(
                report.description,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.mediumGray, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Bottom: Date + Responses count
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
                        size: 14, color: AppTheme.lightGray.withOpacity(0.6)),
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
      ),
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    IconData icon;
    switch (status) {
      case ReportStatus.submitted:
        color = AppTheme.infoBlue;
        icon = Icons.send;
        break;
      case ReportStatus.review:
        color = AppTheme.warningOrange;
        icon = Icons.visibility;
        break;
      case ReportStatus.inProgress:
        color = const Color(0xFF8B5CF6);
        icon = Icons.engineering;
        break;
      case ReportStatus.done:
        color = AppTheme.successGreen;
        icon = Icons.check_circle;
        break;
      case ReportStatus.rejected:
        color = AppTheme.errorRed;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
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
