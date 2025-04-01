// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import 'Admin_Drawer.dart';
//
// class ManageCategories extends StatefulWidget {
//   const ManageCategories({Key? key}) : super(key: key);
//
//   @override
//   _ManageCategoriesState createState() => _ManageCategoriesState();
// }
//
// class _ManageCategoriesState extends State<ManageCategories> {
//   final CollectionReference _categoriesCollection =
//   FirebaseFirestore.instance.collection('Categories');
//
//   Future<void> _deleteCategory(String id) async {
//     try {
//       await _categoriesCollection.doc(id).delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Category deleted successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error deleting category: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Center(
//           child: Text(
//             'Manage Categories   ',
//             style: GoogleFonts.nunitoSans(
//               fontWeight: FontWeight.w900,
//               fontSize: 24,
//               color: Colors.white,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ),
//         backgroundColor: Colors.black.withOpacity(0.9),
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//
//       drawer: const Admin_Drawer(
//         currentScreen: 'Manage Category', // Indicating the current screen
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _categoriesCollection.orderBy('created_at', descending: true).snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(
//               child: Text('Error: ${snapshot.error}'),
//             );
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text('No categories available'),
//             );
//           }
//
//           final categories = snapshot.data!.docs;
//
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: categories.map<Widget>((category) {
//                 final id = category.id;
//                 final name = category['name'] ?? 'Unnamed';
//                 final description = category['description'] ?? '';
//                 final createdAt = (category['created_at'] as Timestamp).toDate();
//
//                 return Card(
//                   elevation: 6,
//                   margin: const EdgeInsets.symmetric(vertical: 10.0),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
//                       leading: CircleAvatar(
//                         backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
//                         child: const Icon(Icons.category, color: Colors.black),
//                       ),
//                       title: Text(
//                         name,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 6.0),
//                           Text(
//                             description,
//                             style: const TextStyle(
//                               color: Colors.black87,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 8.0),
//                           Text(
//                             'Created at: ${createdAt.toLocal().toString().split('.')[0]}',
//                             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                           ),
//                         ],
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.red),
//                         onPressed: () => _deleteCategory(id),
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Admin_Drawer.dart';
import 'admin_screen.dart';

class ManageCategories extends StatefulWidget {
  const ManageCategories({Key? key}) : super(key: key);

  @override
  _ManageCategoriesState createState() => _ManageCategoriesState();
}

class _ManageCategoriesState extends State<ManageCategories> {
  final CollectionReference _categoriesCollection =
  FirebaseFirestore.instance.collection('Categories');

  Future<void> _deleteCategory(String id) async {
    try {
      await _categoriesCollection.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Center(
          child: Text(
            'Manage Categories',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Show Drawer on Mobile, no drawer on Web
      drawer: kIsWeb ? null : const Admin_Drawer(currentScreen: 'Manage Category'),

      // For web, use Row layout with sidebar
      body: kIsWeb
          ? _buildWebLayout(context) // Web layout
          : _buildMobileLayout(context), // Mobile layout
    );
  }

  // Web layout with sidebar
  Widget _buildWebLayout(BuildContext context) {
    return Row(
      children: [
        // Web Sidebar with current screen highlighted
        const WebAdminSidebar(currentScreen: 'Manage Category'),

        // Main content area
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  // Mobile layout (just the main content)
  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: Colors.white, // Adjust background color as needed
      child: _buildMainContent(),
    );
  }

  // Main content area extracted to avoid duplication
  Widget _buildMainContent() {

    return StreamBuilder<QuerySnapshot>(
      stream: _categoriesCollection.orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No categories available'),
          );
        }

        final categories = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: categories.map<Widget>((category) {
              final id = category.id;
              final name = category['name'] ?? 'Unnamed';
              final description = category['description'] ?? '';
              final createdAt = (category['created_at'] as Timestamp).toDate();

              return Card(
                color: Colors.white,
                elevation: 6,
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.category, color: Colors.black),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6.0),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Created at: ${createdAt.toLocal().toString().split('.')[0]}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCategory(id),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
