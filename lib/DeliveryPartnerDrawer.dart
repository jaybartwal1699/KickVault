import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickvault/DeliveryPartnerProfileScreen.dart';
import 'package:kickvault/OrdersToDeliverScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CompletedDeliveriesScreen.dart';
import 'DeliveryPartnerScreen.dart';
import 'login.dart';

class DeliveryPartnerDrawer extends StatefulWidget {
  final String currentScreen;

  const DeliveryPartnerDrawer({Key? key, required this.currentScreen}) : super(key: key);

  @override
  State<DeliveryPartnerDrawer> createState() => _DeliveryPartnerDrawerState();
}

class _DeliveryPartnerDrawerState extends State<DeliveryPartnerDrawer> {
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

    String? storedUserName = prefs.getString('userName');
    String? storedUserEmail = prefs.getString('userEmail');
    String? storedProfileImage = prefs.getString('profileImage');
    String? storedUserRole = prefs.getString('userRole');

    if (storedUserName != null && storedUserEmail != null) {
      setState(() {
        userName = storedUserName;
        userEmail = storedUserEmail;
        profileImage = storedProfileImage ?? '';
        userRole = storedUserRole ?? 'Delivery Partner';
      });
    } else {
      fetchUserData();
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
          await prefs.setString('userRole', userDoc.get('role') ?? 'Delivery Partner');

          setState(() {
            userName = userDoc.get('name') ?? '';
            userEmail = userDoc.get('email') ?? '';
            profileImage = userDoc.get('profile_image') ?? '';
            userRole = userDoc.get('role') ?? 'Delivery Partner';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all user data

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
            height: 220.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.red],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(color: Colors.transparent),
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
                    userRole,
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
              padding: EdgeInsets.zero,
              children: [
                DrawerListTile(
                  title: "Home",
                  icon: Icons.home,
                  isSelected: widget.currentScreen == 'Home',
                  onTap: () {
                    if (widget.currentScreen != 'Home') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DeliveryPartnerScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                DrawerListTile(
                  title: "Orders to Deliver",
                  icon: Icons.local_shipping,
                  isSelected: widget.currentScreen == 'Orders to Deliver',
                  onTap: () {
                    if (widget.currentScreen != 'Orders to Deliver') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => OrdersToDeliverScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                DrawerListTile(
                  title: "Completed Deliveries",
                  icon: Icons.check_circle,
                  isSelected: widget.currentScreen == 'Completed Deliveries',
                  onTap: () {
                    if (widget.currentScreen != 'Completed Deliveries') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CompletedDeliveriesScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),

                DrawerListTile(
                  title: "Profile",
                  icon: Icons.contact_emergency,
                  isSelected: widget.currentScreen == 'profile',
                  onTap: () {
                    if (widget.currentScreen != 'profile') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DeliveryPartnerProfileScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),

                DrawerListTile(
                  title: "Logout",
                  icon: Icons.logout,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  isSelected: false,
                  onTap: logout,
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
      leading: Icon(icon, color: isSelected ? Colors.orangeAccent : iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.orangeAccent : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      tileColor: isSelected ? Colors.orangeAccent.withOpacity(0.1) : null,
    );
  }
}
