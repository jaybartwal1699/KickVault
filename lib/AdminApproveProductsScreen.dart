import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Admin_Drawer.dart';
import 'admin_screen.dart';

class AdminApproveProductsScreen extends StatefulWidget {
  @override
  _AdminApproveProductsScreenState createState() => _AdminApproveProductsScreenState();
}

class _AdminApproveProductsScreenState extends State<AdminApproveProductsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Function to approve a product
  Future<void> approveProduct(String productId, BuildContext context) async {
    try {
      await firestore.collection('Products').doc(productId).update({
        'status': 'active',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product approved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to reject a product
  Future<void> rejectProduct(String productId, BuildContext context) async {
    try {
      await firestore.collection('Products').doc(productId).update({
        'status': 'rejected',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product rejected successfully!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to fetch store name, category name, and verification status
  Future<Map<String, dynamic>> fetchStoreAndCategory(String sellerId, String categoryId) async {
    try {
      final sellerDoc = await firestore.collection('seller_details').doc(sellerId).get();
      final categoryDoc = await firestore.collection('Categories').doc(categoryId).get();

      return {
        'storeName': sellerDoc.data()?['business_details']?['store_name'] ?? 'Unknown Store',
        'categoryName': categoryDoc.data()?['name'] ?? 'Unknown Category',
        'verificationStatus': sellerDoc.data()?['verification_status'] ?? 'pending', // Added verification status
      };
    } catch (e) {
      return {
        'storeName': 'Error fetching store',
        'categoryName': 'Error fetching category',
        'verificationStatus': 'error', // Added error state for verification status
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Approve Products',
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

      // Show Drawer on Mobile, no drawer on Web
      drawer: kIsWeb ? null : const Admin_Drawer(currentScreen: 'Approve Products'),

      // For web, use Row layout with sidebar
      body: kIsWeb
          ? _buildWebLayout(context) // Web layout
          : _buildMobileLayout(context), // Mobile layout
    );
  }

  // Web layout with sidebar
  Widget _buildWebLayout(BuildContext context) {
    return Row(
      children: [
        // Web Sidebar with current screen highlighted
        const WebAdminSidebar(currentScreen: 'Approve Products'),

        // Main content area
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  // Mobile layout (just the main content)
  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: Colors.grey[50], // Light gray background for better aesthetics
      child: _buildMainContent(),
    );
  }

  // Styled section header
  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Widget to display verification status badge
  Widget _buildVerificationBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label = 'Verified';
        icon = Icons.verified;
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = 'Pending';
        icon = Icons.pending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Main content area extracted to avoid duplication
  Widget _buildMainContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('Products').where('status', isEqualTo: 'panding').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 80),
                const SizedBox(height: 16),
                Text(
                  'No products pending approval',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When sellers submit new products, they will appear here',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Review Queue',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${products.length} products waiting for review',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(thickness: 1),

              // Products list
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemBuilder: (context, index) {
                    final product = products[index].data() as Map<String, dynamic>;
                    final productId = products[index].id;
                    final sellerId = product['seller_id'];
                    final categoryId = product['category_id'];

                    return FutureBuilder<Map<String, dynamic>>(
                      future: fetchStoreAndCategory(sellerId, categoryId),
                      builder: (context, futureSnapshot) {
                        if (futureSnapshot.connectionState == ConnectionState.waiting) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 3,
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        if (futureSnapshot.hasError) {
                          return const Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Error loading product data'),
                            ),
                          );
                        }

                        final storeName = futureSnapshot.data?['storeName'] ?? 'Unknown Store';
                        final categoryName = futureSnapshot.data?['categoryName'] ?? 'Unknown Category';
                        final verificationStatus = futureSnapshot.data?['verificationStatus'] ?? 'pending';

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                          ),
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Header with store info
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ?? 'No Name',
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.store, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                storeName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Added verification status badge
                                              _buildVerificationBadge(verificationStatus),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        categoryName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Product Images
                              if (product['images'] != null && product['images'].isNotEmpty)
                                Container(
                                  height: 220,
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: product['images'].length,
                                    itemBuilder: (context, i) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                        width: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            product['images'][i],
                                            height: 200,
                                            width: 200,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 200,
                                                width: 200,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // Product Details
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Description
                                    _buildSectionHeader('Description'),
                                    Text(
                                      product['description'] ?? 'No Description',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 16),

                                    // Price and Discount
                                    _buildSectionHeader('Pricing'),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 16, color: Colors.black),
                                            children: [
                                              const TextSpan(
                                                text: 'Price: ',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: '₹${product['price']}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (product['metadata']?['hasDiscount'] == true)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.red[100]!),
                                            ),
                                            child: Text(
                                              'Discount: ${product['discount']}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Colors with names and images
                                    if (product['colors'] != null && product['colors'].isNotEmpty) ...[
                                      _buildSectionHeader('Available Colors'),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          ...product['colors'].map<Widget>((color) {
                                            return Container(
                                              width: 120,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Image.network(
                                                      color['colorImage'],
                                                      height: 30,
                                                      width: 30,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Container(
                                                            height: 30,
                                                            width: 30,
                                                            color: Colors.grey[300],
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      color['colorName'] ?? 'Unknown',
                                                      style: const TextStyle(fontSize: 12),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Sizes with stock
                                    if (product['sizes'] != null && product['sizes'].isNotEmpty) ...[
                                      _buildSectionHeader('Available Sizes'),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          ...product['sizes'].map<Widget>((size) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Size: ${size['size']}, Stock: ${size['stock']}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Product Details
                                    if (product['details'] != null) ...[
                                      _buildSectionHeader('Product Specifications'),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ...product['details'].entries.map<Widget>((entry) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width: 120,
                                                      child: Text(
                                                        '${entry.key}:',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black54,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        '${entry.value}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Approve and Reject Buttons
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => rejectProduct(productId, context),
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => approveProduct(productId, context),
                                      icon: const Icon(Icons.check,color: Colors.white,),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }
}