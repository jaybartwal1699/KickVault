import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'AddCategory.dart';
import 'AdminApproveProductsScreen.dart';
import 'AdminAssignDeliveryScreen.dart';
import 'AdminVerifyDeliveryPartnersScreen.dart';
import 'CustomerDrawer.dart';
import 'ManageCategories.dart';
import 'admin_screen.dart';
import 'AdminSeller_Approve.dart';
import 'login.dart';

class Admin_Drawer extends StatefulWidget {
  final String currentScreen;

  const Admin_Drawer({Key? key, required this.currentScreen}) : super(key: key);

  @override
  State<Admin_Drawer> createState() => _Admin_DrawerState();
}

class _Admin_DrawerState extends State<Admin_Drawer> {
  String userName = '';
  String userEmail = '';
  String profileImage = '';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
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

  void _showLogoutDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Dismiss the dialog
            child: Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              onConfirm(); // Call the logout function
            },
            child: Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored data

      await FirebaseAuth.instance.signOut(); // Sign out from Firebase

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 220.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.purple],
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
                    userRole.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
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
                    : Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerListTile(
                  title: "Admin Dashboard",
                  icon: Icons.dashboard,
                  isSelected: widget.currentScreen == 'Admin Screen',
                  onTap: () {
                    if (widget.currentScreen != 'Admin Screen') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AdminScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                // DrawerListTile(
                //   title: "Seller Approval",
                //   icon: Icons.approval_outlined,
                //   isSelected: widget.currentScreen == 'Seller Approval',
                //   onTap: () {
                //     if (widget.currentScreen != 'Seller Approval') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => AdminSeller_Approve()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),
                // DrawerListTile(
                //   title: "Approve Products",
                //   icon: Icons.assignment_add,
                //   isSelected: widget.currentScreen == 'Approve Products',
                //   onTap: () {
                //     if (widget.currentScreen != 'Approve Products') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => AdminApproveProductsScreen()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),
                // DrawerListTile(
                //   title: "Add New Category",
                //   icon: Icons.category,
                //   isSelected: widget.currentScreen == 'Add New Category',
                //   onTap: () {
                //     if (widget.currentScreen != 'Add New Category') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => AddCategory()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),
                // DrawerListTile(
                //   title: "Manage Category",
                //   icon: Icons.manage_accounts_rounded,
                //   isSelected: widget.currentScreen == 'Manage Category',
                //   onTap: () {
                //     if (widget.currentScreen != 'Manage Category') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => ManageCategories()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),


                // DrawerListTile(
                //   title: "Verify Delivery Partners",
                //   icon: Icons.manage_history_sharp,
                //   isSelected: widget.currentScreen == 'Verify Delivery Partners',
                //   onTap: () {
                //     if (widget.currentScreen != 'Verify Delivery Partners') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => AdminVerifyDeliveryPartnersScreen()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),

                // DrawerListTile(
                //   title: "Transit Orders",
                //   icon: Icons.manage_history_sharp,
                //   isSelected: widget.currentScreen == 'Transit Orders',
                //   onTap: () {
                //     if (widget.currentScreen != 'Transit Orders') {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => AdminAssignDeliveryScreen ()),
                //       );
                //     } else {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),

                DrawerListTile(
                  title: "Logout",
                  icon: Icons.logout,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => _showLogoutDialog(context, logout),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
