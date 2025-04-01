import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Seller_Drawer.dart';

class SellerInfoScreen extends StatefulWidget {
  const SellerInfoScreen({Key? key}) : super(key: key);

  @override
  _SellerInfoScreenState createState() => _SellerInfoScreenState();
}

class _SellerInfoScreenState extends State<SellerInfoScreen> {
  bool isLoading = true;
  Map<String, dynamic>? sellerInfo;

  @override
  void initState() {
    super.initState();
    fetchSellerInfo();
  }

  Future<void> fetchSellerInfo() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('seller_details')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          setState(() {
            sellerInfo = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No seller info found.')),
          );
        }
      }
    } catch (e) {
      print('Error fetching seller info: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching seller info: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black, // Set AppBar color to black
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
        title: Text(
          'Seller Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Set text color to white
          ),
        ),
      ),

      drawer: SellerDrawer(currentScreen: 'Seller Info'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sellerInfo != null
          ? SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildContent(),
          ],
        ),
      )
          : Center(
        child: Text(
          'No seller information available.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (sellerInfo!['store_profile']['logo_url'] != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!, width: 4),
                image: DecorationImage(
                  image: NetworkImage(sellerInfo!['store_profile']['logo_url']),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: Icon(Icons.store, size: 60, color: Colors.grey[400]),
            ),
          const SizedBox(height: 16),
          Text(
            sellerInfo!['business_details']['store_name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sellerInfo!['business_details']['business_type'],
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildVerificationStatus(),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    final status = sellerInfo!['verification']['verification_status'];
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified_rounded;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.verified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection(
            'Business Information',
            [
              _buildInfoTile('Store Description',
                  sellerInfo!['business_details']['store_description'],
                  Icons.description),
              _buildInfoTile('Categories',
                  (sellerInfo!['store_profile']['categories'] as List).join(
                      ', '),
                  Icons.category),
            ],
          ),
          _buildSection(
            'Contact Details',
            [
              _buildInfoTile('Name', sellerInfo!['name'], Icons.person),
              _buildInfoTile('Email', sellerInfo!['email'], Icons.email),
              _buildInfoTile('Business Email',
                  sellerInfo!['contact']['business_email'],
                  Icons.alternate_email),
              _buildInfoTile('Business Phone',
                  sellerInfo!['contact']['business_phone'],
                  Icons.phone),
            ],
          ),
          _buildSection(
            'Banking Information',
            [
              _buildInfoTile('Bank Name',
                  sellerInfo!['banking_details']['bank_name'],
                  Icons.account_balance),
              _buildInfoTile('Account Number',
                  sellerInfo!['banking_details']['bank_account_number'],
                  Icons.credit_card,
                  isSecure: true),
              _buildInfoTile('Payment Method',
                  sellerInfo!['banking_details']['payment_method'],
                  Icons.payments),
            ],
          ),
          _buildSection(
            'Compliance',
            [
              _buildInfoTile('Tax Number',
                  sellerInfo!['compliance']['tax_number'],
                  Icons.receipt_long),
              _buildInfoTile('Terms Acceptance',
                  sellerInfo!['compliance']['agrees_to_terms']
                      ? 'Accepted'
                      : 'Not Accepted',
                  Icons.gavel),
            ],
          ),
          if (sellerInfo!['verification']['govt_id_url'] != null ||
              sellerInfo!['verification']['address_proof_url'] != null)
            _buildDocumentsSection(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon,
      {bool isSecure = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.green, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      subtitle: Text(
        isSecure ? '••••${value.substring(value.length - 4)}' : (value
            .isNotEmpty ? value : 'Not available'),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ... previous code remains same until _buildDocumentsSection() ...

  Widget _buildDocumentsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 220, // Fixed height for the documents section
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (sellerInfo!['verification']['govt_id_url'] != null)
                    Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.7, // 70% of screen width
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildDocumentCard(
                        'Government ID',
                        sellerInfo!['verification']['govt_id_url'],
                        Icons.badge,
                      ),
                    ),
                  if (sellerInfo!['verification']['address_proof_url'] != null)
                    Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.7, // 70% of screen width
                      child: _buildDocumentCard(
                        'Address Proof',
                        sellerInfo!['verification']['address_proof_url'],
                        Icons.home,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDocumentCard(String title, String url, IconData icon) {
    return FutureBuilder<String>(
      future: _getFileType(url), // Fetch file type metadata
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        bool isPdf = snapshot.data == 'application/pdf';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                isPdf
                    ? Column(
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text(
                      'PDF Document',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Uri pdfUri = Uri.parse(url);
                        if (await canLaunchUrl(pdfUri)) {
                          await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open PDF')),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      label: const Text('Open PDF', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Fetch file metadata from Firebase Storage
  Future<String> _getFileType(String url) async {
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(url);
      final metadata = await storageRef.getMetadata();
      return metadata.contentType ?? ''; // e.g., 'application/pdf' or 'image/jpeg'
    } catch (e) {
      print('Error fetching metadata: $e');
      return '';
    }
  }



// ... rest of the code remains same ...
}