// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'CheckoutScreen2.dart';
//
// class CartScreen extends StatefulWidget {
//   @override
//   _CartScreenState createState() => _CartScreenState();
// }
//
// class _CartScreenState extends State<CartScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> cartItems = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchCartItems();
//   }
//
//   Future<void> fetchCartItems() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       final cartDocs = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('cart')
//           .get();
//
//       setState(() {
//         cartItems = cartDocs.docs
//             .map((doc) => {
//           ...doc.data(),
//           'id': doc.id, // Add document ID for deletion
//         })
//             .toList();
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> removeFromCart(String productId) async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('cart')
//           .doc(productId)
//           .delete();
//
//       // Remove the item locally and refresh UI
//       setState(() {
//         cartItems.removeWhere((item) => item['id'] == productId);
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Item removed from cart!'),
//           backgroundColor: Colors.red,
//
//         ),
//       );
//     }
//   }
//
//   double calculateTotal() {
//     return cartItems.fold(0, (sum, item) => sum + (item['price'] as double));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Center(
//           child: Text(
//             'Cart',
//             style: GoogleFonts.nunitoSans(
//               color: Colors.white, // Ensuring good contrast
//               fontWeight: FontWeight.w900,
//               fontSize: 25, // Optional: Adjust size as needed
//             ),
//           ),
//         ),
//         backgroundColor: Colors.teal[900], // Dark teal color
//         foregroundColor: Colors.white, // Ensuring icons and back button are visible
//       ),
//
//       body: Column(
//         children: [
//           Expanded(
//             child: cartItems.isEmpty
//                 ? Center(
//               child: Text(
//                 'under dev',// 'Your cart is empty',
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             )
//                 : ListView.builder(
//               itemCount: cartItems.length,
//               itemBuilder: (context, index) {
//                 final item = cartItems[index];
//                 return Card(
//                   margin: EdgeInsets.all(8),
//                   child: ListTile(
//                     leading: Image.network(
//                       item['product_image'] ?? '',
//                       width: 50,
//                       height: 50,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) =>
//                           Icon(Icons.image_not_supported),
//                     ),
//                     title: Text(item['product_name'] ?? 'No Name'),
//                     subtitle: Text(
//                         'Color: ${item['color'] ?? 'N/A'}, Size: ${item['size'] ?? 'N/A'}\n₹${item['price'] ?? 0.0}'),
//                     trailing: IconButton(
//                       icon: Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => removeFromCart(item['id']),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           if (cartItems.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   Text(
//                     'Total: ₹${calculateTotal().toStringAsFixed(2)}',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 16),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         if (cartItems.isNotEmpty) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   CheckoutScreen2(cartItems: cartItems),
//                             ),
//                           );
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text("Cart is empty!"),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black,
//                         foregroundColor: Colors.white,
//                       ),
//                       child:
//                       Text('Proceed to Checkout', style: TextStyle(fontSize: 18)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
//



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'CheckoutScreen2.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final user = _auth.currentUser;
    if (user != null) {
      final cartDocs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      setState(() {
        cartItems = cartDocs.docs
            .map((doc) => {
          ...doc.data(),
          'id': doc.id, // Add document ID for deletion
        })
            .toList();
        isLoading = false;
      });
    }
  }

  Future<void> removeFromCart(String productId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(productId)
          .delete();

      // Remove the item locally and refresh UI
      setState(() {
        cartItems.removeWhere((item) => item['id'] == productId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item removed from cart!'),
          backgroundColor: Colors.red,

        ),
      );
    }
  }

  double calculateTotal() {
    return cartItems.fold(0, (sum, item) => sum + (item['price'] as double));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Cart',
            style: GoogleFonts.nunitoSans(
              color: Colors.white, // Ensuring good contrast
              fontWeight: FontWeight.w900,
              fontSize: 25, // Optional: Adjust size as needed
            ),
          ),
        ),
        backgroundColor: Colors.teal[800], // Dark teal color
        foregroundColor: Colors.white, // Ensuring icons and back button are visible
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.network(
                      item['product_image'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported),
                    ),
                    title: Text(item['product_name'] ?? 'No Name'),
                    subtitle: Text(
                        'Color: ${item['color'] ?? 'N/A'}, Size: ${item['size'] ?? 'N/A'}\n₹${item['price'] ?? 0.0}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => removeFromCart(item['id']),
                    ),
                  ),
                );
              },
            ),
          ),
          if (cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Total: ₹${calculateTotal().toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (cartItems.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CheckoutScreen2(cartItems: cartItems),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Cart is empty!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child:
                      Text('Proceed to Checkout', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
