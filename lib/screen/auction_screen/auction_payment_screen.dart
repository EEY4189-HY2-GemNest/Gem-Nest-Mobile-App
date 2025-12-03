import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/order_history_screen/oreder_history_screen.dart';

class AuctionPaymentScreen extends StatefulWidget {
  final String auctionId;
  final double itemPrice;
  final String title;
  final String imagePath;

  const AuctionPaymentScreen({
    super.key,
    required this.auctionId,
    required this.itemPrice,
    required this.title,
    required this.imagePath,
  });

  @override
  _AuctionPaymentScreenState createState() => _AuctionPaymentScreenState();
}


}
