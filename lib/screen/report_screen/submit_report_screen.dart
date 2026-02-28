// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/report_model.dart';
import 'package:gemnest_mobile_app/services/report_service.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';

class SubmitReportScreen extends StatefulWidget {
  final String userRole; // 'buyer' or 'seller'

  const SubmitReportScreen({super.key, required this.userRole});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderIdController = TextEditingController();

  ReportCategory _selectedCategory = ReportCategory.other;
  ReportPriority _selectedPriority = ReportPriority.medium;
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _orderIdController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
            images.map((e) => File(e.path)).take(5 - _selectedImages.length));
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ReportService().submitReport(
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        images: _selectedImages,
        orderId: _orderIdController.text.trim().isEmpty
            ? null
            : _orderIdController.text.trim(),
        overrideRole: widget.userRole,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Report submitted successfully!'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Report a Problem',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.1),
                        AppTheme.primaryBlueDark.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.report_problem_outlined,
                            color: AppTheme.primaryBlue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Submit Your Report',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGray)),
                            const SizedBox(height: 4),
                            Text(
                              'Describe the issue and our team will help resolve it.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mediumGray.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category selector
                _buildSectionLabel('Category', Icons.category_outlined),
                const SizedBox(height: 8),
                _buildCategorySelector(),
                const SizedBox(height: 20),

                // Priority selector
                _buildSectionLabel('Priority', Icons.flag_outlined),
                const SizedBox(height: 8),
                _buildPrioritySelector(),
                const SizedBox(height: 20),

                // Subject
                _buildSectionLabel('Subject', Icons.subject),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  decoration: AppTheme.textFieldDecoration(
                    labelText: 'Brief subject of the issue',
                    prefixIcon: Icons.title,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Subject is required'
                      : null,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Description
                _buildSectionLabel('Description', Icons.description_outlined),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: AppTheme.textFieldDecoration(
                    labelText: 'Describe your problem in detail...',
                    prefixIcon: Icons.edit_note,
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Order ID (optional)
                _buildSectionLabel(
                    'Related Order ID (Optional)', Icons.receipt_long_outlined),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _orderIdController,
                  decoration: AppTheme.textFieldDecoration(
                    labelText: 'Enter order ID if applicable',
                    prefixIcon: Icons.tag,
                  ),
                ),
                const SizedBox(height: 20),

                // Image attachments
                _buildSectionLabel(
                    'Attachments (Optional)', Icons.attach_file_outlined),
                const SizedBox(height: 8),
                _buildImagePicker(),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Submit Report',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray)),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReportCategory.values.map((cat) {
        final isSelected = cat == _selectedCategory;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.borderGray,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getCategoryIcon(cat),
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.mediumGray),
                const SizedBox(width: 6),
                Text(cat.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.mediumGray,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(ReportCategory cat) {
    switch (cat) {
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

  Widget _buildPrioritySelector() {
    return Row(
      children: ReportPriority.values.map((p) {
        final isSelected = p == _selectedPriority;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _getPriorityColor(p) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? _getPriorityColor(p) : AppTheme.borderGray,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: _getPriorityColor(p).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(Icons.flag,
                      size: 18,
                      color: isSelected ? Colors.white : _getPriorityColor(p)),
                  const SizedBox(height: 4),
                  Text(p.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : _getPriorityColor(p),
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getPriorityColor(ReportPriority p) {
    switch (p) {
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

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: AppTheme.borderGray),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedImages.removeAt(index));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_selectedImages.length < 5) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 1.5),
                borderRadius: BorderRadius.circular(14),
                color: AppTheme.primaryBlue.withOpacity(0.04),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: AppTheme.primaryBlue.withOpacity(0.6)),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to add images (${_selectedImages.length}/5)',
                    style: TextStyle(
                        color: AppTheme.primaryBlue.withOpacity(0.6),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
