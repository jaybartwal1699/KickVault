import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickvault/OrdersToDeliver.dart';
import 'package:kickvault/OrdersToDeliverScreen.dart';
import 'package:kickvault/seller_complaints_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared preferences

import 'CollaborationApprovalScreen.dart';
import 'SellerDashboard.dart';
import 'SellerInfoScreen.dart';
import 'SellerProductsScreen.dart';
import 'SellerSalesDashboard.dart';
import 'login.dart';
import 'ProductFormScreen.dart';
import 'seller_screen.dart';
import 'SellerRegistrationForm.dart';

class SellerDrawer extends StatefulWidget {
  final String currentScreen;

  const SellerDrawer({Key? key, required this.currentScreen}) : super(key: key);

  @override
  State<SellerDrawer> createState() => _SellerDrawerState();
}

class _SellerDrawerState extends State<SellerDrawer> {
  String userName = '';
  String userEmail = '';
  String profileImage = '';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    loadUserData(); // Load user data from SharedPreferences
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if user data is already saved in SharedPreferences
    String? storedUserName = prefs.getString('userName');
    String? storedUserEmail = prefs.getString('userEmail');
    String? storedProfileImage = prefs.getString('profileImage');
    String? storedUserRole = prefs.getString('userRole');

    if (storedUserName != null && storedUserEmail != null) {
      setState(() {
        userName = storedUserName;
        userEmail = storedUserEmail;
        profileImage = storedProfileImage ?? '';
        userRole = storedUserRole ?? 'No Role';
      });
    } else {
      fetchUserData(); // If no data in SharedPreferences, fetch from Firestore
    }
  }

  Future<void> fetchUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          // Save the fetched data to SharedPreferences for future use
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userName', userDoc.get('name') ?? '');
          await prefs.setString('userEmail', userDoc.get('email') ?? '');
          await prefs.setString('profileImage', userDoc.get('profile_image') ?? '');
          await prefs.setString('userRole', userDoc.get('role') ?? 'No Role');

          setState(() {
            userName = userDoc.get('name') ?? '';
            userEmail = userDoc.get('email') ?? '';
            profileImage = userDoc.get('profile_image') ?? '';
            userRole = userDoc.get('role') ?? 'No Role';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Clear user data from SharedPreferences on logout
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.remove('profileImage');
      await prefs.remove('userRole');

      // Sign out and navigate to login screen
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 220.0, // Adjust height as needed
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.white],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              accountName: Text(
                userName,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userEmail,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    userRole, // Display user role
                    style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: profileImage.isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    profileImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, size: 50, color: Colors.white);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                )
                    : Icon(Icons.person, size: 50, color: Colors.black),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero, // Remove default padding
              children: [
                DrawerListTile(
                  title: "Home",
                  icon: Icons.home,
                  isSelected: widget.currentScreen == 'Home Screen',
                  onTap: () {
                    if (widget.currentScreen != 'Home Screen') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SellerScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                // DrawerListTile(
                //   title: "Add Products",
                //   icon: Icons.add_box,
                //   isSelected: widget.currentScreen == 'product_form',
                //   onTap: () {
                //     if (widget.currentScreen != 'product_form') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => ProductFormScreen()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),
                // DrawerListTile(
                //   title: "Seller Registration Details",
                //   icon: Icons.app_registration,
                //   isSelected: widget.currentScreen == 'detail form',
                //   onTap: () {
                //     if (widget.currentScreen != 'detail form') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => SellerRegistrationForm()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),
                DrawerListTile(
                  title: "Seller Info Page",
                  icon: Icons.info_outline_rounded,
                  isSelected: widget.currentScreen == 'Seller Info',
                  onTap: () {
                    if (widget.currentScreen != 'Seller Info') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SellerInfoScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),



                // DrawerListTile(
                //   title: "Your Products",
                //   icon: Icons.production_quantity_limits,
                //   isSelected: widget.currentScreen == 'Seller product',
                //   onTap: () {
                //     if (widget.currentScreen != 'Seller product') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => SellerProductsScreen()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),

                // DrawerListTile(
                //   title: "Approve collaboration posts",
                //   icon: Icons.post_add,
                //   isSelected: widget.currentScreen == 'collaboration_posts',
                //   onTap: () {
                //     if (widget.currentScreen != 'collaboration_posts') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => CollaborationApprovalScreen()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),


                // DrawerListTile(
                //   title: "Cancelled orders",
                //   icon: Icons.cancel_schedule_send_sharp,
                //   isSelected: widget.currentScreen == 'Cancelled orders',
                //   onTap: () {
                //     if (widget.currentScreen != 'Cancelled orders') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => SellerComplaintsScreen()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),


                // DrawerListTile(
                //   title: "orders",
                //   icon: Icons.note_add_outlined,
                //   isSelected: widget.currentScreen == 'orders',
                //   onTap: () {
                //     if (widget.currentScreen != 'orders') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => OrdersToDeliver()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),

            // DrawerListTile(
            //     title: "Sells Data",
            //     icon: Icons.bar_chart_outlined,
            //     isSelected: widget.currentScreen == 'Sells data',
            //     //drawer: const SellerDrawer(currentScreen: 'orders sold'),
            //     onTap: () {
            //       if (widget.currentScreen != 'Sells data') {
            //         Navigator.pushReplacement(
            //           context,
            //           MaterialPageRoute(builder: (context) => SellerDashboard()),
            //         );
            //       } else {
            //         Navigator.pop(context);
            //       }
            //     },
            //   ),

                // DrawerListTile(
                //   title: "orders sold",
                //   icon: Icons.money,
                //   isSelected: widget.currentScreen == 'orders sold',
                //   //drawer: const SellerDrawer(currentScreen: 'orders sold'),
                //   onTap: () {
                //     if (widget.currentScreen != 'orders sold') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => SellerSalesDashboard()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),


                DrawerListTile(
                  title: "Logout",
                  icon: Icons.logout,
                  textColor: Colors.red, // Red text color
                  iconColor: Colors.red, // Red icon color
                  isSelected: false,
                  onTap: logout, // Call logout function
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color textColor;
  final Color iconColor;
  final bool isSelected;

  const DrawerListTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.textColor = Colors.black,
    this.iconColor = Colors.black,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Adjust padding
      leading: Icon(icon, color: isSelected ? Colors.black : iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.black : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      tileColor: isSelected ? Colors.black.withOpacity(0.1) : null,
    );
  }
}
