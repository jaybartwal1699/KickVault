import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Seller_Drawer.dart';

class OrdersToDeliver extends StatefulWidget {
  const OrdersToDeliver({Key? key}) : super(key: key);

  @override
  _OrdersToDeliverState createState() => _OrdersToDeliverState();
}

class _OrdersToDeliverState extends State<OrdersToDeliver> {
  String? sellerId;
  bool isLoading = true;
  List<Map<String, dynamic>> deliveryPartners = [];
  Map<String, String?> assignedOrders = {}; // Stores assigned delivery partners for orders

  @override
  void initState() {
    super.initState();
    fetchSellerId();
  }

  // Fetch the seller's ID based on their logged-in UID
  Future<void> fetchSellerId() async {
    try {
      String? userUid = FirebaseAuth.instance.currentUser?.uid;
      print('Debug: Logged-in User UID: $userUid');

      if (userUid == null) {
        print('Error: No logged-in user found.');
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .get();

      if (userDoc.exists) {
        setState(() {
          sellerId = userDoc.id;
        });
        print('Debug: Seller ID found in Firestore: $sellerId');
        fetchDeliveryPartners();
        fetchAssignedOrders(); // Fetch assigned orders
      } else {
        print('Error: No seller found in Firestore.');
      }
    } catch (e) {
      print('Error fetching seller ID: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Fetch available delivery partners from Firestore
  Future<void> fetchDeliveryPartners() async {
    try {
      QuerySnapshot partners = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'delivery_partner')
          .where('is_verified', isEqualTo: 'true') // Filter verified partners
          .get();

      setState(() {
        deliveryPartners = partners.docs.map((doc) {
          return {'id': doc['uid'], 'name': doc['name'] ?? 'Unknown'};
        }).toList();
      });

      print('Debug: Loaded ${deliveryPartners.length} verified delivery partners');
    } catch (e) {
      print('Error fetching delivery partners: $e');
    }
  }


  // Fetch assigned orders from orders_pickup collection
  Future<void> fetchAssignedOrders() async {
    try {
      QuerySnapshot assignedOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders_pickup')
          .get();

      setState(() {
        assignedOrders = {
          for (var doc in assignedOrdersSnapshot.docs)
            doc['order_id']: doc['delivery_partner_id']
        };
      });

      print('Debug: Loaded ${assignedOrders.length} assigned orders');
    } catch (e) {
      print('Error fetching assigned orders: $e');
    }
  }

  // Assign a delivery partner to an order
  Future<void> assignDeliveryPartner(String orderId, String deliveryPartnerId) async {
    try {
      await FirebaseFirestore.instance.collection('orders_pickup').doc(orderId).set({
        'order_id': orderId,
        'seller_id': sellerId,
        'delivery_partner_id': deliveryPartnerId,
        'pickup_status': 'pending',
        'assigned_at': Timestamp.now(),
      });

      // Update UI to reflect assignment
      setState(() {
        assignedOrders[orderId] = deliveryPartnerId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery partner assigned successfully!')),
      );
    } catch (e) {
      print('Error assigning delivery partner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orders to Deliver',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black, // Solid black color
        elevation: 4, // Slight shadow for depth
        iconTheme: const IconThemeData(color: Colors.white), // Ensures drawer icon is white
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sellerId == null
          ? const Center(
        child: Text(
          'Error: No seller ID found!',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('seller_id', isEqualTo: sellerId)
            .where('order_status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Firestore Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No pending orders to deliver',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              Map<String, dynamic> data = order.data() as Map<String, dynamic>;
              String orderId = order.id;
              Timestamp createdAt = data['created_at'] ?? Timestamp.now();
              String? assignedPartner = assignedOrders[orderId];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order: ${data['product_name']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Size: ${data['size']} | Color: ${data['color']}'),
                      Text('Customer: ${data['shipping_address']['name']}'),
                      Text('Ordered At: ${createdAt.toDate()}'),
                      const SizedBox(height: 8),
                      const Divider(),
                      Text(
                        '₹${data['price'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 12),

                      // Condition: If assigned, show text in green and disable dropdown
                      assignedPartner != null
                          ? Text(
                        'Delivery Partner Assigned ✅',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      )
                          : deliveryPartners.isNotEmpty
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assign Delivery Partner:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            hint: const Text('Select Delivery Partner'),
                            items: deliveryPartners
                                .map<DropdownMenuItem<String>>((partner) {
                              return DropdownMenuItem<String>(
                                value: partner['id'],
                                child: Text(partner['name']),
                              );
                            }).toList(),
                            onChanged: (String? selectedPartnerId) {
                              if (selectedPartnerId != null) {
                                assignDeliveryPartner(orderId, selectedPartnerId);
                              }
                            },
                          ),
                        ],
                      )
                          : const Text(
                        'No available delivery partners',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
