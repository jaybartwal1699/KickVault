import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'CustomerDrawer.dart';
import 'TrackOrderScreen.dart';

class YourOrdersScreen extends StatefulWidget {
  @override
  _YourOrdersScreenState createState() => _YourOrdersScreenState();
}

class _YourOrdersScreenState extends State<YourOrdersScreen> {
  Future<String?>? _userUIDFuture;
  final TextEditingController _complaintController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userUIDFuture = fetchUserUID();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<String?> fetchUserUID() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc['uid'];
      }
    } catch (e) {
      print("Error fetching user UID: $e");
    }
    return null;
  }

  Widget _buildActionButton(Map<String, dynamic> order) {
    bool isPending = order['order_status'] == "Pending";
    bool isDelivered = order['order_status'] == "Delivered";
    bool isCancelled = order['is_cancel'] == true;
    bool isReturned = order['is_return'] == true;

    // Don't show button if order is already cancelled or returned
    if (isCancelled || isReturned) {
      return SizedBox.shrink();
    }

    // Show cancel button for pending orders
    if (isPending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showComplaintDialog(order, 'cancel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Cancel Order',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    // Show return button for delivered orders
    if (isDelivered) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showComplaintDialog(order, 'return'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Return Order',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    // No action button for other states
    return SizedBox.shrink();
  }

  Future<void> _showComplaintDialog(Map<String, dynamic> order, String type) async {
    _complaintController.clear();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'cancel' ? 'Cancel Order' : 'Return Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == 'return')
              Text(
                'Note: Returns are only accepted within 7 days of delivery',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: 10),
            TextField(
              controller: _complaintController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: type == 'cancel'
                    ? 'Please provide a reason for cancellation...'
                    : 'Please provide a reason for return...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_complaintController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              try {
                // Create complaint document
                await FirebaseFirestore.instance.collection('order_complaints').add({
                  'order_id': order['id'],
                  'user_id': order['user_id'],
                  'type': type,
                  'reason': _complaintController.text,
                  'created_at': FieldValue.serverTimestamp(),
                  'status': 'pending',
                  'product_name': order['product_name'],
                  'seller_id': order['seller_id']
                   // This is correct way
                });
                print('Seller ID: ${order['seller_id']}');

                // Update order status
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(order['id'])
                    .update({
                  'is_cancel': type == 'cancel',
                  'is_return': type == 'return',
                  'order_status': type == 'cancel' ? 'Cancelled' : 'Return Requested'
                });

                Navigator.pop(context);
                setState(() {}); // Refresh the screen

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        type == 'cancel'
                            ? 'Order cancellation request submitted successfully'
                            : 'Return request submitted successfully'
                    ,style: TextStyle(color: Colors.black),),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error submitting complaint: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to submit request. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Submit',style: TextStyle(color: Colors.black),),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchOrders(String userUID) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: userUID)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Orders',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.teal[900],
        elevation: 0,
        centerTitle: true, // Keeps the title centered
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {}); // Refreshes the screen
            },
          ),
        ],
      ),

      drawer: CustomerDrawer(currentScreen: 'Your orders'),
      body: FutureBuilder<String?>(
        future: _userUIDFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return Center(child: Text("User not found!", style: TextStyle(fontSize: 18)));
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchOrders(userSnapshot.data!),
            builder: (context, ordersSnapshot) {
              if (ordersSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!ordersSnapshot.hasData || ordersSnapshot.data!.isEmpty) {
                return Center(child: Text("No orders found!", style: TextStyle(fontSize: 18)));
              }

              return ListView.builder(
                itemCount: ordersSnapshot.data!.length,
                padding: EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final order = ordersSnapshot.data![index];

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  order['product_image'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['product_name'] ?? 'Unknown Product',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text("Color: ${order['color']} | Size: ${order['size']}"),
                                    Text(
                                      "₹${order['price']}",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                constraints: BoxConstraints(
                                  maxWidth: 140, // Adjust as needed
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order['order_status']),
                                  borderRadius: BorderRadius.circular(16), // Similar to Chip
                                ),
                                child: Text(
                                  order['order_status'] ?? 'Unknown',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  softWrap: true, // Allows wrapping to the next line
                                  maxLines: 2, // Limits to 2 lines max
                                  overflow: TextOverflow.ellipsis, // Adds "..." if text is too long
                                ),
                              ),

                              Text(
                                order['payment_method'] == "online" ? "Paid" : "COD",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Seller: ${(order['seller_details'] != null && order['seller_details']['store_name'] != null)
                                ? order['seller_details']['store_name']
                                : 'Unknown'}",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),


                          SizedBox(height: 10),
                          Text(
                            "Shipping to: ${order['shipping_address']['city']}, ${order['shipping_address']['line1']}",
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 10),
                          // Track Order Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrackOrderScreen(orderId: order['id']),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Track Your Order',
                                style: GoogleFonts.nunitoSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 8),
                          _buildActionButton(order),
                          // Cancel/Return Button

                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;

      case 'In Transit':
        return Colors.black;

      case 'Out for Delivery':
        return Colors.teal;

      case 'Out for Delivery and \nHanded to Delivery Boy':
        return Colors.greenAccent;

      case 'At Nearest Station':
        return Colors.amber;

      case 'Ready to Deliver':
        return Colors.orange;

      case 'cancelled':
        return Colors.red;
      case 'return requested':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}