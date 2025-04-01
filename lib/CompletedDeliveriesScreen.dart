import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'DeliveryPartnerDrawer.dart';

class CompletedDeliveriesScreen extends StatefulWidget {
  @override
  _CompletedDeliveriesScreenState createState() => _CompletedDeliveriesScreenState();
}

class _CompletedDeliveriesScreenState extends State<CompletedDeliveriesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _currentUserId = '';
  int _totalCompletedDeliveries = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      _fetchCompletedDeliveries();
      _updateDeliveryStats();
    }
  }

  Future<void> _fetchCompletedDeliveries() async {
    // Get completed deliveries count and update stats
    QuerySnapshot finalDeliverySnapshot = await _firestore
        .collection('final_delivery')
        .where('delivery_partner_id', isEqualTo: _currentUserId)
        .where('delivery_status', isEqualTo: 'Delivered')
        .get();

    QuerySnapshot pickupSnapshot = await _firestore
        .collection('orders_pickup')
        .where('delivery_partner_id', isEqualTo: _currentUserId)
        .where('pickup_status', isEqualTo: 'completed')
        .get();

    setState(() {
      _totalCompletedDeliveries = finalDeliverySnapshot.docs.length + pickupSnapshot.docs.length;
      _totalEarnings = _totalCompletedDeliveries * 70.0; // 70 Rs per delivery
    });
  }

  Future<void> _updateDeliveryStats() async {
    // Update or create delivery partner stats document
    await _firestore.collection('delivery_partner_stats').doc(_currentUserId).set({
      'total_completed_deliveries': _totalCompletedDeliveries,
      'total_earnings': _totalEarnings,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Completed Deliveries',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.orange.withOpacity(1),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
      ),
      drawer: DeliveryPartnerDrawer(currentScreen: 'Completed Deliveries'),
      body: _currentUserId.isEmpty
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
        children: [
          _buildStatisticsCard(),
          Expanded(
            child: _buildDeliveriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Delivery Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Deliveries', _totalCompletedDeliveries.toString()),
              _buildStatItem('Total Earnings', '₹${_totalEarnings.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveriesList() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.orange.shade100,
            child: TabBar(
              tabs: [
                Tab(text: 'Final Deliveries'),
                Tab(text: 'Pickups'),
              ],
              labelColor: Colors.orange.shade900,
              unselectedLabelColor: Colors.orange.shade700,
              indicatorColor: Colors.orange.shade900,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFinalDeliveriesList(),
                _buildPickupsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalDeliveriesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('final_delivery')
          .where('delivery_partner_id', isEqualTo: _currentUserId)
          .where('delivery_status', isEqualTo: 'Delivered')
          .orderBy('assigned_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No completed deliveries found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var delivery = snapshot.data!.docs[index];
            var deliveryData = delivery.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('orders').doc(deliveryData['order_id']).get(),
              builder: (context, orderSnapshot) {
                if (!orderSnapshot.hasData) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Loading order details...'),
                    ),
                  );
                }

                var orderData = orderSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text('Order #${deliveryData['order_id'].toString().substring(0, 8)}...'),
                    subtitle: Text(
                      'Delivered on: ${_formatTimestamp(deliveryData['assigned_at'])}',
                      style: TextStyle(color: Colors.green),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (orderData['customer_name'] != null)
                              _buildInfoRow('Customer', orderData['customer_name']),
                            if (orderData['delivery_address'] != null)
                              _buildInfoRow('Address', orderData['delivery_address']),
                            _buildInfoRow('Earnings', '₹70.00'),
                            _buildInfoRow('Type', 'Storage to Customer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPickupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders_pickup')
          .where('delivery_partner_id', isEqualTo: _currentUserId)
          .where('pickup_status', isEqualTo: 'completed')
          .orderBy('assigned_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No completed pickups found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var pickup = snapshot.data!.docs[index];
            var pickupData = pickup.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('sellers').doc(pickupData['seller_id']).get(),
              builder: (context, sellerSnapshot) {
                if (!sellerSnapshot.hasData) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Loading seller details...'),
                    ),
                  );
                }

                var sellerData = sellerSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text('Pickup #${pickupData['order_id'].toString().substring(0, 8)}...'),
                    subtitle: Text(
                      'Completed on: ${_formatTimestamp(pickupData['assigned_at'])}',
                      style: TextStyle(color: Colors.green),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sellerData['name'] != null)
                              _buildInfoRow('Seller', sellerData['name']),
                            if (sellerData['address'] != null)
                              _buildInfoRow('Pickup Address', sellerData['address']),
                            _buildInfoRow('Earnings', '₹70.00'),
                            _buildInfoRow('Type', 'Seller to Storage'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      if (timestamp is Timestamp) {
        DateTime dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return 'Invalid date';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}