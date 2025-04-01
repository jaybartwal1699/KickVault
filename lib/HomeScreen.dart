import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AddPostScreen.dart';
import 'SearchScreen.dart';
import 'ProductDescriptionScreen.dart';

class HomeScreen extends StatelessWidget {
  String _formatPrice(dynamic price) {
    if (price == null) return '₹0.00';
    return '₹${price.toStringAsFixed(2)}';
  }

  Widget _buildColorDot(String colorName) {
    Color dotColor;
    switch (colorName.toLowerCase().trim()) {
      case 'red':
        dotColor = Colors.red;
        break;
      case 'yellow':
        dotColor = Colors.yellow;
        break;
      case 'blue':
        dotColor = Colors.blue;
        break;
      case 'black':
        dotColor = Colors.black;
        break;
      case 'white':
        dotColor = Colors.grey[300]!;
        break;
      case 'orange':
        dotColor = Colors.orange;
        break;
      case 'golden':
        dotColor = const Color(0xFFFFD700); // Hex code for golden color
        break;
      case 'purple':
        dotColor = Colors.purple; // Fixed purple color
        break;
      case 'green':
        dotColor = Colors.green;
        break;
      case 'pink':
        dotColor = Colors.pink;
        break;
      case 'brown':
        dotColor = const Color(0xFF8B4513); // Saddle brown
        break;
      case 'grey':
      case 'gray':
        dotColor = Colors.grey;
        break;
      case 'navy':
        dotColor = const Color(0xFF000080); // Navy blue
        break;
      case 'teal':
        dotColor = Colors.teal;
        break;
      case 'silver':
        dotColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 'maroon':
        dotColor = const Color(0xFF800000); // Maroon
        break;
      case 'cyan':
        dotColor = Colors.cyan;
        break;
      case 'lime':
        dotColor = Colors.lime;
        break;
      case 'indigo':
        dotColor = Colors.indigo;
        break;
      case 'amber':
        dotColor = Colors.amber;
        break;
      case 'olive':
        dotColor = const Color(0xFF808000); // Olive
        break;
      case 'coral':
        dotColor = const Color(0xFFFF7F50); // Coral
        break;
      case 'turquoise':
        dotColor = const Color(0xFF40E0D0); // Turquoise
        break;
      case 'lavender':
        dotColor = const Color(0xFFE6E6FA); // Lavender
        break;
      case 'cream':
        dotColor = const Color(0xFFFFFDD0); // Cream
        break;
      case 'burgundy':
        dotColor = const Color(0xFF800020); // Burgundy
        break;
      default:
        dotColor = Colors.grey;
    }

    return Container(
      width: 20,
      height: 20,
      margin: EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await _showExitConfirmationDialog(context);
        return exitApp;
      },
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              // Search and Add Post Row
              Container(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Search Box
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SearchScreen()),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                'Search products...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12), // Space between search and button

                    // Add Post Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddPostScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Button background color
                        foregroundColor: Colors.white, // Text color
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Add Post'),
                    ),
                  ],
                ),
              ),

              // Products Grid in Expanded
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Products')
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Something went wrong'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No products available'));
                    }

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          List<dynamic> colors = (data['colors'] as List?) ?? [];

                          return GestureDetector(
                            onTap: () {
                              var productDoc = snapshot.data!.docs[index]; // Get Firestore document
                              var productData = productDoc.data() as Map<String, dynamic>;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDescriptionScreen(
                                    productData: {
                                      'id': productDoc.id, // ✅ Add the document ID to productData
                                      ...productData,       // ✅ Spread the rest of the product details
                                    },
                                  ),
                                ),
                              );
                            },

                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  Expanded(
                                    flex: 3,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Container(
                                        width: double.infinity,
                                        child: data['images'] != null && (data['images'] as List).isNotEmpty
                                            ? Image.network(
                                          data['images'][0],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.image_not_supported, color: Colors.grey),
                                        )
                                            : Icon(Icons.image_not_supported, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  // Product Details
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            data['name'] ?? 'Unnamed Product',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                _formatPrice(data['metadata']?['discountedPrice']),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (data['metadata']?['hasDiscount'] == true)
                                                Expanded(
                                                  child: Text(
                                                    _formatPrice(data['price']),
                                                    style: TextStyle(
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          if (colors.isNotEmpty)
                                            SizedBox(
                                              height: 20,
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: colors.length,
                                                itemBuilder: (context, colorIndex) {
                                                  return _buildColorDot(
                                                    colors[colorIndex]['colorName'] ?? '',
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Function to show exit confirmation dialog
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Exit App"),
        content: Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Stay on the screen
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Exit
            child: Text("Exit"),
          ),
        ],
      ),
    ) ??
        false; // Default to false if user dismisses the dialog
  }

}

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         body: Column(
//           children: [
//             // Search and Add Post Row
//             Container(
//               padding: const EdgeInsets.all(12.0),
//               child: Row(
//                 children: [
//                   // Search Box
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => SearchScreen()),
//                         );
//                       },
//                       child: Container(
//                         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[100],
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.search, color: Colors.grey[600]),
//                             SizedBox(width: 8),
//                             Text(
//                               'Search products...',
//                               style: TextStyle(color: Colors.grey[600]),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   SizedBox(width: 12), // Space between search and button
//
//                   // Add Post Button
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => AddPostScreen()),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.black, // Button background color
//                       foregroundColor: Colors.white, // Text color
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text('Add Post'),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Products Grid in Expanded
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('Products')
//                     .where('status', isEqualTo: 'active')
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasError) {
//                     return Center(child: Text('Something went wrong'));
//                   }
//
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   }
//
//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return Center(child: Text('No products available'));
//                   }
//
//                   return Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12),
//                     child: GridView.builder(
//                       shrinkWrap: true,
//                       physics: AlwaysScrollableScrollPhysics(),
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         childAspectRatio: 0.65,
//                         crossAxisSpacing: 12,
//                         mainAxisSpacing: 12,
//                       ),
//                       itemCount: snapshot.data!.docs.length,
//                       itemBuilder: (context, index) {
//                         var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
//                         List<dynamic> colors = (data['colors'] as List?) ?? [];
//
//                         return GestureDetector(
//                           onTap: () {
//                             var productDoc = snapshot.data!.docs[index]; // Get Firestore document
//                             var productData = productDoc.data() as Map<String, dynamic>;
//
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ProductDescriptionScreen(
//                                   productData: {
//                                     'id': productDoc.id, // ✅ Add the document ID to productData
//                                     ...productData,       // ✅ Spread the rest of the product details
//                                   },
//                                 ),
//                               ),
//                             );
//                           },
//
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.grey.withOpacity(0.1),
//                                   spreadRadius: 1,
//                                   blurRadius: 5,
//                                   offset: Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // Product Image
//                                 Expanded(
//                                   flex: 3,
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
//                                     child: Container(
//                                       width: double.infinity,
//                                       child: data['images'] != null && (data['images'] as List).isNotEmpty
//                                           ? Image.network(
//                                         data['images'][0],
//                                         fit: BoxFit.cover,
//                                         errorBuilder: (context, error, stackTrace) =>
//                                             Icon(Icons.image_not_supported, color: Colors.grey),
//                                       )
//                                           : Icon(Icons.image_not_supported, color: Colors.grey),
//                                     ),
//                                   ),
//                                 ),
//                                 // Product Details
//                                 Expanded(
//                                   flex: 2,
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Text(
//                                           data['name'] ?? 'Unnamed Product',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                         SizedBox(height: 4),
//                                         Row(
//                                           children: [
//                                             Text(
//                                               _formatPrice(data['metadata']?['discountedPrice']),
//                                               style: TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 color: Colors.green,
//                                                 fontSize: 14,
//                                               ),
//                                             ),
//                                             if (data['metadata']?['hasDiscount'] == true)
//                                               Expanded(
//                                                 child: Text(
//                                                   _formatPrice(data['price']),
//                                                   style: TextStyle(
//                                                     decoration: TextDecoration.lineThrough,
//                                                     color: Colors.grey,
//                                                     fontSize: 12,
//                                                   ),
//                                                   overflow: TextOverflow.ellipsis,
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                         SizedBox(height: 4),
//                                         if (colors.isNotEmpty)
//                                           SizedBox(
//                                             height: 20,
//                                             child: ListView.builder(
//                                               scrollDirection: Axis.horizontal,
//                                               itemCount: colors.length,
//                                               itemBuilder: (context, colorIndex) {
//                                                 return _buildColorDot(
//                                                   colors[colorIndex]['colorName'] ?? '',
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }