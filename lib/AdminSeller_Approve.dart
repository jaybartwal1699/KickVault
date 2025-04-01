import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import 'Admin_Drawer.dart';
import 'admin_screen.dart';

class AdminSeller_Approve extends StatelessWidget {
  const AdminSeller_Approve({Key? key}) : super(key: key);

  Future<String> _fetchUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(
          userId).get();
      return userDoc.exists
          ? userDoc['name'] ?? 'Unknown User'
          : 'Unknown User';
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  Future<void> requestStoragePermission() async {
    // Request storage permission
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      print("Storage permission granted!");
    } else if (status.isDenied) {
      print("Storage permission denied!");
      // Optionally, you can show a message prompting the user to grant permission
    } else if (status.isPermanentlyDenied) {
      print(
          "Storage permission permanently denied. User needs to manually enable it in settings.");
      openAppSettings(); // This opens the app's settings to allow the user to enable the permission manually
    } else if (status.isRestricted) {
      print(
          "Storage permission is restricted, possibly due to parental controls or other restrictions.");
    }
  }




  Future<void> _approveSeller(BuildContext context, String sellerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('seller_details')
          .doc(sellerId)
          .update({
        'verification.verification_status': 'approved',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller approved successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving seller: $e')),
        );
      }
    }
  }

  // Add downloadFile method
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        // For Android 10 and above, also request manage external storage permission
        if (await Permission.manageExternalStorage
            .request()
            .isGranted) {
          return true;
        }
      }
      return false;
    }
    return true; // For iOS, return true as we don't need explicit storage permission
  }

// 2. Update the downloadFile method
  Future<void> downloadFile(BuildContext context, String url,
      String fileName) async {
    try {
      final permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permissions are required')),
          );
        }
        return;
      }

      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      final dio = Dio();
      dio.options.headers = {
        'Accept': '*/*',
        'Content-Type': 'application/octet-stream',
      };

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
                'Download Progress: ${(received / total * 100).toStringAsFixed(
                    0)}%');
          }
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File downloaded successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    }
  }


// Add this utility function at the top of your file
  Future<bool> checkFileType(String url) async {
    try {
      final dio = Dio();
      // First, try to do a HEAD request to check content type
      final response = await dio.head(url);
      final contentType = response.headers.value('content-type');

      if (contentType != null) {
        debugPrint('Content-Type from header: $contentType');
        return contentType.toLowerCase().contains('pdf');
      }
    } catch (e) {
      debugPrint('Error checking content type: $e');
    }

    // Fallback to checking URL
    return url.toLowerCase().contains('pdf') ||
        url.toLowerCase().contains('application/pdf');
  }

  Future<String> _downloadPDF(String url) async {
    try {
      final permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        throw Exception('Storage permissions not granted');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'document_${DateTime
          .now()
          .millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      debugPrint('Starting PDF download from: $url');
      debugPrint('Saving to: $filePath');

      final dio = Dio();
      dio.options.headers = {
        'Accept': 'application/pdf',
        'Content-Type': 'application/pdf',
      };

      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 0) {
            return filePath;
          }
          throw Exception('Downloaded file is empty');
        }
        throw Exception('File was not created');
      }
      throw Exception('Failed to download file: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      throw Exception('Failed to download PDF: $e');
    }
  }

  void _showDocumentDialog(BuildContext context, String title, String fileUrl,
      String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          FutureBuilder<bool>(
            future: checkFileType(fileUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Dialog(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Checking document type...'),
                      ],
                    ),
                  ),
                );
              }

              final isPdf = snapshot.data ?? false;
              debugPrint('Is PDF file: $isPdf');

              return Dialog(
                backgroundColor: Colors.white,
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.8,
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * 0.8,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () async {
                              final permissionGranted = await requestPermissions();
                              if (!permissionGranted) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text(
                                        'Storage permissions are required')),
                                  );
                                }
                                return;
                              }
                              downloadFile(context, fileUrl, fileName);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      // Document viewer
                      Expanded(
                        child: isPdf
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'PDF document',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(
                                Icons.open_in_browser,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Open in Browser',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () async {
                                try {
                                  final uri = Uri.parse(fileUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          'Could not open the PDF')),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error opening PDF: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Error opening PDF: $e')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        )
                            : LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: FutureBuilder<Size>(
                                  future: _getImageSize(fileUrl),
                                  builder: (context, sizeSnapshot) {
                                    if (sizeSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    return InteractiveViewer(
                                      panEnabled: true,
                                      boundaryMargin: const EdgeInsets.all(20),
                                      minScale: 0.1,
                                      maxScale: 4.0,
                                      child: Center(
                                        child: Image.network(
                                          fileUrl,
                                          fit: BoxFit.contain,
                                          width: constraints.maxWidth,
                                          height: constraints.maxHeight,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .center,
                                                children: [
                                                  CircularProgressIndicator(
                                                    value: loadingProgress
                                                        .expectedTotalBytes !=
                                                        null
                                                        ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                      'Loading image...'),
                                                ],
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            debugPrint('Image Error: $error');
                                            return const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .center,
                                                children: [
                                                  Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.red,
                                                    size: 48,
                                                  ),
                                                  SizedBox(height: 16),
                                                  Text(
                                                    'Failed to load image',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

// Helper method to pre-load the image and get its dimensions
  Future<Size> _getImageSize(String imageUrl) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.network(imageUrl);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );
    return completer.future;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Seller Approval',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Show Drawer on Mobile, no drawer on Web
      drawer: kIsWeb ? null : const Admin_Drawer(currentScreen: 'Seller Approval'),

      // For web, use Row layout with sidebar
      body: kIsWeb
          ? _buildWebLayout(context) // Web layout
          : _buildMobileLayout(context), // Mobile layout
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Row(
      children: [
        // Web Sidebar with current screen highlighted
        const WebAdminSidebar(currentScreen: 'Seller Approval'),

        // Main content area
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: Colors.black,
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
                    .collection('seller_details')
                    .where('verification.verification_status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        )
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 60, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            'No Pending Seller Requests',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final seller = snapshot.data!.docs[index];
                      final data = seller.data() as Map<String, dynamic>;
                      final contact = data['contact'] as Map<String, dynamic>;
                      final business = data['business_details'] as Map<String,
                          dynamic>;
                      final verification = data['verification'] as Map<String,
                          dynamic>;
                      final userId = data['user_id'] ?? '';

                      return FutureBuilder<String>(
                        future: _fetchUserName(userId),
                        builder: (context, userSnapshot) {
                          final userName = userSnapshot.data ?? 'Fetching...';

                          return Card(
                            color: Colors.white,
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Store Info Section
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          data['store_profile']['logo_url'] ?? '',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error,
                                              stackTrace) =>
                                              Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                    Icons.store, size: 40,
                                                    color: Colors.black54),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              'STORE \nINFORMATION',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              business['store_name'] ??
                                                  'No store name',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.person, size: 16,
                                                    color: Colors.black54),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Owner: $userName',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.business_center, size: 16, color: Colors.black54),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Type: ${business['business_type'] ?? 'Not specified'}',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.grey[800],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(height: 32, thickness: 1),

                                  // Contact Information Section
                                  Text(
                                    'CONTACT DETAILS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _buildInfoChip(Icons.phone, contact['business_phone'], 'Phone'),
                                      _buildInfoChip(Icons.email, contact['business_email'], 'Email'),

                                      _buildInfoChip(Icons.location_on, null, 'Address', userId: data['user_id']),


                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Store Description Section
                                  Text(
                                    'STORE DESCRIPTION',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Text(
                                      business['store_description'] ??
                                          'No description provided',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[850],
                                        height: 1.4,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Categories Section
                                  Text(
                                    'STORE CATEGORIES',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: (data['store_profile']['categories'] as List)
                                        .asMap()
                                        .map((index, category) => MapEntry(
                                      index,
                                      Chip(
                                        label: Text(
                                          '${index + 1}. ${category.toString()}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        backgroundColor: Colors.grey[200],
                                        side: BorderSide(color: Colors.grey[300]!),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                    ))
                                        .values
                                        .toList(),
                                  ),


                                  const SizedBox(height: 24),

                                  // Verification Documents Section
                                  Text(
                                    'VERIFICATION DOCUMENTS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showDocumentDialog(
                                                context,
                                                'Government ID',
                                                verification['govt_id_url'],
                                                'govt_id.jpg',
                                              ),
                                          icon: const Icon(
                                            Icons.description,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'View Government ID',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            side: const BorderSide(
                                                color: Colors.black, width: 1.5),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showDocumentDialog(
                                                context,
                                                'Address Proof',
                                                verification['address_proof_url'],
                                                'address_proof.jpg',
                                              ),
                                          icon: const Icon(
                                            Icons.house,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'View Address Proof',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            side: const BorderSide(
                                                color: Colors.black, width: 1.5),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Verification Status Section
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.pending_actions,
                                          color: Colors.amber,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment
                                                .start,
                                            children: [
                                              const Text(
                                                'VERIFICATION STATUS',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                verification['verification_status']
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Action Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _approveSeller(context, seller.id),
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      label: const Text(
                                        'APPROVE SELLER',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },


          );
        }
  }



  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Center(
  //         child: Text(
  //           'Seller Approval',
  //           style: GoogleFonts.nunitoSans(
  //             fontWeight: FontWeight.w900,
  //             fontSize: 26,
  //             color: Colors.white,
  //             letterSpacing: 0.8,
  //           ),
  //         ),
  //       ),
  //       backgroundColor: Colors.black,
  //       elevation: 2,
  //       iconTheme: const IconThemeData(color: Colors.white),
  //     ),
  //
  //     drawer: kIsWeb ? null : const Admin_Drawer(
  //         currentScreen: 'Seller Approval'),
  //     body: Container(
  //       color: Colors.black,
  //       child: StreamBuilder<QuerySnapshot>(
  //         stream: FirebaseFirestore.instance
  //             .collection('seller_details')
  //             .where('verification.verification_status', isEqualTo: 'pending')
  //             .snapshots(),
  //         builder: (context, snapshot) {
  //           if (snapshot.hasError) {
  //             return Center(child: Text('Error: ${snapshot.error}'));
  //           }
  //
  //           if (snapshot.connectionState == ConnectionState.waiting) {
  //             return const Center(
  //                 child: CircularProgressIndicator(
  //                   color: Colors.black,
  //                 )
  //             );
  //           }
  //
  //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //             return Center(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Icon(Icons.info_outline, size: 60, color: Colors.grey[700]),
  //                   const SizedBox(height: 16),
  //                   Text(
  //                     'No Pending Seller Requests',
  //                     style: TextStyle(
  //                       fontSize: 20,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.grey[800],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }
  //
  //           return ListView.builder(
  //             itemCount: snapshot.data!.docs.length,
  //             padding: const EdgeInsets.all(16.0),
  //             itemBuilder: (context, index) {
  //               final seller = snapshot.data!.docs[index];
  //               final data = seller.data() as Map<String, dynamic>;
  //               final contact = data['contact'] as Map<String, dynamic>;
  //               final business = data['business_details'] as Map<String,
  //                   dynamic>;
  //               final verification = data['verification'] as Map<String,
  //                   dynamic>;
  //               final userId = data['user_id'] ?? '';
  //
  //               return FutureBuilder<String>(
  //                 future: _fetchUserName(userId),
  //                 builder: (context, userSnapshot) {
  //                   final userName = userSnapshot.data ?? 'Fetching...';
  //
  //                   return Card(
  //                     color: Colors.white,
  //                     elevation: 4,
  //                     margin: const EdgeInsets.only(bottom: 20),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(12),
  //                       side: BorderSide(color: Colors.grey[300]!, width: 1),
  //                     ),
  //                     child: Padding(
  //                       padding: const EdgeInsets.all(20.0),
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           // Store Info Section
  //                           Row(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               ClipRRect(
  //                                 borderRadius: BorderRadius.circular(12),
  //                                 child: Image.network(
  //                                   data['store_profile']['logo_url'] ?? '',
  //                                   width: 100,
  //                                   height: 100,
  //                                   fit: BoxFit.contain,
  //                                   errorBuilder: (context, error,
  //                                       stackTrace) =>
  //                                       Container(
  //                                         width: 100,
  //                                         height: 100,
  //                                         color: Colors.grey[300],
  //                                         child: const Icon(
  //                                             Icons.store, size: 40,
  //                                             color: Colors.black54),
  //                                       ),
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 20),
  //                               Expanded(
  //                                 child: Column(
  //                                   crossAxisAlignment: CrossAxisAlignment
  //                                       .start,
  //                                   children: [
  //                                     Text(
  //                                       'STORE \nINFORMATION',
  //                                       style: TextStyle(
  //                                         fontSize: 15,
  //                                         fontWeight: FontWeight.w900,
  //                                         color: Colors.black,
  //                                         letterSpacing: 1.2,
  //                                       ),
  //                                     ),
  //                                     const SizedBox(height: 8),
  //                                     Text(
  //                                       business['store_name'] ??
  //                                           'No store name',
  //                                       style: const TextStyle(
  //                                         fontSize: 22,
  //                                         fontWeight: FontWeight.bold,
  //                                         color: Colors.black,
  //                                       ),
  //                                     ),
  //                                     const SizedBox(height: 8),
  //                                     Row(
  //                                       children: [
  //                                         const Icon(Icons.person, size: 16,
  //                                             color: Colors.black54),
  //                                         const SizedBox(width: 4),
  //                                         Text(
  //                                           'Owner: $userName',
  //                                           style: TextStyle(
  //                                             fontSize: 15,
  //                                             color: Colors.grey[800],
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                     const SizedBox(height: 4),
  //                                     Row(
  //                                       children: [
  //                                         Icon(Icons.business_center, size: 16, color: Colors.black54),
  //                                         const SizedBox(width: 4),
  //                                         Expanded(
  //                                           child: Text(
  //                                             'Type: ${business['business_type'] ?? 'Not specified'}',
  //                                             style: TextStyle(
  //                                               fontSize: 15,
  //                                               color: Colors.grey[800],
  //                                             ),
  //                                             overflow: TextOverflow.ellipsis,
  //                                             maxLines: 1,
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //
  //                           const Divider(height: 32, thickness: 1),
  //
  //                           // Contact Information Section
  //                           Text(
  //                             'CONTACT DETAILS',
  //                             style: TextStyle(
  //                               fontSize: 12,
  //                               fontWeight: FontWeight.w900,
  //                               color: Colors.black,
  //                               letterSpacing: 1.2,
  //                             ),
  //                           ),
  //                           const SizedBox(height: 12),
  //                           Wrap(
  //                             spacing: 12,
  //                             runSpacing: 12,
  //                             children: [
  //                               _buildInfoChip(
  //                                   Icons.email, contact['business_email'],
  //                                   'Email'),
  //                               _buildInfoChip(
  //                                   Icons.phone, contact['business_phone'],
  //                                   'Phone'),
  //                               _buildInfoChip(Icons.location_on,
  //                                   business['address'] ?? 'Not provided',
  //                                   'Address'),
  //                             ],
  //                           ),
  //
  //                           const SizedBox(height: 24),
  //
  //                           // Store Description Section
  //                           Text(
  //                             'STORE DESCRIPTION',
  //                             style: TextStyle(
  //                               fontSize: 12,
  //                               fontWeight: FontWeight.w900,
  //                               color: Colors.black,
  //                               letterSpacing: 1.2,
  //                             ),
  //                           ),
  //                           const SizedBox(height: 8),
  //                           Container(
  //                             padding: const EdgeInsets.all(12),
  //                             decoration: BoxDecoration(
  //                               color: Colors.grey[50],
  //                               borderRadius: BorderRadius.circular(8),
  //                               border: Border.all(color: Colors.grey[200]!),
  //                             ),
  //                             child: Text(
  //                               business['store_description'] ??
  //                                   'No description provided',
  //                               style: TextStyle(
  //                                 fontSize: 15,
  //                                 color: Colors.grey[850],
  //                                 height: 1.4,
  //                               ),
  //                             ),
  //                           ),
  //
  //                           const SizedBox(height: 24),
  //
  //                           // Categories Section
  //                           Text(
  //                             'STORE CATEGORIES',
  //                             style: TextStyle(
  //                               fontSize: 12,
  //                               fontWeight: FontWeight.w900,
  //                               color: Colors.black,
  //                               letterSpacing: 1.2,
  //                             ),
  //                           ),
  //                           const SizedBox(height: 12),
  //                           Wrap(
  //                             spacing: 8,
  //                             runSpacing: 8,
  //                             children: (data['store_profile']['categories'] as List)
  //                                 .asMap()
  //                                 .map((index, category) => MapEntry(
  //                               index,
  //                               Chip(
  //                                 label: Text(
  //                                   '${index + 1}. ${category.toString()}',
  //                                   style: const TextStyle(
  //                                     fontSize: 13,
  //                                     fontWeight: FontWeight.w500,
  //                                   ),
  //                                 ),
  //                                 backgroundColor: Colors.grey[200],
  //                                 side: BorderSide(color: Colors.grey[300]!),
  //                                 padding: const EdgeInsets.symmetric(horizontal: 4),
  //                               ),
  //                             ))
  //                                 .values
  //                                 .toList(),
  //                           ),
  //
  //
  //                           const SizedBox(height: 24),
  //
  //                           // Verification Documents Section
  //                           Text(
  //                             'VERIFICATION DOCUMENTS',
  //                             style: TextStyle(
  //                               fontSize: 12,
  //                               fontWeight: FontWeight.w900,
  //                               color: Colors.black,
  //                               letterSpacing: 1.2,
  //                             ),
  //                           ),
  //                           const SizedBox(height: 12),
  //                           Row(
  //                             children: [
  //                               Expanded(
  //                                 child: OutlinedButton.icon(
  //                                   onPressed: () =>
  //                                       _showDocumentDialog(
  //                                         context,
  //                                         'Government ID',
  //                                         verification['govt_id_url'],
  //                                         'govt_id.jpg',
  //                                       ),
  //                                   icon: const Icon(
  //                                     Icons.description,
  //                                     color: Colors.black,
  //                                     size: 20,
  //                                   ),
  //                                   label: const Text(
  //                                     'View Government ID',
  //                                     style: TextStyle(
  //                                         fontWeight: FontWeight.w600),
  //                                   ),
  //                                   style: OutlinedButton.styleFrom(
  //                                     foregroundColor: Colors.black,
  //                                     side: const BorderSide(
  //                                         color: Colors.black, width: 1.5),
  //                                     padding: const EdgeInsets.symmetric(
  //                                         vertical: 12, horizontal: 16),
  //                                     shape: RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.circular(8),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 12),
  //                               Expanded(
  //                                 child: OutlinedButton.icon(
  //                                   onPressed: () =>
  //                                       _showDocumentDialog(
  //                                         context,
  //                                         'Address Proof',
  //                                         verification['address_proof_url'],
  //                                         'address_proof.jpg',
  //                                       ),
  //                                   icon: const Icon(
  //                                     Icons.house,
  //                                     color: Colors.black,
  //                                     size: 20,
  //                                   ),
  //                                   label: const Text(
  //                                     'View Address Proof',
  //                                     style: TextStyle(
  //                                         fontWeight: FontWeight.w600),
  //                                   ),
  //                                   style: OutlinedButton.styleFrom(
  //                                     foregroundColor: Colors.black,
  //                                     side: const BorderSide(
  //                                         color: Colors.black, width: 1.5),
  //                                     padding: const EdgeInsets.symmetric(
  //                                         vertical: 12, horizontal: 16),
  //                                     shape: RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.circular(8),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //
  //                           const SizedBox(height: 24),
  //
  //                           // Verification Status Section
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                                 vertical: 12, horizontal: 16),
  //                             decoration: BoxDecoration(
  //                               color: Colors.amber[50],
  //                               borderRadius: BorderRadius.circular(8),
  //                               border: Border.all(color: Colors.amber[300]!),
  //                             ),
  //                             child: Row(
  //                               children: [
  //                                 const Icon(
  //                                   Icons.pending_actions,
  //                                   color: Colors.amber,
  //                                   size: 24,
  //                                 ),
  //                                 const SizedBox(width: 12),
  //                                 Expanded(
  //                                   child: Column(
  //                                     crossAxisAlignment: CrossAxisAlignment
  //                                         .start,
  //                                     children: [
  //                                       const Text(
  //                                         'VERIFICATION STATUS',
  //                                         style: TextStyle(
  //                                           fontSize: 12,
  //                                           fontWeight: FontWeight.bold,
  //                                           color: Colors.amber,
  //                                           letterSpacing: 1,
  //                                         ),
  //                                       ),
  //                                       const SizedBox(height: 4),
  //                                       Text(
  //                                         verification['verification_status']
  //                                             .toUpperCase(),
  //                                         style: const TextStyle(
  //                                           fontSize: 18,
  //                                           fontWeight: FontWeight.bold,
  //                                           color: Colors.amber,
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //
  //                           const SizedBox(height: 24),
  //
  //                           // Action Button
  //                           SizedBox(
  //                             width: double.infinity,
  //                             height: 50,
  //                             child: ElevatedButton.icon(
  //                               onPressed: () =>
  //                                   _approveSeller(context, seller.id),
  //                               icon: const Icon(
  //                                 Icons.check_circle,
  //                                 color: Colors.white,
  //                                 size: 22,
  //                               ),
  //                               label: const Text(
  //                                 'APPROVE SELLER',
  //                                 style: TextStyle(
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.bold,
  //                                   letterSpacing: 1,
  //                                 ),
  //                               ),
  //                               style: ElevatedButton.styleFrom(
  //                                 backgroundColor: Colors.black,
  //                                 foregroundColor: Colors.white,
  //                                 elevation: 4,
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(8),
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               );
  //             },
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

Future<Map<String, dynamic>?> _fetchSellerAddress(String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      return userDoc.data()?['address']; // Extracting address map
    }
  } catch (e) {
    print('Error fetching seller address: $e');
  }
  return null;
}

Widget _buildInfoChip(IconData icon, String? value, String label, {String? userId}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.black),
            const SizedBox(width: 6),
            if (label == "Address" && userId != null)
              FutureBuilder<Map<String, dynamic>?>(
                future: _fetchSellerAddress(userId),
                builder: (context, addressSnapshot) {
                  if (addressSnapshot.connectionState == ConnectionState.waiting) {
                    return Text('Loading...', style: TextStyle(fontSize: 14));
                  }
                  if (!addressSnapshot.hasData || addressSnapshot.data == null) {
                    return Text('Not available', style: TextStyle(fontSize: 14));
                  }
                  final address = addressSnapshot.data!;
                  return Expanded(
                    child: Text(
                      '${address['line1']}, ${address['city']}, ${address['state']} - ${address['zipcode']}',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 6,
                    ),
                  );
                },
              )
            else
              Expanded(
                child: Text(
                  value ?? 'Not available',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}




class WebAdminSellerApprovalScreen extends StatelessWidget {
  const WebAdminSellerApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Approval',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
        elevation: 0,
      ),

      // Web layout: Sidebar + Main Content
      body: Row(
        children: [
          const WebAdminSidebar(currentScreen: 'Seller Approvals',), // Sidebar for navigation
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('seller_details')
                  .where('verification.verification_status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No pending sellers'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    final seller = snapshot.data!.docs[index];
                    final data = seller.data() as Map<String, dynamic>;
                    final business = data['business_details'] as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business['store_name'] ?? 'No store name',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Verification Pending',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _approveSeller(context, seller.id),
                              icon: const Icon(Icons.check_circle, color: Colors.white),
                              label: const Text('Approve Seller'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),
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
  }
  Future<void> _approveSeller(BuildContext context, String sellerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('seller_details')
          .doc(sellerId)
          .update({
        'verification.verification_status': 'approved',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller approved successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving seller: $e')),
        );
      }
    }
  }

}
