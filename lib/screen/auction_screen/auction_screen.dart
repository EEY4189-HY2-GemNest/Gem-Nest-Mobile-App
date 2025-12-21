// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/models/auction_model.dart';
import 'package:gemnest_mobile_app/repositories/auction_repository.dart';
import 'package:gemnest_mobile_app/screen/auction_screen/auction_payment_screen.dart';
import 'package:gemnest_mobile_app/widget/professional_back_button.dart';
import 'package:gemnest_mobile_app/widget/shared_bottom_nav.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}


class _AuctionScreenState extends State<AuctionScreen> {
  // Repository with optimized data structures
  final AuctionRepository _auctionRepository = AuctionRepository();

  // Filter Controllers
  final TextEditingController _filterController = TextEditingController();
  

  // Filter State Variables
  bool _isFilterExpanded = false;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  double _minPrice = 0;
  double _maxPrice = 10000;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
  

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      
      elevation: 0,
      title: const Text(
        'Auctions',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      
      centerTitle: true,
      leading: ProfessionalAppBarBackButton(
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () {
            setState(() {
              _isFilterExpanded = !_isFilterExpanded;
            });
          },
        ),
      ],
    );
  }
  

  Widget _buildFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isFilterExpanded ? 320 : 0,
      child: _isFilterExpanded
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),

              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Filter
                    TextField(
                      controller: _filterController,
                      decoration: const InputDecoration(
                        labelText: 'Search auctions...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),


                    // Status Filter
                    Row(
                      children: [
                        const Text('Status: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children:
                                ['all', 'live', 'ended', 'won'].map((status) {
                              final isSelected = _selectedStatus == status;
                              return FilterChip(
                                label: Text(status.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                },
                                selectedColor: Colors.blue.shade100,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),