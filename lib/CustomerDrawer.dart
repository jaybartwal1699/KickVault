import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickvault/RejectedCollaborationScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AboutScreen.dart';
import 'CustomerProfile.dart';
import 'SupportScreen.dart';
import 'YourOrdersScreen.dart';
import 'customer_screen.dart';

class CustomerDrawer extends StatefulWidget {
  final String currentScreen;

  const CustomerDrawer({Key? key, required this.currentScreen}) : super(key: key);

  @override
  State<CustomerDrawer> createState() => _CustomerDrawerState();
}

class _CustomerDrawerState extends State<CustomerDrawer> {
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
        userRole = storedUserRole ?? 'No Role';
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

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
                colors: [Colors.blue, Colors.teal],
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
                        MaterialPageRoute(builder: (context) => CustomerScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                DrawerListTile(
                  title: "Profile",
                  icon: Icons.person,
                  isSelected: widget.currentScreen == 'Profile',
                  onTap: () {
                    if (widget.currentScreen != 'Profile') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CustomerProfile()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                DrawerListTile(
                  title: "Rejected Collaboration posts",
                  icon: Icons.note_add_rounded,
                  isSelected: widget.currentScreen == 'RejectedCollaborationScreen',
                  onTap: () {
                    if (widget.currentScreen != 'RejectedCollaborationScreen') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => RejectedCollaborationScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),

                DrawerListTile(
                  title: "Your orders",
                  icon: Icons.delivery_dining,
                  isSelected: widget.currentScreen == 'Your orders',
                  onTap: () {
                    if (widget.currentScreen != 'Your orders') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => YourOrdersScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),

                DrawerListTile(
                  title: "About",
                  icon: Icons.info_outline,
                  isSelected: widget.currentScreen == 'AboutScreen',
                  onTap: () {
                    if (widget.currentScreen != 'AboutScreen') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AboutScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),

                DrawerListTile(
                  title: "Support",
                  icon: Icons.support_agent,
                  isSelected: widget.currentScreen == 'Support',
                  onTap: () {
                    if (widget.currentScreen != 'Support') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SupportScreen()),
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
      leading: Icon(icon, color: isSelected ? Colors.teal[900] : iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.teal[900] : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      tileColor: isSelected ? Colors.teal.withOpacity(0.1) : null,
    );
  }
}
