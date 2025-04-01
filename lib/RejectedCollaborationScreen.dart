import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kickvault/CustomerDrawer.dart';

class RejectedCollaborationScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Rejected Collaborations  ',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.teal[900], // Solid color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: CustomerDrawer(currentScreen: 'RejectedCollaborationScreen'),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, authSnapshot) {
          if (!authSnapshot.hasData || authSnapshot.data == null) {
            return Center(child: Text('Please sign in to view rejected collaborations.'));
          }
          final user = authSnapshot.data;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('rejected_collaboration_posts')
                .where('user_id', isEqualTo: user!.uid)
                .orderBy('rejected_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No rejected collaborations found.'));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final List<String> images = List<String>.from(data['images'] ?? []);
                  final List<String> comments = List<String>.from(data['comments'] ?? []);

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Info
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(data['store_logo'] ?? ''),
                          ),
                          title: Text(data['store_name'] ?? 'Unknown Store',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Seller: ${data['seller_name'] ?? 'N/A'}"),
                        ),

                        // Images Gallery
                        if (images.isNotEmpty)
                          Container(
                            height: 200,
                            margin: EdgeInsets.symmetric(horizontal: 8.0),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, imageIndex) {
                                return GestureDetector(
                                  onTap: () => _showImageGallery(context, images, imageIndex),
                                  child: Container(
                                    margin: EdgeInsets.all(8.0),
                                    width: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 5,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        images[imageIndex],
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Description & Location
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['description'] ?? 'No description available',
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(height: 8),
                              Text('Location: ${data['location'] ?? 'Unknown'}',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),

                        // Rejection Reason & Message
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Rejection Reason: ${data['rejection_reason'] ?? 'N/A'}",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text("Message: ${data['rejection_message'] ?? 'No message provided'}",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),

                        // Comments Section
                        if (comments.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Comments:", style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                for (var comment in comments)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 4.0),
                                    child: Text("- $comment"),
                                  ),
                              ],
                            ),
                          ),

                        // Date of Rejection
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            "Rejected at: ${_formatTimestamp(data['rejected_at'])}",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Function to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown date";
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute}";
  }

  // Function to show image in full screen
  void _showImageGallery(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: double.infinity,
          height: 400,
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Image.network(images[index], fit: BoxFit.cover);
            },
          ),
        ),
      ),
    );
  }
}
