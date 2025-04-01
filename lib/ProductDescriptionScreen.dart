import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'CheckoutScreen.dart';


class ProductDescriptionScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDescriptionScreen({Key? key, required this.productData}) : super(key: key);

  @override
  _ProductDescriptionScreenState createState() => _ProductDescriptionScreenState();
}

class _ProductDescriptionScreenState extends State<ProductDescriptionScreen> {
  int _currentColorIndex = 0;
  int _currentSizeIndex = 0;
  int _currentImageIndex = 0;
  Map<String, dynamic>? sellerDetails;




  @override
  void initState() {
    super.initState();
    fetchSellerDetails();
  }

  @override
  void dispose() {

    super.dispose();
  }


  Future<void> fetchSellerDetails() async {
    final sellerId = widget.productData['seller_id']; // Get seller ID from product data

    if (sellerId == null) {
      print('Error: seller_id is null in productData.');
      return;
    }

    try {
      // Fetch seller details from 'seller_details' collection
      final sellerDoc = await FirebaseFirestore.instance
          .collection('seller_details')
          .doc(sellerId)
          .get();

      if (!sellerDoc.exists) {
        print('Error: Seller document does not exist.');
        return;
      }

      Map<String, dynamic> sellerData = sellerDoc.data()!;

      // Fetch seller's address from 'users' collection using their UID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId) // Using sellerId since it's the same as the UID in users collection
          .get();

      if (userDoc.exists) {
        sellerData['address'] = userDoc.data()?['address'] ?? {}; // Fetch the address
      } else {
        sellerData['address'] = {}; // Set empty address if not found
        print('Warning: Seller address not found in users collection.');
      }

      setState(() {
        sellerDetails = {
          'uid': sellerDoc.id, // Store the document ID as seller_id
          ...sellerData,
        };
      });

      print('Seller details fetched: $sellerDetails');
    } catch (e) {
      print('Error fetching seller details: $e');
    }
  }
  int _getStockForSelectedColorAndSize() {
    final List<dynamic> colors = widget.productData['colors'] ?? [];
    if (colors.isEmpty || _currentColorIndex >= colors.length) return 0;

    final selectedColor = colors[_currentColorIndex];
    final List<dynamic> sizes = selectedColor['sizes'] ?? [];
    if (sizes.isEmpty || _currentSizeIndex >= sizes.length) return 0;

    final selectedSize = sizes[_currentSizeIndex];
    return (selectedSize['stock'] as num?)?.toInt() ?? 0;
  }



  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {

    final List<dynamic> images = widget.productData['images'] ?? [];
    final List<dynamic> colors = widget.productData['colors'] ?? [];
    final List<dynamic> sizes = colors.isNotEmpty
        ? (colors[_currentColorIndex]['sizes'] ?? [])
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [

          // Image Carousel with Page Indicator
          SliverAppBar(
            expandedHeight: 400.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  CarouselSlider.builder(
                    itemCount: images.length,
                    carouselController: _carouselController,
                    options: CarouselOptions(
                      height: 400,
                      viewportFraction: 1.0,
                      autoPlay: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                    itemBuilder: (context, index, realIndex) =>
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image_not_supported, size: 100),
                          ),
                        ),
                  ),
                  Positioned(
                    bottom: 20,
                    child: AnimatedSmoothIndicator(
                      activeIndex: _currentImageIndex,
                      count: images.length,
                      effect: WormEffect(
                        dotWidth: 10,
                        dotHeight: 10,
                        activeDotColor: Colors.black,
                        dotColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.productData['name'] ?? 'Product Name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${widget.productData['metadata']?['discountedPrice'] ?? 0}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            if (widget.productData['metadata']?['hasDiscount'] == true)
                              Text(
                                '₹${widget.productData['price']}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Color Selection
                  SizedBox(height: 20),
                  Text(
                    'Available Colors',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 85,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentColorIndex = index;
                              _currentSizeIndex = 0;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 12),
                            width: 60,
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    border: _currentColorIndex == index
                                        ? Border.all(color: Colors.black, width: 3)
                                        : null,
                                    boxShadow: _currentColorIndex == index
                                        ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                      )
                                    ]
                                        : [],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      colors[index]['colorImage'],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(color: Colors.grey),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  colors[index]['colorName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _currentColorIndex == index
                                        ? Colors.black
                                        : Colors.grey[600],
                                    fontWeight: _currentColorIndex == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Size Selection
                  SizedBox(height: 16),
                  Text(
                    'Sizes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sizes.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentSizeIndex = index;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 10),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _currentSizeIndex == index
                                  ? Colors.black
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                sizes[index]['size'],
                                style: TextStyle(
                                  color: _currentSizeIndex == index
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8), // Space before stock info
// Stock Information for Selected Color and Size
                  Text(
                    'Stock Available: ${_getStockForSelectedColorAndSize()}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getStockForSelectedColorAndSize() <= 0
                          ? Colors.red
                          : _getStockForSelectedColorAndSize() < 10
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Seller Details
                  SizedBox(height: 16),
                  if (sellerDetails != null) ...[
                    Text(
                      'Product By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFA2E1E1), Color(0xFFFCF9F9)], // Replace with your desired gradient colors
                          begin: Alignment.topLeft, // Start point of the gradient
                          end: Alignment.bottomRight, // End point of the gradient
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Store Name: ${sellerDetails!['business_details']?['store_name']}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Seller Name: ${sellerDetails!['name']}',
                                  style: TextStyle(fontSize: 16,),
                                ),
                              ),
                            ],
                          ),
                          // SizedBox(height: 12),
                          // Row(
                          //   children: [
                          //     Icon(Icons.email, color: Colors.black, size: 20),
                          //     SizedBox(width: 8),
                          //     Expanded(
                          //       child: Text(
                          //         'Business Email: ${sellerDetails!['contact']?['business_email'] ?? 'N/A'}',
                          //         style: TextStyle(fontSize: 16),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],



                  // Description
                  SizedBox(height: 16),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),
                  Text(
                    widget.productData['description'] ?? 'No description available',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),

                  // Gender Display
                  // Gender Information Display
                  SizedBox(height: 16),
                  Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    // First check if gender exists directly in the product data
                    widget.productData['gender'] ??
                        // Then check if it exists in the details map
                        widget.productData['details']?['gender'] ??
                        // Default value if not found in either location
                        'Not specified',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),


                  // Technical Details
                  SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: ((widget.productData['details'] as Map?) ?? {})
                              .entries
                              .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0), // Adjust vertical spacing between rows
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Align the content to start
                              children: [
                                Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16, // Adjust font size for labels
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0), // Space between key and value
                                  child: Text(
                                    entry.value.toString(),
                                    style: TextStyle(fontSize: 16), // Match value font size
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),



                  // Action Buttons
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('cart')
                                  .doc(widget.productData['id'])
                                  .set({
                                'product_id': widget.productData['id'],
                                'product_name': widget.productData['name'],
                                'product_image': widget.productData['colors'][_currentColorIndex]['colorImage'],
                                'color': widget.productData['colors'][_currentColorIndex]['colorName'],
                                'size': widget.productData['colors'][_currentColorIndex]['sizes'][_currentSizeIndex]['size'],
                                'price': widget.productData['metadata']['discountedPrice'],
                                'seller_details': sellerDetails,
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to cart'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: BorderSide(color: Colors.black),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('Add to Cart'),
                        ),
                      ),

                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (sellerDetails != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutScreen(
                                    productData: {
                                      'id': widget.productData['id'] ?? widget.productData['documentId'], // ✅ Ensure ID is passed
                                      ...widget.productData,
                                    },
                                    sellerDetails: sellerDetails!,
                                    selectedColorIndex: _currentColorIndex,
                                    selectedSizeIndex: _currentSizeIndex,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please wait while loading seller details')),
                              );
                            }
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('Buy Now'),
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
    );
  }
}

