import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _TrackOrderScreenState createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final List<String> statuses = [
    "Pending",
    "Shipped",
    "In Transit",
    "At Nearest Station",
    "Ready to Deliver",
    "Out for Delivery",
    "Delivered"
  ];

  Future<Map<String, dynamic>> fetchOrderDetails() async {
    try {
      // Fetch order details
      DocumentSnapshot orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!orderDoc.exists) {
        return {};
      }

      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;

      // Fetch delivery details
      QuerySnapshot deliverySnapshot = await FirebaseFirestore.instance
          .collection('final_delivery')
          .where('order_id', isEqualTo: widget.orderId)
          .limit(1)
          .get();

      Map<String, dynamic>? deliveryData;
      Map<String, dynamic>? partnerData;

      if (deliverySnapshot.docs.isNotEmpty) {
        deliveryData = deliverySnapshot.docs.first.data() as Map<String, dynamic>;

        // Fetch delivery partner if available
        if (deliveryData['delivery_partner_id'] != null) {
          DocumentSnapshot partnerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(deliveryData['delivery_partner_id'])
              .get();

          if (partnerDoc.exists) {
            partnerData = partnerDoc.data() as Map<String, dynamic>;
          }
        }
      }

      return {
        'orderData': orderData,
        'deliveryData': deliveryData,
        'partnerData': partnerData,
      };
    } catch (e) {
      print('Error fetching order details: $e');
      return {};
    }
  }

  int getStatusIndex(String? status) {
    if (status == null) return 0;

    final statusMap = {
      "Pending": 0,
      "Shipped": 1,
      "Order Confirmed": 1,
      "In Transit": 2,
      "At Nearest Station": 3,
      "Ready to Deliver": 4,
      "Out for Delivery": 5,
      "Out for Delivery and Handed to Delivery Boy": 5,
      "Delivered": 6,
    };

    return statusMap[status] ?? 0;
  }

  String _getStatusMessage(String? status) {
    final statusMessages = {
      "Pending": 'Your order has been received and is being processed.',
      "Shipped": 'Your order has been confirmed and is being prepared for shipping.',
      "In Transit": 'Your package has left our warehouse and is on its way to you.',
      "At Nearest Station": 'Your package has arrived at the nearest station and will be delivered soon.',
      "Ready to Deliver": 'Your order is ready to be delivered to you.',
      "Out for Delivery": 'Your order is out for delivery and will arrive soon.',
      "Delivered": 'Your order has been delivered successfully. Thank you for shopping with us!',
    };

    return statusMessages[status] ?? 'Your order status: $status';
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Your Order',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white
          ),
        ),
        backgroundColor: Colors.teal[900],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TrackOrderScreen(orderId: widget.orderId),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchOrderDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.teal)
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Order not found!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Please check the order ID and try again.'),
                ],
              ),
            );
          }

          final orderData = snapshot.data!['orderData'];
          final deliveryData = snapshot.data!['deliveryData'];
          final partnerData = snapshot.data!['partnerData'];

          Timestamp createdAt = orderData['created_at'];
          DateTime createdDate = createdAt.toDate();
          DateTime estimatedDeliveryDate = createdDate.add(Duration(days: 3 + (createdDate.day % 3)));
          String formattedEstimatedDate = DateFormat('MMMM d, yyyy').format(estimatedDeliveryDate);

          int currentStatusIndex = getStatusIndex(orderData['order_status']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Details Card
                _buildOrderDetailsCard(orderData),

                SizedBox(height: 20),

                // Order Status Tracking Card
                _buildOrderTrackingCard(orderData, currentStatusIndex, formattedEstimatedDate),

                SizedBox(height: 20),

                // Shipping Address Card
                _buildShippingAddressCard(orderData),

                SizedBox(height: 20),

                // Delivery Partner Card (if applicable)
                if (currentStatusIndex >= 3 && partnerData != null)
                  _buildDeliveryPartnerCard(partnerData, deliveryData),

                SizedBox(height: 20),

                // Order PIN Card (if available)
                if (orderData.containsKey('order_pin') && orderData['order_pin'] != null)
                  _buildOrderPinCard(orderData),
              ],
            ),
          );
        },
      ),
    );
  }

  // Separate method to build Order Details Card
  Widget _buildOrderDetailsCard(Map<String, dynamic> orderData) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🆔 Order ID: ${widget.orderId}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            SizedBox(height: 16),
            Text('🛍 Product: ${orderData['product_name']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                orderData['product_image'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported, size: 50),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🎨 Color: ${orderData['color']}', style: TextStyle(fontSize: 16)),
                Text('📏 Size: ${orderData['size']}', style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            Text('💰 Price: ₹${orderData['price']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 8),
            Text('💳 Payment: ${orderData['payment_method']} (${orderData['payment_status']})',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Separate method to build Order Tracking Card
  Widget _buildOrderTrackingCard(Map<String, dynamic> orderData, int currentStatusIndex, String formattedEstimatedDate) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.teal),
                SizedBox(width: 8),
                Text('Order Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),

            // Horizontal Status List
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  bool isActive = index <= currentStatusIndex;
                  return Container(
                    width: 80,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.teal : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isActive ? Icons.check : Icons.circle,
                              size: isActive ? 14 : 10,
                              color: isActive ? Colors.white : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          statuses[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? Colors.teal : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Progress Indicator
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: (currentStatusIndex + 1) / statuses.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Estimated Delivery Section
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _getDeliveryStatusIcon(orderData['order_status']),
                    color: _getDeliveryStatusColor(orderData['order_status']),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderData['order_status'] == "Delivered" ? 'Delivery Status' : 'Estimated Delivery',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        orderData['order_status'] == "Delivered" ? 'Delivered' : formattedEstimatedDate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: orderData['order_status'] == "Delivered" ? Colors.green : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Latest Update Section
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Update',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.teal),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getStatusMessage(orderData['order_status']),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (orderData.containsKey('updated_at') && orderData['updated_at'] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            orderData['order_status'] == "Delivered"
                                ? 'Delivered'
                                : 'Updated: ${_formatTimestamp(orderData['updated_at'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get delivery status icon
  IconData _getDeliveryStatusIcon(String status) {
    switch (status) {
      case "Delivered":
        return Icons.check_circle;
      case "Out for Delivery":
        return Icons.local_shipping;
      case "Ready to Deliver":
        return Icons.assignment_turned_in;
      case "At Nearest Station":
        return Icons.store_mall_directory;
      default:
        return Icons.calendar_today;
    }
  }

  // Helper method to get delivery status color
  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case "Delivered":
        return Colors.green;
      case "Out for Delivery":
        return Colors.blue;
      case "Ready to Deliver":
        return Colors.amber;
      case "At Nearest Station":
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  // Separate method to build Shipping Address Card
  Widget _buildShippingAddressCard(Map<String, dynamic> orderData) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal),
                SizedBox(width: 8),
                Text('Shipping Address:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text('${orderData['shipping_address']['name']}, ${orderData['shipping_address']['phone']}'),
            Text(
              '${orderData['shipping_address']['line1']}, ${orderData['shipping_address']['city']}, ${orderData['shipping_address']['state']} - ${orderData['shipping_address']['zipcode']}',
            ),
          ],
        ),
      ),
    );
  }

  // Separate method to build Delivery Partner Card
  Widget _buildDeliveryPartnerCard(Map<String, dynamic> partnerData, Map<String, dynamic>? deliveryData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Delivery Partner:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerData['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (partnerData['phone'] != null) {
                            final Uri uri = Uri.parse('tel:${partnerData['phone']}');
                            if (await canLaunchUrl(uri)) {
                              launchUrl(uri);
                            } else {
                              print('Could not launch phone dialer');
                            }
                          }
                        },
                        child: Text(
                          '📞 ${partnerData['phone'] ?? 'Not Available'}',
                          style: TextStyle(
                            color: partnerData['phone'] != null ? Colors.blue : Colors.grey.shade600,
                            decoration: partnerData['phone'] != null ? TextDecoration.underline : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 8),
            if (deliveryData != null && deliveryData['assigned_at'] != null)
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Text(
                    '⏱ Assigned at: ${_formatTimestamp(deliveryData['assigned_at'])}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Separate method to build Order PIN Card
  Widget _buildOrderPinCard(Map<String, dynamic> orderData) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.redAccent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pin, color: Colors.white),
                SizedBox(width: 8),
                Text('Delivery PIN:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            SizedBox(height: 8),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  orderData['order_pin'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Do not share this PIN before the delivery agent asks for it in person.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}