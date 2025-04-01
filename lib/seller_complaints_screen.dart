import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Seller_Drawer.dart';

class SellerComplaintsScreen extends StatefulWidget {
  @override
  _SellerComplaintsScreenState createState() => _SellerComplaintsScreenState();
}

class _SellerComplaintsScreenState extends State<SellerComplaintsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? sellerId;

  @override
  void initState() {
    super.initState();
    _getSellerId();
  }

  Future<void> _getSellerId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        sellerId = user.uid;
      });
    }
  }

  Future<void> _updateStatus(String docId) async {
    await _firestore.collection('order_complaints').doc(docId).update({
      'status': 'confirmed',
    });
  }

  Future<void> _showOrderDetails(String orderId) async {
    try {
      // Fetch order details using order_id
      DocumentSnapshot orderSnapshot =
      await _firestore.collection('orders').doc(orderId).get();

      if (!orderSnapshot.exists) {
        _showErrorDialog("Order details not found.");
        return;
      }

      var orderData = orderSnapshot.data() as Map<String, dynamic>;

      // Extract order details
      String productName = orderData['product_name'] ?? "Unknown";
      String buyerName = orderData['shipping_address']['name'] ?? "Unknown";
      String price = orderData['price'].toString();
      String paymentStatus = orderData['payment_status'];
      String orderStatus = orderData['order_status'];

      // Show order details in an alert dialog
      _showDetailsDialog(
        productName,
        buyerName,
        price,
        paymentStatus,
        orderStatus,
      );
    } catch (e) {
      _showErrorDialog("Error fetching order details: $e");
    }
  }

  void _showDetailsDialog(
      String productName,
      String buyerName,
      String price,
      String paymentStatus,
      String orderStatus,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Order Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Product: $productName"),
              Text("Buyer: $buyerName"),
              Text("Price: ₹$price"),
              Text("Payment Status: $paymentStatus"),
              Text("Order Status: $orderStatus"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sellerId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Set AppBar color to black
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
        title: Text(
          'Manage Order Complaints',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Set text color to white
          ),
        ),
      ),


      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('order_complaints')
            .where('seller_id', isEqualTo: sellerId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No complaints found.'));
          }

          var complaints = snapshot.data!.docs;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var complaint = complaints[index];
              String orderId = complaint['order_id'];

              return Card(
                margin: EdgeInsets.all(10),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(complaint['product_name']),
                      subtitle: Text("Reason: ${complaint['reason']}"),
                      trailing: ElevatedButton(
                        onPressed: () => _updateStatus(complaint.id),
                        child: Text('Confirm',style: TextStyle(color: Colors.black),),
                      ),
                    ),
                    SizedBox(height: 5),
                    TextButton(
                      onPressed: () => _showOrderDetails(orderId),
                      child: Text(
                        "Details",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
