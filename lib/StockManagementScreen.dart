import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StockManagementScreen extends StatefulWidget {
  @override
  _StockManagementScreenState createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _sellerId = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _getSellerProducts();
  }

  Future<void> _getSellerProducts() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    _sellerId = user.uid;

    try {
      QuerySnapshot productSnapshot = await _firestore
          .collection('Products')
          .where('seller_id', isEqualTo: _sellerId)
          .get();

      _products = productSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $e')),
      );
    }
  }

  void _modifyStock(String productId, int colorIndex, int sizeIndex, int change) {
    setState(() {
      var product = _products.firstWhere((prod) => prod['id'] == productId);
      List<dynamic> colors = product['colors'];

      if (colorIndex < colors.length) {
        List<dynamic> sizes = colors[colorIndex]['sizes'];

        if (sizeIndex < sizes.length) {
          int currentStock = sizes[sizeIndex]['stock'];
          int updatedStock = currentStock + change;

          if (updatedStock >= 0) {
            sizes[sizeIndex]['stock'] = updatedStock;
          }
        }
      }
    });
  }

  Future<void> _saveStockChanges() async {
    try {
      for (var product in _products) {
        await _firestore.collection('Products').doc(product['id']).update({
          'colors': product['colors'],
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock updated successfully'),
          backgroundColor: Colors.green, // ✅ Sets the background color to green
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating stock: $e')),
      );
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name'] ?? 'Product Name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            Column(
              children: List.generate(product['colors'].length, (colorIndex) {
                Map<String, dynamic> colorData = product['colors'][colorIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(5),
                            image: DecorationImage(
                              image: NetworkImage(colorData['colorImage']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          colorData['colorName'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Column(
                      children: List.generate(colorData['sizes'].length, (sizeIndex) {
                        Map<String, dynamic> sizeData = colorData['sizes'][sizeIndex];

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Size: ${sizeData['size']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () =>
                                      _modifyStock(product['id'], colorIndex, sizeIndex, -1),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '${sizeData['stock']}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () =>
                                      _modifyStock(product['id'], colorIndex, sizeIndex, 1),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                    const Divider(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Ensure background is set
        iconTheme: const IconThemeData(color: Colors.white), // Ensure icons are visible
        title: const Text(
          'Manage Stock',
          style: TextStyle(
            color: Colors.white, // Ensure text is visible
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              itemCount: _products.length,
              itemBuilder: (context, index) => _buildProductCard(_products[index]),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: ElevatedButton(
              onPressed: _saveStockChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
