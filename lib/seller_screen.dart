// import 'dart:ui'; // For ImageFilter and BackdropFilter
// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'ProductFormScreen.dart';
// import 'login.dart';
// import 'Seller_Drawer.dart';
//
// class SellerScreen extends StatelessWidget {
//   const SellerScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final List<String> brandLogos = [
//       'assets/images/1.png',
//       'assets/images/2.png',
//       'assets/images/3.png',
//       'assets/images/4.png',
//     ];
//
//     final List<String> testimonials = [
//       "Kick Vault helped me double my sales within the first month!",
//       "The platform is super easy to use, and the support team is amazing!",
//       "Thanks to Kick Vault, my small business is now reaching global customers.",
//       "Fast shipping and seamless logistics make selling so much easier."
//     ];
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF1E1E1E),
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         flexibleSpace: _buildGlassContainer(
//           context: context, // passing context here
//           height: kToolbarHeight + MediaQuery.of(context).padding.top,
//           gradient: LinearGradient(
//             colors: [
//               Colors.green.withOpacity(0.2),
//               Colors.green.withOpacity(0.1),
//             ],
//           ),
//           blur: 20,
//         ),
//         title: Text(
//           "Welcome Seller",
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//       ),
//       drawer: SellerDrawer(currentScreen: 'Home Screen'),
//       body: Stack(
//         children: [
//           // Background gradient and patterns
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   const Color(0xFF1E1E1E),
//                   Colors.green.withOpacity(0.2),
//                   const Color(0xFF1E1E1E),
//                 ],
//               ),
//             ),
//           ),
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
//
//                 // Welcome Container with Glassmorphism
//                 _buildGlassContainer(
//                   context: context,
//                   height: 260,
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Welcome to Kick Vault!",
//                           style: GoogleFonts.poppins(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           "Your trusted e-commerce platform for selling premium shoes. Partner with us and reach thousands of customers across the globe!",
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             color: Colors.white.withOpacity(0.8),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // Enhanced Carousel
//                 Text(
//                   "Featured Brands",
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white.withOpacity(0.9),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 CarouselSlider(
//                   items: brandLogos.map((logo) {
//                     return Builder(
//                       builder: (BuildContext context) {
//                         return _buildGlassContainer(
//                           context: context, // passing context here
//                           height: 200,
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(5),
//                             child: Image.asset(
//                               logo,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   }).toList(),
//                   options: CarouselOptions(
//                     height: 170,
//                     autoPlay: true,
//                     enlargeCenterPage: true,
//                     viewportFraction: 0.8,
//                     autoPlayInterval: const Duration(seconds: 3),
//                   ),
//                 ),
//
//                 const SizedBox(height: 32),
//
//                 // Enhanced Features Section
//                 Text(
//                   "Why Sell with Kick Vault?",
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white.withOpacity(0.9),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 GridView.count(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   crossAxisCount: 2,
//                   mainAxisSpacing: 16,
//                   crossAxisSpacing: 16,
//                   childAspectRatio: 0.85,
//                   children: [
//                     _buildFeatureCard(
//                       context: context,
//                       icon: Icons.shopping_cart,
//                       title: "Massive Customer Base",
//                       description: "Reach thousands of customers looking for premium quality shoes.",
//                     ),
//                     _buildFeatureCard(
//                       context: context,
//                       icon: Icons.local_shipping,
//                       title: "Fast Shipping",
//                       description: "We handle shipping and logistics so you can focus on selling.",
//                     ),
//                     _buildFeatureCard(
//                       context: context,
//                       icon: Icons.trending_up,
//                       title: "Increase Sales",
//                       description: "Maximize your profit with our competitive fee structure.",
//                     ),
//                     _buildFeatureCard(
//                       context: context,
//                       icon: Icons.support_agent,
//                       title: "24/7 Support",
//                       description: "Our dedicated support team is here to help you every step of the way.",
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 32),
//
//                 // Enhanced Testimonials
//                 Text(
//                   "What Our Sellers Say",
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white.withOpacity(0.9),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 CarouselSlider(
//                   items: testimonials.map((testimonial) {
//                     return _buildGlassContainer(
//                       context: context,
//                       height: 120,
//                       child: Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               '"$testimonial"',
//                               style: GoogleFonts.poppins(
//                                 fontStyle: FontStyle.italic,
//                                 color: Colors.white.withOpacity(0.9),
//                                 fontSize: 14,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                   options: CarouselOptions(
//                     height: 120,
//                     autoPlay: true,
//                     enlargeCenterPage: true,
//                     viewportFraction: 0.9,
//                     autoPlayInterval: const Duration(seconds: 4),
//                   ),
//                 ),
//
//                 const SizedBox(height: 32),
//
//                 // Enhanced Steps Section
//                 Text(
//                   "How to Start Selling?",
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white.withOpacity(0.9),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: 4,
//                   itemBuilder: (context, index) {
//                     final steps = [
//                       {
//                         "title": "Create an Account",
//                         "desc": "Sign up and set up your profile."
//                       },
//                       {
//                         "title": "List Your Products",
//                         "desc": "Add product details and images."
//                       },
//                       {
//                         "title": "Start Selling",
//                         "desc": "Go live and start reaching customers."
//                       },
//                       {
//                         "title": "Earn Revenue",
//                         "desc": "Enjoy seamless payouts and grow your business."
//                       },
//                     ];
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       child: _buildGlassContainer(
//                         context: context,
//                         height: 80,
//                         child: ListTile(
//                           leading: Container(
//                             width: 40,
//                             height: 40,
//                             decoration: BoxDecoration(
//                               color: Colors.green.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 "${index + 1}",
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           title: Text(
//                             steps[index]["title"]!,
//                             style: GoogleFonts.poppins(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           subtitle: Text(
//                             steps[index]["desc"]!,
//                             style: GoogleFonts.poppins(
//                               color: Colors.white.withOpacity(0.7),
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//
//                 const SizedBox(height: 32),
//
//                 // Enhanced Call to Action
//                 Center(
//                   child: _buildGlassContainer(
//                     context: context,
//                     height: 56,
//                     width: 200,
//                     child: Material(
//                       color: Colors.transparent,
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(28),
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                                 builder: (context) => ProductFormScreen()),
//                           );
//                         },
//                         child: Center(
//                           child: Text(
//                             "Start Selling Now!",
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Custom glass container implementation using BackdropFilter
//   Widget _buildGlassContainer({
//     required BuildContext context,
//     double height = 150,
//     double width = double.infinity,
//     Widget? child,
//     LinearGradient? gradient,
//     double blur = 10,
//   }) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: Stack(
//         children: [
//           Container(
//             height: height,
//             width: width,
//             decoration: BoxDecoration(
//               gradient: gradient ?? LinearGradient(colors: [
//                 Colors.white.withOpacity(0.1),
//                 Colors.white.withOpacity(0.05)
//               ]),
//               borderRadius: BorderRadius.circular(20),
//             ),
//           ),
//           BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
//             child: Container(
//               height: height,
//               width: width,
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: child,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Feature Card Builder
//   Widget _buildFeatureCard({
//     required BuildContext context,
//     required IconData icon,
//     required String title,
//     required String description,
//   }) {
//     return Container(
//       height: 250, // Responsive height for the feature card
//       child: _buildGlassContainer(
//         context: context,
//         height: 250,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 40,
//                 color: Colors.green,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 title,
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 description,
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.white.withOpacity(0.7),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
import 'dart:ui';

import 'package:flutter/material.dart';
import "package:carousel_slider/carousel_slider.dart";
import 'package:kickvault/SellerProductsScreen.dart';
import 'package:kickvault/SellerSalesDashboard.dart';
import 'package:kickvault/seller_complaints_screen.dart';
import 'CollaborationApprovalScreen.dart';
import 'OrdersToDeliver.dart';
import 'OrdersToDeliverScreen.dart';
import 'ProductFormScreen.dart';
import 'SellerDashboard.dart';
import 'SellerRegistrationForm.dart';
import 'StockManagementScreen.dart';
import 'login.dart';
import 'Seller_Drawer.dart';

class SellerScreen extends StatelessWidget {
  const SellerScreen({super.key});

  Future<bool> _onBackPressed(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Exit Confirmation"),
        content: Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Yes"),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> brandLogos = [
      'assets/images/1.png',
      'assets/images/2.png',
      'assets/images/3.png',
      'assets/images/4.png',
    ];

    final List<Map<String, String>> testimonials = [
      {
        "text": "Kick Vault helped me double my sales within the first month!",
        "author": "Ajay D.",
        "role": "Sneaker Store Owner"
      },
      {
        "text": "The platform is super easy to use, and the support team is amazing!",
        "author": "Srinivas Amin",
        "role": "Independent Seller"
      },
      {
        "text": "Thanks to Kick Vault, my small business is now reaching global customers.",
        "author": "Dhruv Patel",
        "role": "Boutique Owner"
      },
      {
        "text": "Fast shipping and seamless logistics make selling so much easier.",
        "author": "Nisha",
        "role": "Footwear Specialist"
      }
    ];

    return WillPopScope(
      onWillPop: () async {
        // Prevent navigating back to the login screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => SellerScreen()));
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Light background for contrast
        appBar: AppBar(
          title: const Text(
            'KickVault Sellers',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.black, // Solid black color
          elevation: 4, // Slight shadow for depth
          iconTheme: const IconThemeData(
              color: Colors.white), // Ensures drawer icon is white
        ),
        drawer: SellerDrawer(currentScreen: 'Home Screen'),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.grey.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Transform Your\nShoes Business",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Join thousands of successful sellers on the premier platform for premium footwear",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // **Navigation Tiles**
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildNavigationTile(
                          context,
                          icon: Icons.dashboard,
                          title: "Sells Dashboard",
                          destination: SellerDashboard(),
                        ),
                        _buildNavigationTile(
                          context,
                          icon: Icons.inventory,
                          title: "Stock Management",
                          destination: StockManagementScreen(),
                        ),
                        _buildNavigationTile(
                          context,
                          icon: Icons.local_shipping,
                          title: "Orders to Deliver",
                          destination: OrdersToDeliver(),
                        ),
                        _buildNavigationTile(
                          context,
                          icon: Icons.add,
                          title: "Add Product",
                          destination: ProductFormScreen(),
                        ),
                        _buildNavigationTile(
                          context,
                          icon: Icons.app_registration,
                          title: "Seller Registration",
                          destination: SellerRegistrationForm(),
                        ),
                        _buildNavigationTile(
                          context,
                          icon: Icons.handshake,
                          title: "Collaboration Approvals",
                          destination: CollaborationApprovalScreen(),
                        ),
                        _buildNavigationTile(
                          context,
                          icon: Icons.sell_rounded,
                          title: "Your Products",
                          destination: SellerProductsScreen(),
                        ),
                        _buildNavigationTile(
                          context,
                          icon: Icons.cancel_schedule_send,
                          title: "Cancelled orders",
                          destination: SellerComplaintsScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

// **Stats Section**
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildStatCard("10K+", "Active Sellers"),
                    ),
                    const SizedBox(width: 12), // Spacing between cards
                    Expanded(
                      child: _buildStatCard("1M+", "Monthly Buyers"),
                    ),
                    const SizedBox(width: 12), // Spacing between cards
                    Expanded(
                      child: _buildStatCard("98%", "Satisfaction"),
                    ),
                  ],
                ),
              ),



              // Stats Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                ),
              ),

              // Featured Brands
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Trusted by Top Brands",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              CarouselSlider(
                items: brandLogos.map((logo) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          logo,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  );
                }).toList(),
                options: CarouselOptions(
                  height: 120.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.4,
                  autoPlayInterval: const Duration(seconds: 3),
                ),
              ),

              // Why Sell with Us
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Why Choose Kick Vault?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureCard(
                      Icons.trending_up,
                      "Boost Your Sales",
                      "Access millions of sneaker enthusiasts and grow your business exponentially.",
                    ),
                    _buildFeatureCard(
                      Icons.security,
                      "Secure Payments",
                      "Get paid reliably with our secure payment system and seller protection.",
                    ),
                    _buildFeatureCard(
                      Icons.support_agent,
                      "24/7 Support",
                      "Our dedicated team is always here to help you succeed.",
                    ),
                  ],
                ),
              ),

              // Testimonials
              // Testimonials Section with Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "    What Our Sellers Say", // Section Header
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Matching the color scheme
                      ),
                    ),
                    const SizedBox(height: 16),
                    CarouselSlider(
                      items: testimonials.map((testimonial) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(horizontal: 8.0),
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.black, // Testimonial card background color updated
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          testimonial["text"]!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white, // Text color updated
                                            fontStyle: FontStyle.italic,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.only(top: 16),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          testimonial["author"]!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white, // Author name color updated
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          testimonial["role"]!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade400, // Role text color updated
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
                      }).toList(),
                      options: CarouselOptions(
                        height: 250.0, // Adjusted height
                        autoPlay: true,
                        enlargeCenterPage: true,
                        viewportFraction: 0.85,
                        autoPlayInterval: const Duration(seconds: 5),
                      ),
                    ),
                  ],
                ),
              ),



              // Call to Action
              // How to Start Selling Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      " How to Start Selling?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // White header text
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final steps = [
                          {
                            "title": "Create an Account",
                            "desc": "Sign up and set up your profile."
                          },
                          {
                            "title": "List Your Products",
                            "desc": "Add product details and images."
                          },
                          {
                            "title": "Start Selling",
                            "desc": "Go live and start reaching customers."
                          },
                          {
                            "title": "Earn Revenue",
                            "desc": "Enjoy seamless payouts and grow your business."
                          },
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black, // Light background for number
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                    color: Colors.white, // Dark number text
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              steps[index]["title"]!,
                              style: TextStyle(
                                color: Colors.black, // White text for the title
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              steps[index]["desc"]!,
                              style: TextStyle(
                                color: Colors.black, // Lighter white for description
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      "Ready to Start?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      "Join thousands of successful sellers on Kick Vault",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => SellerRegistrationForm()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Create Seller Account",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNavigationTile(BuildContext context,
      {required IconData icon, required String title, required Widget destination}) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => destination));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
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
