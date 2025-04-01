import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> customerData;
  final Map<String, dynamic> sellerData;
  final Map<String, dynamic> productData;

  const OrderDetailsScreen({
    Key? key,
    required this.orderData,
    required this.customerData,
    required this.sellerData,
    required this.productData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 🏷 Product Details
            _buildSectionHeader("Product Details"),
            _buildDetailRow("Product Name", productData['name']),
            _buildDetailRow("Size", orderData['size']),
            _buildDetailRow("Color", orderData['color']),
            _buildDetailRow("Price", "₹${orderData['price']}"),
            _buildImage(productData['images'][0]),

            // 📦 Order Details
            _buildSectionHeader("Order Details"),
            _buildDetailRow("Order Status", orderData['order_status']),
            _buildDetailRow("Payment Method", orderData['payment_method']),
            _buildDetailRow("Payment Status", orderData['payment_status']),
            _buildDetailRow("Order Date", orderData['created_at'].toDate().toString()),

            // 🏠 Customer Details
            _buildSectionHeader("Customer Details"),
            _buildDetailRow("Customer Name", customerData['name']),
            _buildDetailRow("Phone", customerData['phone']),
            _buildDetailRow("Address", "${orderData['shipping_address']['line1']}, ${orderData['shipping_address']['city']}, ${orderData['shipping_address']['state']}"),

            // 🏪 Seller Details
            _buildSectionHeader("Seller Details"),
            _buildDetailRow("Store Name", sellerData['store_name']),
            _buildDetailRow("Seller Name", sellerData['name']),
            _buildDetailRow("Business Email", sellerData['contact']['business_email']),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Image.network(imageUrl, height: 150, fit: BoxFit.cover),
    );
  }
}
