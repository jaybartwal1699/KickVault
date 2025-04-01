import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'DeliveryPartnerDrawer.dart';
import 'CompletedDeliveriesScreen.dart';
import 'OrdersToDeliverScreen.dart';

class DeliveryPartnerScreen extends StatefulWidget {
  const DeliveryPartnerScreen({super.key});

  @override
  State<DeliveryPartnerScreen> createState() => _DeliveryPartnerScreenState();
}

class _DeliveryPartnerScreenState extends State<DeliveryPartnerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _currentUserId = '';
  int _totalCompletedDeliveries = 0;
  int _pendingDeliveries = 0;
  double _totalEarnings = 0.0;
  bool _isLoading = true;

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
      _fetchDeliveryData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDeliveryData() async {
    try {
      // Get completed deliveries
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

      // Get pending deliveries
      QuerySnapshot pendingFinalDeliverySnapshot = await _firestore
          .collection('final_delivery')
          .where('delivery_partner_id', isEqualTo: _currentUserId)
          .where('delivery_status', whereIn: ['Pending', 'In Progress', 'Assigned']) // Be explicit about statuses
          .get();

      QuerySnapshot pendingPickupSnapshot = await _firestore
          .collection('orders_pickup')
          .where('delivery_partner_id', isEqualTo: _currentUserId)
          .where('pickup_status', whereIn: ['pending', 'assigned', 'in_progress']) // Be explicit about statuses
          .get();

      print('Completed final deliveries: ${finalDeliverySnapshot.docs.length}');
      print('Completed pickups: ${pickupSnapshot.docs.length}');
      print('Pending final deliveries: ${pendingFinalDeliverySnapshot.docs.length}');
      print('Pending pickups: ${pendingPickupSnapshot.docs.length}');

      int completedDeliveriesCount = finalDeliverySnapshot.docs.length + pickupSnapshot.docs.length;
      int pendingCount = pendingFinalDeliverySnapshot.docs.length + pendingPickupSnapshot.docs.length;
      double earnings = completedDeliveriesCount * 70.0; // 70 Rs per delivery

      print('Total completed: $completedDeliveriesCount');
      print('Total pending: $pendingCount');
      print('Total earnings: $earnings');

      // Update delivery partner stats
      await _firestore.collection('delivery_partner_stats').doc(_currentUserId).set({
        'total_completed_deliveries': completedDeliveriesCount,
        'pending_deliveries': pendingCount,
        'total_earnings': earnings,
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _totalCompletedDeliveries = completedDeliveriesCount;
        _pendingDeliveries = pendingCount;
        _totalEarnings = earnings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching delivery data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Delivery Partner Dashboard',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: Colors.white,
              letterSpacing: 0,
            ),
          ),
        ),
        backgroundColor: Colors.orange.withOpacity(1),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
      ),
      drawer: DeliveryPartnerDrawer(currentScreen: 'Home'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
        onRefresh: _fetchDeliveryData,
        color: Colors.orange,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                      "Total Earnings",
                      "\₹ ${_totalEarnings.toStringAsFixed(0)}",
                      Icons.monetization_on
                  ),
                  _buildInfoCard(
                      "Orders Delivered",
                      "$_totalCompletedDeliveries",
                      Icons.delivery_dining
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                      "Pending Orders",
                      "$_pendingDeliveries",
                      Icons.timer
                  ),
                  _buildInfoCard(
                      "Earnings Per Delivery",
                      "₹ 70",
                      Icons.account_balance_wallet
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Action Buttons
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildActionButton(
                      context,
                      "Orders to Deliver",
                      Icons.local_shipping,
                      Colors.orange.shade300,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OrdersToDeliverScreen()),
                      ),
                    ),
                    _buildActionButton(
                        context,
                        "Completed Deliveries",
                        Icons.check_circle,
                        Colors.green.shade300,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompletedDeliveriesScreen(),
                          ),
                        )
                    ),
                    _buildActionButton(
                        context,
                        "Earnings History",
                        Icons.attach_money,
                        Colors.blue.shade300,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompletedDeliveriesScreen(),
                          ),
                        )
                    ),
                    _buildActionButton(
                      context,
                      "Pickup Orders",
                      Icons.store,
                      Colors.purple.shade300,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OrdersToDeliverScreen()),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.orange),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      VoidCallback onPressed
      ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
}