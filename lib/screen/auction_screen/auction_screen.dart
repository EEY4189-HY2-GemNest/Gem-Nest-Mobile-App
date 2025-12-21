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