import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Admin_Drawer.dart';

class AdminAssignDeliveryScreen extends StatefulWidget {
  @override
  _AdminAssignDeliveryScreenState createState() => _AdminAssignDeliveryScreenState();
}

class _AdminAssignDeliveryScreenState extends State<AdminAssignDeliveryScreen> {
  List<Map<String, dynamic>> deliveryPartners = [];

  @override
  void initState() {
    super.initState();
    fetchDeliveryPartners();
  }

  // ✅ Fetch only verified delivery partners from Firestore
  Future<void> fetchDeliveryPartners() async {
    try {
      QuerySnapshot partners = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'delivery_partner')
          .where('is_verified', isEqualTo: 'true')
          .get();

      setState(() {
        deliveryPartners = partners.docs
            .map((doc) => {
          'id': doc['uid'],
          'name': doc['name'] ?? 'Unknown',
        })
            .toList();
      });
    } catch (e) {
      print('Error fetching verified delivery partners: $e');
    }
  }

  // ✅ Update Order Status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'order_status': newStatus,
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to "$newStatus"!')),
      );

      setState(() {});
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ✅ Assign delivery partner and update Firestore
  Future<void> assignDeliveryPartner(String orderId, String deliveryPartnerId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'order_status': 'Ready to Deliver',
      });

      await FirebaseFirestore.instance.collection('final_delivery').doc(orderId).update({
        'delivery_partner_id': deliveryPartnerId,
        'assigned_at': Timestamp.now(),
        'delivery_status': 'Out for Delivery',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery partner assigned successfully!')),
      );

      setState(() {});
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
        title: Center(
          child: Text(
            'Transit Orders',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: kIsWeb ? null : Admin_Drawer(currentScreen: 'Transit Orders'),
      body: Row(
        children: [
          // Web Sidebar - only show on web
          if (kIsWeb)
            const WebAdminSidebar(currentScreen: 'Transit Orders'),

          // Main Content Area
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black12, Colors.white38],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('final_delivery')
            .where('delivery_status', isEqualTo: 'Out for Delivery')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No orders to assign',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header for Web
                if (kIsWeb)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping, size: 32, color: Colors.black87),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transit Orders Management',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Assign delivery partners and track order status',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Orders List
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      Map<String, dynamic> deliveryData = order.data() as Map<String, dynamic>;
                      String orderId = order.id;
                      String? deliveryPartnerId = deliveryData['delivery_partner_id'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
                        builder: (context, orderSnapshot) {
                          if (orderSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!orderSnapshot.hasData || !orderSnapshot.data!.exists) {
                            return const Center(child: Text('❌ Order details not found.'));
                          }

                          Map<String, dynamic> orderData = orderSnapshot.data!.data() as Map<String, dynamic>;

                          String productName = orderData['product_name'] ?? 'Unknown';
                          String size = orderData['size'] ?? 'N/A';
                          String color = orderData['color'] ?? 'N/A';
                          String price = orderData['price']?.toStringAsFixed(2) ?? '0.00';
                          String customerName = orderData['shipping_address']['name'] ?? 'N/A';
                          String customerPhone = orderData['shipping_address']['phone'] ?? 'N/A';
                          String orderStatus = orderData['order_status'] ?? 'Unknown';

                          // Enhanced card with more web-friendly layout
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: kIsWeb
                                  ? _buildWebOrderCard(
                                  productName, size, color, price, customerName,
                                  customerPhone, orderStatus, orderId, deliveryPartnerId)
                                  : _buildMobileOrderCard(
                                  productName, size, color, price, customerName,
                                  customerPhone, orderStatus, orderId, deliveryPartnerId),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Mobile-optimized order card
  Widget _buildMobileOrderCard(
      String productName, String size, String color, String price,
      String customerName, String customerPhone, String orderStatus,
      String orderId, String? deliveryPartnerId) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order: $productName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text('Size: $size | Color: $color'),
        Text('Customer: $customerName'),
        Text('Phone: $customerPhone'),
        const Divider(),
        Text(
          '₹$price',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.orange, size: 18),
            const SizedBox(width: 4),
            Text(
              'Out for Delivery',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Status Update Buttons
        if (orderStatus == 'Shipped')
          ElevatedButton(
            onPressed: () => updateOrderStatus(orderId, 'In Transit'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Product is in Transit', style: TextStyle(color: Colors.white)),
          ),

        if (orderStatus == 'In Transit')
          ElevatedButton(
            onPressed: () => updateOrderStatus(orderId, 'At Nearest Station'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Go to Nearest Station', style: TextStyle(color: Colors.white)),
          ),

        if (orderStatus == 'At Nearest Station')
          ElevatedButton(
            onPressed: () => updateOrderStatus(orderId, 'Ready to Deliver'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ready to Deliver', style: TextStyle(color: Colors.white)),
          ),

        const SizedBox(height: 12),

        // Delivery Partner Assignment
        if (deliveryPartnerId != null)
          Text(
            'Delivery Partner Assigned ✅',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          )
        else if (deliveryPartners.isNotEmpty)
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            hint: const Text('Select Delivery Partner'),
            items: deliveryPartners.map((partner) {
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
    );
  }

  // Web-optimized order card with responsive layout
  Widget _buildWebOrderCard(
      String productName, String size, String color, String price,
      String customerName, String customerPhone, String orderStatus,
      String orderId, String? deliveryPartnerId) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Order details
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shopping_bag, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Size: $size | Color: $color',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Text(
                      '₹$price',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(customerName),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(customerPhone),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shipment Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusChip(orderStatus),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Right side - Actions
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              // Status Update Buttons
              if (orderStatus == 'Shipped')
                ElevatedButton.icon(
                  onPressed: () => updateOrderStatus(orderId, 'In Transit'),
                  icon: const Icon(Icons.local_shipping, color: Colors.white),
                  label: const Text('Mark as In Transit', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),

              if (orderStatus == 'In Transit')
                ElevatedButton.icon(
                  onPressed: () => updateOrderStatus(orderId, 'At Nearest Station'),
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: const Text('At Nearest Station', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),

              if (orderStatus == 'At Nearest Station')
                ElevatedButton.icon(
                  onPressed: () => updateOrderStatus(orderId, 'Ready to Deliver'),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Ready to Deliver', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),

              const SizedBox(height: 16),

              // Delivery Partner Assignment Section
              const Text(
                'Delivery Partner',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),

              if (deliveryPartnerId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Delivery Partner Assigned',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                )
              else if (deliveryPartners.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    hint: const Text('Select Delivery Partner'),
                    items: deliveryPartners.map((partner) {
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
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData iconData;

    switch (status) {
      case 'Shipped':
        chipColor = Colors.blue;
        iconData = Icons.local_shipping;
        break;
      case 'In Transit':
        chipColor = Colors.orange;
        iconData = Icons.directions_car;
        break;
      case 'At Nearest Station':
        chipColor = Colors.purple;
        iconData = Icons.location_on;
        break;
      case 'Ready to Deliver':
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      default:
        chipColor = Colors.grey;
        iconData = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

// WebAdminSidebar from admin_screen.dart
class WebAdminSidebar extends StatelessWidget {
  final String currentScreen;

  const WebAdminSidebar({
    Key? key,
    required this.currentScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      color: Colors.black.withOpacity(0.9), // Sidebar background color
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSidebarItem(
            context,
            title: "Admin Dashboard",
            icon: Icons.dashboard,
            route: '/admin',
            isSelected: currentScreen == 'Admin Dashboard',
          ),
          _buildSidebarItem(
            context,
            title: "Seller Approvals",
            icon: Icons.person_search,
            route: '/admin/seller-approve',
            isSelected: currentScreen == 'Seller Approval',
          ),
          _buildSidebarItem(
            context,
            title: "Approve Products",
            icon: Icons.check_circle,
            route: '/admin/approve-products',
            isSelected: currentScreen == 'Approve Products',
          ),
          _buildSidebarItem(
            context,
            title: "Manage Categories",
            icon: Icons.category,
            route: '/admin/manage-categories',
            isSelected: currentScreen == 'Manage Category',
          ),
          _buildSidebarItem(
            context,
            title: "Add Category",
            icon: Icons.add_box,
            route: '/admin/add-category',
            isSelected: currentScreen == 'Add New Category',
          ),
          _buildSidebarItem(
            context,
            title: "Verify Delivery Partners",
            icon: Icons.manage_history_sharp,
            route: '/admin/verify-delivery',
            isSelected: currentScreen == 'Verify Delivery Partners',
          ),
          _buildSidebarItem(
            context,
            title: "Transit Orders",
            icon: Icons.local_shipping,
            route: '/admin/transit-orders',
            isSelected: currentScreen == 'Transit Orders',
          ),
          const Divider(color: Colors.white54), // Separator line
          _buildSidebarItem(
            context,
            title: "Logout",
            icon: Icons.logout,
            route: '/login',
            iconColor: Colors.red,
            textColor: Colors.red,
            isSelected: false, // Logout is never "selected"
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        required String route,
        Color iconColor = Colors.white,
        Color textColor = Colors.white,
        bool isSelected = false,
      }) {
    // Create the background color for the selected item
    final Color backgroundColor = isSelected
        ? Colors.white.withOpacity(0.2)
        : Colors.transparent;

    // Make text and icon more prominent when selected
    final Color activeIconColor = isSelected ? Colors.white : iconColor;
    final Color activeTextColor = isSelected ? Colors.white : textColor;
    final FontWeight fontWeight = isSelected ? FontWeight.bold : FontWeight.normal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: activeTextColor,
            fontWeight: fontWeight,
          ),
        ),
        leading: Icon(icon, color: activeIconColor),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}