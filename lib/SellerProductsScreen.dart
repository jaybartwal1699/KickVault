import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kickvault/Seller_Drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'EditProductScreen.dart';
import 'ProductFormScreen.dart';

class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({Key? key}) : super(key: key);

  @override
  _SellerProductsScreenState createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot>? _productsStream;
  String? _sellerId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeSellerData();
  }

  Future<void> _initializeSellerData() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _error = 'User data not found';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      if (userData['role'] != 'seller') {
        setState(() {
          _error = 'Access denied: User is not a seller';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _sellerId = currentUser.uid;
        _productsStream = FirebaseFirestore.instance
            .collection('Products')
            .where('seller_id', isEqualTo: currentUser.uid)
            .snapshots();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error initializing seller data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Products')
          .doc(productId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 60),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _initializeSellerData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Set AppBar color to black
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
        title: Text(
          'Your Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Set text color to white
          ),
        ),
      ),


      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _productsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Your First Product',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductFormScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final images = List<String>.from(data['images'] ?? []);
                final metadata = data['metadata'] as Map<String, dynamic>;
                final colors = data['colors'] as List<dynamic>? ?? [];

                return Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (images.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, imageIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: images[imageIndex],
                                      fit: BoxFit.cover,
                                      width: 200,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          data['name'] ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['description'] ?? 'No description',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              '₹${data['price'].toString()}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: data['discount'] > 0
                                    ? Colors.grey
                                    : Colors.black,
                                decoration: data['discount'] > 0
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (data['discount'] > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₹${metadata['discountedPrice'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${data['discount']}% \nOFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total Stock: ${metadata['totalStock']}',
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Colors: ${metadata['colorCount']} | Sizes: ${metadata['sizeCount']}',
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: data['status'] == 'active'
                                ? Colors.green
                                : data['status'] == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            data['status']?.toUpperCase() ?? 'UNKNOWN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        if (colors.isNotEmpty)
                          Text('Available Colors:',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black)),
                        ...colors.map((color) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Image.network(
                                  color['colorImage'] ?? '',
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  color['colorName'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              label: const Text('Edit',
                                  style: TextStyle(color: Colors.blue)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProductScreen(
                                      productId: doc.id,
                                      productData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor:
                                      const Color(0xFFF0F0F0),
                                      title: const Text('Confirm Delete',
                                          style:
                                          TextStyle(color: Colors.black)),
                                      content: const Text(
                                          'Are you sure you want to delete this product?',
                                          style:
                                          TextStyle(color: Colors.black)),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel',
                                              style: TextStyle(
                                                color: Colors.black,
                                              )),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Delete',
                                              style:
                                              TextStyle(color: Colors.red)),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _deleteProduct(doc.id);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductFormScreen(),
            ),
          );
        },
      ),
    );
  }
}