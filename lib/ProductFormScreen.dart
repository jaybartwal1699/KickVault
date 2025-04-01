// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
//
// import 'package:kickvault/Admin_Drawer.dart';
// import 'package:kickvault/Seller_Drawer.dart';
//
// class ProductFormScreen extends StatefulWidget {
//   @override
//   _ProductFormScreenState createState() => _ProductFormScreenState();
// }
//
// class _ProductFormScreenState extends State<ProductFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String name = '';
//   String description = '';
//   String categoryId = '';
//   double price = 0;
//   double discount = 0;
//   List<Map<String, dynamic>> colors = []; // Store colors with sizes and stock
//   String sellerId = '';
//   List<Category> categoryList = [];
//   List<Seller> sellerList = [];
//   List<File> imageFiles = [];
//   List<String> imageUrls = [];
//
//   //new fields
//   String fit = '';
//   String material = '';
//   String archSupport = '';
//   String cushioning = '';
//   String weight = '';
//   String outsoleGrip = '';
//   String durability = '';
//   String styleAesthetics = '';
//
//   @override
//   void initState() {
//     super.initState();
//     fetchCategories();
//     fetchSellers();
//   }
//
//   Future<void> fetchCategories() async {
//     try {
//       QuerySnapshot querySnapshot =
//       await FirebaseFirestore.instance.collection('Categories').get();
//       final categories = querySnapshot.docs
//           .map((doc) => Category.fromFirestore(doc))
//           .toList();
//
//       setState(() {
//         categoryList = categories;
//         if (categories.isNotEmpty) {
//           categoryId = categories.first.id;
//         }
//       });
//     } catch (e) {
//       print('Error fetching categories: $e');
//     }
//   }
//
//   Future<void> fetchSellers() async {
//     try {
//       QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('role', isEqualTo: 'seller')
//           .get();
//       final sellers =
//       querySnapshot.docs.map((doc) => Seller.fromFirestore(doc)).toList();
//
//       setState(() {
//         sellerList = sellers;
//         if (sellers.isNotEmpty) {
//           sellerId = sellers.first.id;
//         }
//       });
//     } catch (e) {
//       print('Error fetching sellers: $e');
//     }
//   }
//
//   Future<void> _pickImages() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final List<XFile>? selectedImages = await picker.pickMultiImage();
//
//       if (selectedImages != null && selectedImages.isNotEmpty) {
//         setState(() {
//           // Convert XFile to File
//           imageFiles = selectedImages.map((image) => File(image.path)).toList();
//         });
//       }
//     } catch (e) {
//       print('Error picking images: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error picking images: $e')),
//       );
//     }
//   }
//
//
//   Future<List<String>> _uploadImages() async {
//     List<String> uploadedImageUrls = [];
//     try {
//       for (var image in imageFiles) {
//         if (image is File) {
//           String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//           Reference storageRef =
//           FirebaseStorage.instance.ref().child('products/$fileName');
//           UploadTask uploadTask = storageRef.putFile(image);
//           TaskSnapshot snapshot = await uploadTask;
//           String imageUrl = await snapshot.ref.getDownloadURL();
//           uploadedImageUrls.add(imageUrl);
//         } else {
//           print("Error: Image is not a valid File object");
//         }
//       }
//     } catch (e) {
//       print('Error uploading images: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error uploading images: $e')),
//       );
//     }
//     return uploadedImageUrls;
//   }
//
//
//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       // Save the current state of all form fields
//       _formKey.currentState!.save();
//
//       try {
//         // Show loading indicator
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (BuildContext context) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//               ),
//             );
//           },
//         );
//
//         // Step 1: Upload main product images
//         List<String> mainImageUrls = [];
//         for (var image in imageFiles) {
//           String fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${mainImageUrls.length}';
//           Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
//           UploadTask uploadTask = storageRef.putFile(image);
//           TaskSnapshot snapshot = await uploadTask;
//           String imageUrl = await snapshot.ref.getDownloadURL();
//           mainImageUrls.add(imageUrl);
//         }
//
//         // Step 2: Process colors and their images
//         List<Map<String, dynamic>> processedColors = [];
//         for (var color in colors) {
//           if (color['color'].isEmpty) {
//             throw Exception('Color name cannot be empty');
//           }
//
//           // Upload color-specific image if it exists
//           String? colorImageUrl;
//           if (color['colorImage'] != null) {
//             String fileName = 'colors/${DateTime.now().millisecondsSinceEpoch}';
//             Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
//             UploadTask uploadTask = storageRef.putFile(color['colorImage']);
//             TaskSnapshot snapshot = await uploadTask;
//             colorImageUrl = await snapshot.ref.getDownloadURL();
//           }
//
//           // Validate and process sizes for each color
//           List<Map<String, dynamic>> processedSizes = [];
//           for (var size in color['sizes']) {
//             if (size['size'].isEmpty) {
//               throw Exception('Size cannot be empty');
//             }
//             if (size['stock'] == null || size['stock'] < 0) {
//               throw Exception('Invalid stock quantity');
//             }
//
//             processedSizes.add({
//               'size': size['size'],
//               'stock': size['stock'],
//             });
//           }
//
//           // Add processed color data to the list
//           processedColors.add({
//             'colorName': color['color'],
//             'colorImage': colorImageUrl,
//             'sizes': processedSizes,
//           });
//         }
//
//         // Step 3: Validate required fields
//         if (name.isEmpty) throw Exception('Product name is required');
//         if (description.isEmpty) throw Exception('Description is required');
//         if (categoryId.isEmpty) throw Exception('Category is required');
//         if (sellerId.isEmpty) throw Exception('Seller is required');
//         if (price <= 0) throw Exception('Price must be greater than 0');
//         if (discount < 0 || discount > 100) throw Exception('Invalid discount percentage');
//         if (processedColors.isEmpty) throw Exception('At least one color is required');
//         if (mainImageUrls.isEmpty) throw Exception('At least one product image is required');
//
//         // Step 4: Create the final product document
//         Map<String, dynamic> productData = {
//           'name': name.trim(),
//           'description': description.trim(),
//           'category_id': categoryId,
//           'seller_id': sellerId,
//           'price': price,
//           'discount': discount,
//           'colors': processedColors,
//           'images': mainImageUrls,
//           'created_at': FieldValue.serverTimestamp(),
//           'updated_at': FieldValue.serverTimestamp(),
//           'status': 'panding', // Default status for new products
//           'details': {
//             'fit': fit.trim(),
//             'material': material.trim(),
//             'archSupport': archSupport.trim(),
//             'cushioning': cushioning.trim(),
//             'weight': weight.trim(),
//             'outsoleGrip': outsoleGrip.trim(),
//             'durability': durability.trim(),
//             'styleAesthetics': styleAesthetics.trim(),
//           },
//           // Add metadata
//           'metadata': {
//             'totalStock': processedColors.fold<int>(0, (sum, color) =>
//             sum + (color['sizes'] as List<dynamic>).fold<int>(0, (sizeSum, size) =>
//             sizeSum + int.parse(size['stock'].toString())
//             )
//             ),
//             'hasDiscount': discount > 0,
//             'discountedPrice': price - (price * discount / 100),
//             'colorCount': processedColors.length,
//             'sizeCount': processedColors.fold<int>(0, (sum, color) =>
//             sum + (color['sizes'] as List<dynamic>).length
//             ),
//           }
//         };
//
//         // Step 5: Save to Firebase
//         DocumentReference docRef = await FirebaseFirestore.instance
//             .collection('Products')
//             .add(productData);
//
//         // Close loading indicator
//         Navigator.pop(context);
//
//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Product added successfully!'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//
//         // Reset form
//         _resetForm();
//
//       } catch (e) {
//         // Close loading indicator if it's showing
//         if (Navigator.canPop(context)) {
//           Navigator.pop(context);
//         }
//
//         // Show error message
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }
//
// // Helper method to reset the form
//   void _resetForm() {
//     setState(() {
//       // Reset all form fields
//       _formKey.currentState!.reset();
//       name = '';
//       description = '';
//       price = 0;
//       discount = 0;
//       imageFiles.clear();
//       imageUrls.clear();
//       colors.clear();
//
//       // Reset product details
//       fit = '';
//       material = '';
//       archSupport = '';
//       cushioning = '';
//       weight = '';
//       outsoleGrip = '';
//       durability = '';
//       styleAesthetics = '';
//
//       // Don't reset category and seller IDs as they're likely still relevant
//     });
//   }
//
//
//   void _addColor() {
//     setState(() {
//       colors.add({
//         'color': '',
//         'sizes': [],
//         'colorImage': null, // Store the image for the color
//       });
//     });
//   }
//
//   void _addSize(int colorIndex) {
//     setState(() {
//       colors[colorIndex]['sizes'].add({
//         'size': '',
//         'stock': 0,
//       });
//     });
//   }
//
//   void _removeColor(int colorIndex) {
//     setState(() {
//       colors.removeAt(colorIndex);
//     });
//   }
//
//   void _removeSize(int colorIndex, int sizeIndex) {
//     setState(() {
//       colors[colorIndex]['sizes'].removeAt(sizeIndex);
//     });
//   }
//
//   // Pick an image for a specific color
//   Future<void> _pickColorImage(int colorIndex) async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? selectedImage = await picker.pickImage(source: ImageSource.gallery);
//
//       if (selectedImage != null) {
//         setState(() {
//           colors[colorIndex]['colorImage'] = File(selectedImage.path); // Store image for this color
//         });
//       }
//     } catch (e) {
//       print('Error picking image for color: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF121212),
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: const Text("Add Product"),
//         elevation: 0,
//       ),
//       drawer: SellerDrawer(currentScreen: 'product_form'),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 20),
//               _buildTextField('Product Name', Icons.shopping_bag, false,
//                       (value) => name = value),
//               const SizedBox(height: 16),
//               _buildTextField(
//                   'Description',
//                   Icons.description,
//                   false,
//                       (value) => description = value,
//                   maxLines: 4,
//                   keyboardType: TextInputType.multiline),
//               const SizedBox(height: 16),
//               _buildDropdown('Category', categoryList, categoryId, (value) {
//                 setState(() {
//                   categoryId = value!;
//                 });
//               }),
//               const SizedBox(height: 16),
//               _buildTextField('Price', Icons.attach_money, true,
//                       (value) => price = double.parse(value)),
//               const SizedBox(height: 16),
//               _buildTextField('Discount', Icons.percent, true,
//                       (value) => discount = double.parse(value)),
//               const SizedBox(height: 16),
//               _buildColorSection(),
//               const SizedBox(height: 16),
//               _buildDropdown('Seller', sellerList, sellerId, (value) {
//                 setState(() {
//                   sellerId = value!;
//                 });
//               }),
//               const SizedBox(height: 16),
//               _buildTextField('Fit', Icons.straighten, false,
//                       (value) => fit = value),
//               const SizedBox(height: 16),
//               _buildTextField('Material', Icons.texture, false,
//                       (value) => material = value),
//               const SizedBox(height: 16),
//               _buildTextField('Arch Support', Icons.snowshoeing, false,
//                       (value) => archSupport = value),
//               const SizedBox(height: 16),
//               _buildTextField('Cushioning', Icons.crop_square, false,
//                       (value) => cushioning = value),
//               const SizedBox(height: 16),
//               _buildTextField('Weight', Icons.fitness_center, false,
//                       (value) => weight = value),
//               const SizedBox(height: 16),
//               _buildTextField('Outsole Grip', Icons.terrain, false,
//                       (value) => outsoleGrip = value),
//               const SizedBox(height: 16),
//               _buildTextField('Durability', Icons.update, false,
//                       (value) => durability = value),
//               const SizedBox(height: 16),
//               _buildTextField('Style and Aesthetics', Icons.style, false,
//                       (value) => styleAesthetics = value),
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: _pickImages,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   minimumSize: const Size(double.infinity, 50),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text('Pick Images',
//                     style: TextStyle(color: Colors.white)),
//               ),
//               const SizedBox(height: 10),
//               imageFiles.isNotEmpty
//                   ? Wrap(
//                 spacing: 8.0,
//                 runSpacing: 8.0,
//                 children: imageFiles.map((image) {
//                   return Image.file(
//                     image,
//                     width: 100,
//                     height: 100,
//                     fit: BoxFit.cover,
//                   );
//                 }).toList(),
//               )
//                   : const Text('No images selected',
//                   style: TextStyle(color: Colors.grey)),
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: _submitForm,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                   minimumSize: const Size(double.infinity, 50),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text("Submit", style: TextStyle(fontSize: 18)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField(
//       String label, IconData icon, bool isNumeric, Function(String) onSaved,
//       {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
//     return TextFormField(
//       style: TextStyle(color: Colors.white),
//       maxLines: maxLines,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
//         prefixIcon: Icon(icon, color: Colors.white),
//         filled: true,
//         fillColor: const Color(0xFF1E1E1E),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide.none,
//         ),
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please enter $label';
//         }
//         return null;
//       },
//       onSaved: (value) {
//         if (value != null) onSaved(value);
//       },
//     );
//   }
//
//   Widget _buildDropdown(String label, List<dynamic> items, String selectedValue,
//       Function(String?) onChanged) {
//     return DropdownButtonFormField<String>(
//       dropdownColor: const Color(0xFF1E1E1E),
//       style: TextStyle(
//         color: Colors.white
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
//         prefixIcon: Icon(Icons.category, color: Colors.white),
//         filled: true,
//         fillColor: const Color(0xFF1E1E1E),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide.none,
//         ),
//       ),
//       value: selectedValue.isNotEmpty ? selectedValue : null,
//       items: items.map((item) {
//         return DropdownMenuItem<String>(
//           value: item.id,
//           child: Text(item.name),
//         );
//       }).toList(),
//       onChanged: onChanged,
//       validator: (value) => value == null ? 'Please select $label' : null,
//     );
//   }
//
//   Widget _buildColorSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Colors',
//           style: TextStyle(color: Colors.white, fontSize: 16),
//         ),
//         const SizedBox(height: 10),
//         ElevatedButton(
//           onPressed: _addColor,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             minimumSize: const Size(double.infinity, 50),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           child: const Text('Add Color',
//               style: TextStyle(color: Colors.white)),
//         ),
//         const SizedBox(height: 20),
//         ListView.builder(
//           shrinkWrap: true,
//           itemCount: colors.length,
//           itemBuilder: (context, colorIndex) {
//             return Card(
//               color: const Color(0xFF1E1E1E),
//               margin: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       style: TextStyle(color: Colors.white),
//                       decoration: InputDecoration(
//                         labelText: 'Color Name',
//                         labelStyle: TextStyle(color: Colors.white),
//                         prefixIcon: const Icon(Icons.color_lens, color: Colors.white),
//                         filled: true,
//                         fillColor: const Color(0xFF121212),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           colors[colorIndex]['color'] = value;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 10),
//                     ElevatedButton(
//                       onPressed: () => _pickColorImage(colorIndex),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text('Pick Color Image',
//                           style: TextStyle(color: Colors.white)),
//                     ),
//                     const SizedBox(height: 10),
//                     colors[colorIndex]['colorImage'] != null
//                         ? Image.file(
//                       colors[colorIndex]['colorImage']!,
//                       width: 100,
//                       height: 100,
//                       fit: BoxFit.cover,
//                     )
//                         : const Text('No color image selected',
//                         style: TextStyle(color: Colors.grey)),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () => _addSize(colorIndex),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text('Add Size',
//                           style: TextStyle(color: Colors.white)),
//                     ),
//                     const SizedBox(height: 20),
//                     ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: colors[colorIndex]['sizes'].length,
//                       itemBuilder: (context, sizeIndex) {
//                         return Card(
//                           color: const Color(0xFF1E1E1E),
//                           margin: const EdgeInsets.symmetric(vertical: 8.0),
//                           child: Padding(
//                             padding: const EdgeInsets.all(10.0),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: TextFormField(
//                                     style: TextStyle(color: Colors.white),
//                                     decoration: InputDecoration(
//                                       labelText: 'Size',
//                                       labelStyle: TextStyle(color: Colors.white),
//                                       prefixIcon: const Icon(Icons.format_size, color: Colors.white),
//                                       filled: true,
//                                       fillColor: const Color(0xFF121212),
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                         borderSide: BorderSide.none,
//                                       ),
//                                     ),
//                                     onChanged: (value) {
//                                       setState(() {
//                                         colors[colorIndex]['sizes'][sizeIndex]['size'] = value;
//                                       });
//                                     },
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: TextFormField(
//                                     style: TextStyle(color: Colors.white),
//                                     keyboardType: TextInputType.number,
//                                     decoration: InputDecoration(
//                                       labelText: 'Stock',
//                                       labelStyle: TextStyle(color: Colors.white),
//                                       prefixIcon: const Icon(Icons.store, color: Colors.white),
//                                       filled: true,
//                                       fillColor: const Color(0xFF121212),
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                         borderSide: BorderSide.none,
//                                       ),
//                                     ),
//                                     onChanged: (value) {
//                                       setState(() {
//                                         colors[colorIndex]['sizes'][sizeIndex]['stock'] = int.parse(value);
//                                       });
//                                     },
//                                   ),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.delete, color: Colors.white),
//                                   onPressed: () => _removeSize(colorIndex, sizeIndex),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _removeColor(colorIndex),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }
//
// class Category {
//   final String id;
//   final String name;
//
//   Category({required this.id, required this.name});
//
//   factory Category.fromFirestore(DocumentSnapshot doc) {
//     return Category(
//       id: doc.id,
//       name: doc['name'],
//     );
//   }
// }
//
// class Seller {
//   final String id;
//   final String name;
//
//   Seller({required this.id, required this.name});
//
//   factory Seller.fromFirestore(DocumentSnapshot doc) {
//     return Seller(
//       id: doc.id,
//       name: doc['name'],
//     );
//   }
// }

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:kickvault/Admin_Drawer.dart';
import 'package:kickvault/Seller_Drawer.dart';

class ProductFormScreen extends StatefulWidget {
  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  String categoryId = '';
  double price = 0;
  double discount = 0;
  List<Map<String, dynamic>> colors = [];
  String sellerId = '';
  List<Category> categoryList = [];
  List<Seller> sellerList = [];
  List<File> imageFiles = [];
  List<String> imageUrls = [];
  bool _isLoading = false;
  bool _isDarkMode = false;

  // Product details
  String fit = '';
  String material = '';
  String archSupport = '';
  String cushioning = '';
  String weight = '';
  String outsoleGrip = '';
  String durability = '';
  String styleAesthetics = '';
  String selectedGender = '';

  final List<Map<String, String>> genders = [
    {'id': 'male', 'name': 'Male'},
    {'id': 'female', 'name': 'Female'},
    {'id': 'unisex', 'name': 'Unisex'},
  ];



  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchSellers();
  }

  Future<void> fetchCategories() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Categories').get();
      final categories = querySnapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();

      setState(() {
        categoryList = categories;
        if (categories.isNotEmpty) {
          categoryId = categories.first.id;
        }
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchSellers() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'seller')
          .get();
      final sellers =
      querySnapshot.docs.map((doc) => Seller.fromFirestore(doc)).toList();

      setState(() {
        sellerList = sellers;
        if (sellers.isNotEmpty) {
          sellerId = sellers.first.id;
        }
      });
    } catch (e) {
      print('Error fetching sellers: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? selectedImages = await picker.pickMultiImage();

      if (selectedImages != null && selectedImages.isNotEmpty) {
        setState(() {
          // Convert XFile to File
          imageFiles = selectedImages.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }


  Future<List<String>> _uploadImages() async {
    List<String> uploadedImageUrls = [];
    try {
      for (var image in imageFiles) {
        if (image is File) {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference storageRef =
          FirebaseStorage.instance.ref().child('products/$fileName');
          UploadTask uploadTask = storageRef.putFile(image);
          TaskSnapshot snapshot = await uploadTask;
          String imageUrl = await snapshot.ref.getDownloadURL();
          uploadedImageUrls.add(imageUrl);
        } else {
          print("Error: Image is not a valid File object");
        }
      }
    } catch (e) {
      print('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    }
    return uploadedImageUrls;
  }


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Save the current state of all form fields
      _formKey.currentState!.save();

      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          },
        );

        // Step 1: Upload main product images
        List<String> mainImageUrls = [];
        for (var image in imageFiles) {
          String fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${mainImageUrls.length}';
          Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
          UploadTask uploadTask = storageRef.putFile(image);
          TaskSnapshot snapshot = await uploadTask;
          String imageUrl = await snapshot.ref.getDownloadURL();
          mainImageUrls.add(imageUrl);
        }

        // Step 2: Process colors and their images
        List<Map<String, dynamic>> processedColors = [];
        for (var color in colors) {
          if (color['color'].isEmpty) {
            throw Exception('Color name cannot be empty');
          }

          // Upload color-specific image if it exists
          String? colorImageUrl;
          if (color['colorImage'] != null) {
            String fileName = 'colors/${DateTime.now().millisecondsSinceEpoch}';
            Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
            UploadTask uploadTask = storageRef.putFile(color['colorImage']);
            TaskSnapshot snapshot = await uploadTask;
            colorImageUrl = await snapshot.ref.getDownloadURL();
          }

          // Validate and process sizes for each color
          List<Map<String, dynamic>> processedSizes = [];
          for (var size in color['sizes']) {
            if (size['size'].isEmpty) {
              throw Exception('Size cannot be empty');
            }
            if (size['stock'] == null || size['stock'] < 0) {
              throw Exception('Invalid stock quantity');
            }

            processedSizes.add({
              'size': size['size'],
              'stock': size['stock'],
            });
          }

          // Add processed color data to the list
          processedColors.add({
            'colorName': color['color'],
            'colorImage': colorImageUrl,
            'sizes': processedSizes,
          });
        }

        // Step 3: Validate required fields
        if (name.isEmpty) throw Exception('Product name is required');
        if (description.isEmpty) throw Exception('Description is required');
        if (categoryId.isEmpty) throw Exception('Category is required');
        if (sellerId.isEmpty) throw Exception('Seller is required');
        // Add this with other validations in _submitForm()
        if (selectedGender.isEmpty) throw Exception('Gender is required');
        if (price <= 0) throw Exception('Price must be greater than 0');
        if (discount < 0 || discount > 100) throw Exception('Invalid discount percentage');
        if (processedColors.isEmpty) throw Exception('At least one color is required');
        if (mainImageUrls.isEmpty) throw Exception('At least one product image is required');

        // Step 4: Create the final product document
        Map<String, dynamic> productData = {
          'name': name.trim(),
          'description': description.trim(),
          'category_id': categoryId,
          'seller_id': sellerId,
          'gender': selectedGender,
          'price': price,
          'discount': discount,
          'colors': processedColors,
          'images': mainImageUrls,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'status': 'panding', // Default status for new products
          'details': {
            'fit': fit.trim(),
            'material': material.trim(),
            'archSupport': archSupport.trim(),
            'cushioning': cushioning.trim(),
            'weight': weight.trim(),
            'outsoleGrip': outsoleGrip.trim(),
            'durability': durability.trim(),
            'styleAesthetics': styleAesthetics.trim(),
          },
          // Add metadata
          'metadata': {
            'totalStock': processedColors.fold<int>(0, (sum, color) =>
            sum + (color['sizes'] as List<dynamic>).fold<int>(0, (sizeSum, size) =>
            sizeSum + int.parse(size['stock'].toString())
            )
            ),
            'hasDiscount': discount > 0,
            'discountedPrice': price - (price * discount / 100),
            'colorCount': processedColors.length,
            'sizeCount': processedColors.fold<int>(0, (sum, color) =>
            sum + (color['sizes'] as List<dynamic>).length
            ),
          }
        };

        // Step 5: Save to Firebase
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('Products')
            .add(productData);

        // Close loading indicator
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 80),
          ),
        );

        // Reset form
        _resetForm();

      } catch (e) {
        // Close loading indicator if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

// Helper method to reset the form
  void _resetForm() {
    setState(() {
      // Reset all form fields
      _formKey.currentState!.reset();
      name = '';
      description = '';
      price = 0;
      discount = 0;
      imageFiles.clear();
      imageUrls.clear();
      colors.clear();

      // Reset product details
      fit = '';
      material = '';
      archSupport = '';
      cushioning = '';
      weight = '';
      outsoleGrip = '';
      durability = '';
      styleAesthetics = '';
      selectedGender = '';

      // Don't reset category and seller IDs as they're likely still relevant
    });
  }


  void _addColor() {
    setState(() {
      colors.add({
        'color': '',
        'sizes': [],
        'colorImage': null, // Store the image for the color
      });
    });
  }

  void _addSize(int colorIndex) {
    setState(() {
      colors[colorIndex]['sizes'].add({
        'size': '',
        'stock': 0,
      });
    });
  }

  void _removeColor(int colorIndex) {
    setState(() {
      colors.removeAt(colorIndex);
    });
  }

  void _removeSize(int colorIndex, int sizeIndex) {
    setState(() {
      colors[colorIndex]['sizes'].removeAt(sizeIndex);
    });
  }

  // Pick an image for a specific color
  Future<void> _pickColorImage(int colorIndex) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? selectedImage = await picker.pickImage(source: ImageSource.gallery);

      if (selectedImage != null) {
        setState(() {
          colors[colorIndex]['colorImage'] = File(selectedImage.path); // Store image for this color
        });
      }
    } catch (e) {
      print('Error picking image for color: $e');
    }
  }

  // ... [Keep all the existing helper methods and functions]

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    _isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Set AppBar color to black
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
        title: Text(
          'Add Products ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Set text color to white
          ),
        ),
      ),
      drawer: SellerDrawer(currentScreen: 'product_form'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Images Section Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Product Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _pickImages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Pick Images',style: TextStyle(color: Colors.white,),),
                        ),
                        SizedBox(height: 16),
                        if (imageFiles.isNotEmpty)
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: imageFiles.map((image) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  image,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            'No images selected',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Basic Details Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Basic Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTextField('Product Name', Icons.shopping_bag, false,
                                (value) => name = value),
                        SizedBox(height: 16),
                        _buildTextField(
                            'Description',
                            Icons.description,
                            false,
                                (value) => description = value,
                            maxLines: 4),
                        SizedBox(height: 16),
                        _buildDropdown('Category', categoryList, categoryId,
                                (value) {
                              setState(() {
                                categoryId = value!;
                              });
                            }),
                        SizedBox(height: 16),
                        _buildDropdown('Seller', sellerList, sellerId, (value) {
                          setState(() {
                            sellerId = value!;
                          });
                        }),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.person, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                          value: selectedGender.isNotEmpty ? selectedGender : null,
                          items: genders.map((gender) {
                            return DropdownMenuItem<String>(
                              value: gender['id'],
                              child: Text(gender['name']!),
                            );
                          }).toList(),
                          validator: (value) => value == null ? 'Please select gender' : null,
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                            });
                          },
                          onSaved: (value) {
                            selectedGender = value!; // Save the selected gender when the form is saved
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Pricing Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pricing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTextField('Price', Icons.attach_money, true,
                                (value) => price = double.parse(value)),
                        SizedBox(height: 16),
                        _buildTextField('Discount', Icons.percent, true,
                                (value) => discount = double.parse(value)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Product Details Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTextField('Fit', Icons.straighten, false,
                                (value) => fit = value),
                        SizedBox(height: 16),
                        _buildTextField('Material', Icons.texture, false,
                                (value) => material = value),
                        SizedBox(height: 16),
                        _buildTextField('Arch Support', Icons.snowshoeing, false,
                                (value) => archSupport = value),
                        SizedBox(height: 16),
                        _buildTextField('Cushioning', Icons.crop_square, false,
                                (value) => cushioning = value),
                        SizedBox(height: 16),
                        _buildTextField('Weight', Icons.fitness_center, false,
                                (value) => weight = value),
                        SizedBox(height: 16),
                        _buildTextField('Outsole Grip', Icons.terrain, false,
                                (value) => outsoleGrip = value),
                        SizedBox(height: 16),
                        _buildTextField('Durability', Icons.update, false,
                                (value) => durability = value),
                        SizedBox(height: 16),
                        _buildTextField('Style and Aesthetics', Icons.style, false,
                                (value) => styleAesthetics = value),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Colors and Sizes Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: _buildColorSection(),
                  ),
                ),
                SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, IconData icon, bool isNumeric, Function(String) onSaved,
      {int maxLines = 1}) {
    return TextFormField(
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black), // Changed to black
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      onSaved: (value) {
        if (value != null) onSaved(value);
      },
    );

  }

  Widget _buildDropdown(String label, List<dynamic> items, String selectedValue,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
        Icon(Icons.category, color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      value: selectedValue.isNotEmpty ? selectedValue : null,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item.id,
          child: Text(item.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }
  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Colors',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addColor,
          style: ElevatedButton.styleFrom(
            backgroundColor:  Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Add Color',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        if (colors.isEmpty)
          const Text(
            'No colors added yet',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: colors.length,
            itemBuilder: (context, colorIndex) {
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Color Name',
                          prefixIcon: const Icon(Icons.color_lens),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            colors[colorIndex]['color'] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _pickColorImage(colorIndex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Pick Color Image',
                          style: TextStyle(color: Colors.white),),
                      ),
                      const SizedBox(height: 10),
                      colors[colorIndex]['colorImage'] != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          colors[colorIndex]['colorImage']!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                          : const Text(
                        'No color image selected',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _addSize(colorIndex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add Size',
                          style: TextStyle(color: Colors.white),),
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: colors[colorIndex]['sizes']?.length ?? 0,
                        itemBuilder: (context, sizeIndex) {
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Size',
                                        hintText: 'size', // Added placeholder
                                        labelStyle: const TextStyle(color: Colors.black),
                                        prefixIcon: const Icon(Icons.format_size),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          colors[colorIndex]['sizes'][sizeIndex]['size'] = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Stock',
                                        hintText: 'stock', // Added placeholder
                                        labelStyle: const TextStyle(color: Colors.black),
                                        prefixIcon: const Icon(Icons.store),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          colors[colorIndex]['sizes'][sizeIndex]['stock'] = int.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeSize(colorIndex, sizeIndex),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeColor(colorIndex),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}


// ... [Keep the rest of the existing methods]

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromFirestore(DocumentSnapshot doc) {
    return Category(
      id: doc.id,
      name: doc['name'],
    );
  }
}

class Seller {
  final String id;
  final String name;

  Seller({required this.id, required this.name});

  factory Seller.fromFirestore(DocumentSnapshot doc) {
    return Seller(
      id: doc.id,
      name: doc['name'],
    );
  }
}
