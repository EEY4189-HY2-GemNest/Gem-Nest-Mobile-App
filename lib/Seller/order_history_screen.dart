import 'dart:io'; // For file operations
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For toast messages
import 'package:gemhub/Seller/order_details_screen.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:path_provider/path_provider.dart'; // For internal storage access
import 'package:pdf/widgets.dart' as pw; // For PDF generation
import 'package:printing/printing.dart'; // For printing/sharing PDF

class SellerOrderHistoryScreen extends StatefulWidget {
  const SellerOrderHistoryScreen({super.key});

  @override
  _SellerOrderHistoryScreenState createState() =>
      _SellerOrderHistoryScreenState();
}


                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text('Order #${orderId.substring(0, 8)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Status: ${order['status']}',
                                style: const TextStyle(color: Colors.white60)),
                            Text(
                                'Total: Rs. ${order['totalAmount'].toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white60)),
                            Text('Delivery: ${order['deliveryDate']}',
                                style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: isOverdue ? Colors.white : Colors.blueAccent,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailsScreen(orderId: orderId),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
