import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add this package for animations

class NotificationsPage extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(int)? onDelete; // Callback to delete a notification by index
  final VoidCallback? onClearAll; // Callback to clear all notifications

  const NotificationsPage({
    super.key,
    required this.notifications,
    this.onDelete,
    this.onClearAll,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late List<Map<String, dynamic>> _notifications; // Local copy of notifications

  @override
  void initState() {
    super.initState();
    _notifications = List.from(widget.notifications);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  
}
