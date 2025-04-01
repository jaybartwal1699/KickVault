import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'admin_screen.dart';

class SellerManagementScreen extends StatefulWidget {
  @override
  _SellerManagementScreenState createState() => _SellerManagementScreenState();
}

class _SellerManagementScreenState extends State<SellerManagementScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> allSellers = [];

  @override
  void initState() {
    super.initState();
    loadSellers();
  }

  Future<void> loadSellers() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> sellers = await fetchSellers();
      setState(() {
        allSellers = sellers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading sellers: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSellers() async {
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'seller')
        .get();

    List<Map<String, dynamic>> sellersList = [];

    for (var doc in userSnapshot.docs) {
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

      // Fetch seller details
      String sellerId = userData['uid'] ?? '';
      DocumentSnapshot sellerSnapshot =
      await FirebaseFirestore.instance.collection('seller_details').doc(sellerId).get();
      Map<String, dynamic>? sellerData = sellerSnapshot.data() as Map<String, dynamic>?;

      // Format timestamps
      Timestamp? createdAt = userData['created_at'] as Timestamp?;

      // Add seller to list
      sellersList.add({
        'user_id': sellerId,
        'name': userData['name'] ?? 'Unknown',
        'email': userData['email'] ?? 'Unknown',
        'phone': userData['phone'] ?? 'Unknown',
        'profile_image': userData['profile_image'] ?? '',
        'created_at': createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate()) : 'N/A',

        // Seller details
        'store_name': sellerData?['business_details']?['store_name'] ?? 'Unknown',
        'business_type': sellerData?['business_details']?['business_type'] ?? 'Unknown',
        'store_description': sellerData?['business_details']?['store_description'] ?? 'Unknown',
        'logo_url': sellerData?['store_profile']?['logo_url'] ?? '',
        'verification_status': sellerData?['verification']?['verification_status'] ?? 'Not Verified',
        'bank_account_number': sellerData?['banking_details']?['bank_account_number'] ?? 'N/A',
        'bank_name': sellerData?['banking_details']?['bank_name'] ?? 'N/A',
        'payment_method': sellerData?['banking_details']?['payment_method'] ?? 'N/A',
        'tax_number': sellerData?['compliance']?['tax_number'] ?? 'N/A',
        'categories': sellerData?['store_profile']?['categories'] ?? [],
      });
    }

    return sellersList;
  }

  @override
  Widget build(BuildContext context) {
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
            'Seller Management',
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
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh, color: Colors.white),
        //     onPressed: loadOrders,
        //     tooltip: 'Refresh Orders',
        //   ),
        // ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by seller name, email, or store name',
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
              'Showing ${allSellers.length} sellers',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            // Sellers data table
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : allSellers.isEmpty
                  ? Center(child: Text('No sellers found'))
                  : _buildSellersTable(allSellers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellersTable(List<Map<String, dynamic>> sellers) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          dataRowHeight: 72,
          columns: [
            DataColumn(label: Text('Seller ID')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Store Name')),
            DataColumn(label: Text('Business Type')),
            DataColumn(label: Text('Verification Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: sellers.map((seller) {
            return DataRow(
              cells: [
                DataCell(
                  Text(seller['user_id'], style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataCell(
                  Row(
                    children: [
                      seller['profile_image'].isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          seller['profile_image'],
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
                        child: Icon(Icons.person, size: 20),
                      ),
                      SizedBox(width: 8),
                      Text(seller['name']),
                    ],
                  ),
                ),
                DataCell(Text(seller['email'])),
                DataCell(Text(seller['phone'])),
                DataCell(Text(seller['store_name'])),
                DataCell(Text(seller['business_type'])),
                DataCell(
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: seller['verification_status'] == 'approved'
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      seller['verification_status'],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.visibility, color: Colors.blue),
                    tooltip: 'View Details',
                    onPressed: () {
                      _showSellerDetailsDialog(context, seller);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSellerDetailsDialog(BuildContext context, Map<String, dynamic> seller) {
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
                    'Seller Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              Divider(height: 32),

              // Seller summary
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seller and business information
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Seller info
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Seller Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    _detailItem('Name', seller['name']),
                                    _detailItem('Email', seller['email']),
                                    _detailItem('Phone', seller['phone']),
                                    _detailItem('User ID', seller['user_id']),
                                    _detailItem('Created At', seller['created_at']),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 16),

                          // Right column - Business info
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Business Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    _detailItem('Store Name', seller['store_name']),
                                    _detailItem('Business Type', seller['business_type']),
                                    _detailItem('Store Description', seller['store_description']),
                                    _detailItem('Categories', seller['categories'].join(', ')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Banking and verification information
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Banking info
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Banking Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    _detailItem('Bank Account Number', seller['bank_account_number']),
                                    _detailItem('Bank Name', seller['bank_name']),
                                    _detailItem('Payment Method', seller['payment_method']),
                                    _detailItem('Tax Number', seller['tax_number']),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 16),

                          // Right column - Verification info
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Verification Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    _detailItem('Verification Status', seller['verification_status']),
                                  ],
                                ),
                              ),
                            ),
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
}