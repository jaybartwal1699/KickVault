import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'Admin_Drawer.dart';
import 'admin_screen.dart';

class AdminManageOrdersScreen extends StatefulWidget {
  @override
  _AdminManageOrdersScreenState createState() => _AdminManageOrdersScreenState();
}

class _AdminManageOrdersScreenState extends State<AdminManageOrdersScreen> {
  String selectedStatus = 'All';
  List<String> statusOptions = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Canceled'];

  bool isLoading = true;
  List<Map<String, dynamic>> allOrders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> orders = await fetchOrders();
      setState(() {
        allOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    QuerySnapshot orderSnapshot = await FirebaseFirestore.instance.collection('orders').get();
    List<Map<String, dynamic>> ordersList = [];

    for (var doc in orderSnapshot.docs) {
      Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;

      // Fetch user data
      String userId = orderData['user_id'] ?? '';
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;

      // Fetch product data
      String productId = orderData['product_id'] ?? '';
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      Map<String, dynamic>? productData = productSnapshot.data() as Map<String, dynamic>?;

      // Fetch seller data
      String sellerId = orderData['seller_id'] ?? '';
      DocumentSnapshot sellerSnapshot = await FirebaseFirestore.instance.collection('seller_details').doc(sellerId).get();
      Map<String, dynamic>? sellerData = sellerSnapshot.data() as Map<String, dynamic>?;

      // Format timestamps
      Timestamp? createdAt = orderData['created_at'] as Timestamp?;
      Timestamp? updatedAt = orderData['updated_at'] as Timestamp?;

      // Format price
      double price = (orderData['price'] is double) ? orderData['price'] : 0.0;

      // Add order to list
      ordersList.add({
        'order_id': doc.id,
        'order_pin': orderData['order_pin'] ?? '',
        'order_status': orderData['order_status'] ?? 'Pending',
        'payment_method': orderData['payment_method'] ?? '',
        'payment_status': orderData['payment_status'] ?? '',
        'is_cancel': orderData['is_cancel'] ?? false,
        'is_return': orderData['is_return'] ?? false,
        'created_at': createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate()) : 'N/A',
        'updated_at': updatedAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(updatedAt.toDate()) : 'N/A',
        'price': price.toStringAsFixed(2),
        'color': orderData['color'] ?? '',
        'size': orderData['size'] ?? '',

        // Product details
        'product_id': productId,
        'product_name': orderData['product_name'] ?? productData?['name'] ?? 'Unknown',
        'product_image': orderData['product_image'] ??
            (productData != null &&
                productData['images'] != null &&
                productData['images'] is List &&
                (productData['images'] as List).isNotEmpty ?
            productData['images'][0] : null) ?? '',
        // User details
        'user_id': userId,
        'customer_name': userData?['name'] ?? 'Unknown',
        'customer_email': userData?['email'] ?? 'Unknown',
        'customer_phone': userData?['phone'] ?? 'Unknown',

        // Seller details
        'seller_id': sellerId,
        'seller_name': sellerData?['name'] ?? 'Unknown',
        'store_name': sellerData?['business_details']?['store_name'] ?? 'Unknown',
      });
    }

    return ordersList;
  }

  void updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'order_status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Refresh orders list
      await loadOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter orders based on selected status
    List<Map<String, dynamic>> filteredOrders = selectedStatus == 'All'
        ? allOrders
        : allOrders.where((order) => order['order_status'] == selectedStatus).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminScreen()),
            );
          },
        ),
        title: Center(
          child: Text(
            'Manage Orders',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      drawer: kIsWeb ? null : const Admin_Drawer(currentScreen: 'Manage Orders'),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and filter row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text('Filter by: '),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedStatus,
                      items: statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Status summary cards
            Container(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatusCard('Total Orders', allOrders.length.toString(), Colors.blue),
                  _buildStatusCard('Pending', _countOrdersByStatus('Pending'), Colors.orange),
                  _buildStatusCard('Processing', _countOrdersByStatus('Processing'), Colors.purple),
                  _buildStatusCard('Shipped', _countOrdersByStatus('Shipped'), Colors.indigo),
                  _buildStatusCard('Delivered', _countOrdersByStatus('Delivered'), Colors.green),
                  _buildStatusCard('Canceled', _countOrdersByStatus('Canceled'), Colors.red),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by order ID, customer name, or product',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // Implement search functionality later
              },
            ),

            SizedBox(height: 16),

            Text(
              'Showing ${filteredOrders.length} orders',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            // Orders data table
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredOrders.isEmpty
                  ? Center(child: Text('No orders found'))
                  : _buildOrdersTable(filteredOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, Color color) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 150,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTable(List<Map<String, dynamic>> orders) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          dataRowHeight: 72,
          columns: [
            DataColumn(label: Text('Order ID')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Seller')),
            DataColumn(label: Text('Payment')),
            DataColumn(label: Text('Actions')),
          ],
          rows: orders.map((order) {
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(order['order_id'], style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('PIN: ${order['order_pin']}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['order_status']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order['order_status'],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(order['customer_name']),
                      Text(order['customer_email'], style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      order['product_image'].isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          order['product_image'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, size: 20),
                            );
                          },
                        ),
                      )
                          : Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 20),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order['product_name'], overflow: TextOverflow.ellipsis),
                            if (order['color'].isNotEmpty || order['size'].isNotEmpty)
                              Text(
                                '${order['color']} | Size: ${order['size']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text('\₹ ${order['price']}')),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(order['created_at']),
                      Text('Updated: ${order['updated_at']}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(order['store_name']),
                      Text(order['seller_name'], style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(order['payment_method'].toUpperCase()),
                      Text(order['payment_status'], style: TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      DropdownButton<String>(
                        hint: Text('Update'),
                        icon: Icon(Icons.arrow_drop_down),
                        underline: Container(height: 0),
                        onChanged: (value) {
                          if (value != null) {
                            updateOrderStatus(order['order_id'], value);
                          }
                        },
                        items: statusOptions
                            .where((status) => status != 'All' && status != order['order_status'])
                            .map((status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text('Change to $status'),
                        ))
                            .toList(),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {
                          _showOrderDetailsDialog(context, order);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 800,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              Divider(height: 32),

              // Order summary
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order and customer information
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Order info
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    _detailItem('Order ID', order['order_id']),
                                    _detailItem('Order PIN', order['order_pin']),
                                    _detailItem('Created', order['created_at']),
                                    _detailItem('Updated', order['updated_at']),
                                    _detailItem('Status', order['order_status']),
                                    _detailItem('Is Canceled', order['is_cancel'] ? 'Yes' : 'No'),
                                    _detailItem('Is Returned', order['is_return'] ? 'Yes' : 'No'),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 16),

                          // Right column - Customer info
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    _detailItem('Name', order['customer_name']),
                                    _detailItem('Email', order['customer_email']),
                                    _detailItem('Phone', order['customer_phone']),
                                    _detailItem('User ID', order['user_id']),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Product and payment information
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Product info
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Product Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    if (order['product_image'].isNotEmpty)
                                      Container(
                                        height: 150,
                                        width: double.infinity,
                                        margin: EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: NetworkImage(order['product_image']),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    _detailItem('Product Name', order['product_name']),
                                    _detailItem('Product ID', order['product_id']),
                                    _detailItem('Color', order['color']),
                                    _detailItem('Size', order['size']),
                                    _detailItem('Price', '\$${order['price']}'),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 16),

                          // Right column - Payment info
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Payment & Seller Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    _detailItem('Payment Method', order['payment_method'].toUpperCase()),
                                    _detailItem('Payment Status', order['payment_status']),
                                    Divider(height: 24),
                                    _detailItem('Store Name', order['store_name']),
                                    _detailItem('Seller Name', order['seller_name']),
                                    _detailItem('Seller ID', order['seller_id']),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Action buttons
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Update Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: order['order_status'],
                                      items: statusOptions
                                          .where((status) => status != 'All')
                                          .map((status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null && value != order['order_status']) {
                                          Navigator.pop(context);
                                          updateOrderStatus(order['order_id'], value);
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.print),
                                    label: Text('Print Order'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Print functionality coming soon!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _countOrdersByStatus(String status) {
    return allOrders.where((order) => order['order_status'] == status).length.toString();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}