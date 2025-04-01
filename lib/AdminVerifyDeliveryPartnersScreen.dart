import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Admin_Drawer.dart';
import 'admin_screen.dart';

class AdminVerifyDeliveryPartnersScreen extends StatefulWidget {
  @override
  _AdminVerifyDeliveryPartnersScreenState createState() =>
      _AdminVerifyDeliveryPartnersScreenState();
}

class _AdminVerifyDeliveryPartnersScreenState
    extends State<AdminVerifyDeliveryPartnersScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Function to verify a delivery partner
  Future<void> verifyPartner(String partnerId, BuildContext context) async {
    try {
      await firestore.collection('users').doc(partnerId).update({
        'is_verified': 'true',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery partner verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying delivery partner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to reject a delivery partner
  Future<void> rejectPartner(String partnerId, BuildContext context) async {
    try {
      await firestore.collection('users').doc(partnerId).update({
        'is_verified': 'false',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery partner rejected successfully!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting delivery partner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verify Delivery Partners',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),

      // Show Drawer on Mobile, no drawer on Web
      drawer: kIsWeb ? null : const Admin_Drawer(currentScreen: 'Verify Delivery Partners'),

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
        const WebAdminSidebar(currentScreen: 'Verify Delivery Partners'),

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
  String _formatAddress(Map<String, dynamic> addressMap) {
    final line1 = addressMap['line1'] ?? '';
    final line2 = addressMap['line2'] ?? '';
    final city = addressMap['city'] ?? '';
    final state = addressMap['state'] ?? '';
    final zipcode = addressMap['zipcode'] ?? '';

    return '$line1, $line2, $city, $state - $zipcode'
        .replaceAll(RegExp(r', ,'), ',')  // Remove empty parts
        .replaceAll(RegExp(r',,'), ',')
        .replaceAll(RegExp(r' - $'), ''); // Remove trailing dash if zipcode empty
  }

  // Main content area
  Widget _buildMainContent() {
    return StreamBuilder(
      stream: firestore
          .collection('users')
          .where('role', isEqualTo: 'delivery_partner')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                  'Error loading delivery partners',
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
                const Icon(Icons.people_alt_outlined, color: Colors.grey, size: 80),
                const SizedBox(height: 16),
                Text(
                  'No delivery partners to verify',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When new delivery partners register, they will appear here',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        var partners = snapshot.data!.docs;

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
                      'Delivery Partner Verification Queue',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${partners.length} delivery partners waiting for verification',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(thickness: 1),

              // Partners list
              Expanded(
                child: ListView.builder(
                  itemCount: partners.length,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemBuilder: (context, index) {
                    var partner = partners[index];
                    return FutureBuilder(
                      future: firestore
                          .collection('Delivery_partner_detail')
                          .doc(partner['uid'])
                          .get(),
                      builder: (context, AsyncSnapshot<DocumentSnapshot> detailSnapshot) {
                        if (detailSnapshot.connectionState == ConnectionState.waiting) {
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

                        String? documentImage = detailSnapshot.data?.exists == true
                            ? detailSnapshot.data!['document_image']
                            : null;

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
                              // Partner Header with personal info
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
                                            partner['name'] ?? 'No Name',
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                partner['phone'] ?? 'No Phone',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
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
                                        color: partner['is_verified'] == 'true'
                                            ? Colors.green[100]
                                            : partner['is_verified'] == 'false'
                                            ? Colors.red[100]
                                            : Colors.orange[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        partner['is_verified'] == 'true'
                                            ? 'Verified'
                                            : partner['is_verified'] == 'false'
                                            ? 'Rejected'
                                            : 'Pending',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: partner['is_verified'] == 'true'
                                              ? Colors.green[800]
                                              : partner['is_verified'] == 'false'
                                              ? Colors.red[800]
                                              : Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Partner Details
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Contact Information
                                    _buildSectionHeader('Contact Information'),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Email: ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  partner['email'] ?? 'No Email',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Phone: ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              Text(
                                                partner['phone'] ?? 'No Phone',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          if (partner['address'] != null) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Address: ',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    _formatAddress(partner['address']),
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // ID Document
                                    _buildSectionHeader('Verification Document'),
                                    documentImage != null
                                        ? Container(
                                      height: 300,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          documentImage,
                                          fit: BoxFit.contain,
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
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Failed to load image',
                                                    style: TextStyle(color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                        : Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No Document Uploaded',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'The delivery partner has not uploaded any verification documents',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Additional details if available

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
                                      onPressed: () => rejectPartner(partner['uid'], context),
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
                                      onPressed: () => verifyPartner(partner['uid'], context),
                                      icon: const Icon(Icons.check, color: Colors.white),
                                      label: const Text('Verify'),
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