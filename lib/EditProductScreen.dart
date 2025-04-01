import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductScreen({
    Key? key,
    required this.productId,
    required this.productData,
  }) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late List<dynamic> _colors;
  late List<dynamic> _sizes;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.productData['description']);
    _priceController =
        TextEditingController(text: widget.productData['price'].toString());
    _discountController =
        TextEditingController(text: widget.productData['discount'].toString());
    _colors = List.from(widget.productData['colors'] ?? []);
    _sizes = [];
    // Flatten sizes from colors into a single list for easier management
    for (var color in _colors) {
      _sizes.addAll(color['sizes'] ?? []);
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      double price = double.parse(_priceController.text);
      int discount = int.parse(_discountController.text);
      double discountedPrice = price * (1 - discount / 100);
      bool hasDiscount = discount > 0;
      int totalStock = _sizes.fold(0, (sum, size) => sum + (size['stock'] as int));
      int colorCount = _colors.length;
      int sizeCount = _sizes.length;

      // Update the product data and metadata in Firestore
      await FirebaseFirestore.instance
          .collection('Products')
          .doc(widget.productId)
          .update({
        'description': _descriptionController.text,
        'price': price,
        'discount': discount,
        'colors': _colors,
        'metadata.discountedPrice': discountedPrice,
        'metadata.hasDiscount': hasDiscount,
        'metadata.totalStock': totalStock,
        'metadata.colorCount': colorCount,
        'metadata.sizeCount': sizeCount,
        'updated_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteColor(int index) {
    setState(() {
      var removedColor = _colors.removeAt(index);
      _sizes.removeWhere((size) => removedColor['sizes'].contains(size));
    });
  }

  void _deleteSize(int index) {
    setState(() {
      _sizes.removeAt(index);
      // Update colors to reflect size removal (optional logic if needed)
      for (var color in _colors) {
        color['sizes'].removeWhere((size) => size == _sizes[index]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Edit Product',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Display product name at the top
              Text(
                'Editing: ${widget.productData['name'] ?? 'Unnamed Product'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount (%)',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a discount percentage';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Colors Section
              const Text(
                'Colors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              ..._colors.asMap().entries.map((entry) {
                int index = entry.key;
                var color = entry.value;
                return ListTile(
                  leading: Image.network(
                    color['colorImage'] ?? '',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
                  ),
                  title: Text(color['colorName'] ?? 'Unknown'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteColor(index),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              // Sizes Section
              const Text(
                'Sizes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              ..._sizes.asMap().entries.map((entry) {
                int index = entry.key;
                var size = entry.value;
                return ListTile(
                  title: Text('Size: ${size['size']}'),
                  subtitle: Text('Stock: ${size['stock']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSize(index),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _updateProduct,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }
}