// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/auction_screen/auction_payment_screen.dart';

class AuctionScreen extends StatelessWidget {
  const AuctionScreen({super.key});

  DateTime _parseEndTime(dynamic endTime) {
    if (endTime is Timestamp) {
      return endTime.toDate();
    } else if (endTime is String) {
      try {
        return DateTime.parse(endTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  
}
