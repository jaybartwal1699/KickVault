import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kickvault/UserComplaintsScreen.dart';
import 'CartScreen.dart';
import 'CustomerDrawer.dart';
import 'HomeScreen.dart';
import 'SocialScreen.dart';
import 'AddPostScreen.dart';
import 'login.dart';



class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  _CustomerScreenState createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  String userName = '';
  String userEmail = '';
  String profileImage = '';
  int selectedIndex = 0;
  int openComplaintCount = 0;

  final List<Widget> screens = [
    HomeScreen(),
    CartScreen(),
    SocialScreen(),
  ];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    checkOpenComplaints();
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
          setState(() {
            userName = userDoc.get('name') ?? '';
            userEmail = userDoc.get('email') ?? '';
            profileImage = userDoc.get('profile_image') ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> checkOpenComplaints() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Initial query to get open complaints count
        final QuerySnapshot complaintsSnapshot = await FirebaseFirestore.instance
            .collection('complaints')
            .where('user_id', isEqualTo: currentUser.uid) // Make sure this matches your user ID field in Firestore
            .where('status', isEqualTo: 'Open') // Make sure complaint status field is spelled correctly
            .get();

        // Debug print for troubleshooting
        print('Found ${complaintsSnapshot.docs.length} open complaints');

        // Update count in the UI
        setState(() {
          openComplaintCount = complaintsSnapshot.docs.length;
        });

        // Set up real-time listener for changes
        FirebaseFirestore.instance
            .collection('complaints')
            .where('user_id', isEqualTo: currentUser.uid)
            .snapshots()
            .listen((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            if (doc['status'] == 'Open') {
              count++;
            }
          }

          // Only update state if count has changed
          if (count != openComplaintCount) {
            setState(() {
              openComplaintCount = count;
              print('Updated count: $openComplaintCount'); // Debug print
            });
          }
        });
      }
    } catch (e) {
      print('Error checking open complaints: $e');
    }
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void goToComplaintsScreen() {
    // Navigate to user complaints screen
    // You'll need to implement this screen or use an existing one
    // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => UserComplaintsScreen()));
  }

  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: Stack(
          children: [
            // Solid color background
            Container(
              decoration: BoxDecoration(
                color: Colors.teal, // Set a solid color
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  // Apply curve to the bottom corners
                  bottomRight: Radius.circular(20.0),
                ),
              ),
            ),
            // BackdropFilter to add glass effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0), // Ensure no color overlay
                child: AppBar(
                  title: Center(
                    child: Text(
                      'Kick Vault  ',
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  backgroundColor: Colors.teal[900], // Solid color
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    // Notification icon with badge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Iconsax.notification, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserComplaintsScreen()),
                            );
                          },
                        ),

                        if (openComplaintCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                openComplaintCount > 9 ? '9+' : '$openComplaintCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Iconsax.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.people),
          label: 'Social',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedIndex != 0) {
          setState(() {
            selectedIndex = 0; // Return to HomeScreen instead of exiting
          });
          return false; // Prevents default back action
        }

        // Show Exit Confirmation Dialog
        bool exitApp = await showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: const Text("Exit Confirmation"),
                content: const Text("Are you sure you want to exit the app?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("No"),
                  ),
                  TextButton(
                    onPressed: () {
                      // Exit the app
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("Yes"),
                  ),
                ],
              ),
        ) ?? false;

        return exitApp; // Exits app only if user confirms
      },
      child: Scaffold(
        appBar: buildAppBar(),
        drawer: CustomerDrawer(currentScreen: 'Home'),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: screens[selectedIndex],
        ),
        bottomNavigationBar: buildBottomNavigationBar(),
      ),
    );
  }
}