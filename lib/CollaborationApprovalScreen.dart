import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'Seller_Drawer.dart';

class CollaborationApprovalScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _rejectCollaboration(BuildContext context, DocumentSnapshot doc) {
    TextEditingController messageController = TextEditingController();
    String selectedReason = "Not Interested";
    List<String> reasons = ["Image not good", "Change description or location", "Not Interested"];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Reject Collaboration",
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Reject Collaboration"),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatefulBuilder(
                  builder: (context, setState) {
                    return DropdownButtonFormField<String>(
                      value: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value!;
                        });
                      },
                      items: reasons.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: "Enter additional details",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(color: Colors.black)),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

                          docData['rejection_reason'] = selectedReason;
                          docData['rejection_message'] = messageController.text.trim();
                          docData['rejected_at'] = FieldValue.serverTimestamp();
                          docData['verification_status'] = 'rejected';

                          await FirebaseFirestore.instance
                              .collection('rejected_collaboration_posts')
                              .doc(doc.id)
                              .set(docData);

                          await FirebaseFirestore.instance
                              .collection('collaboration posts')
                              .doc(doc.id)
                              .delete();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Collaboration rejected successfully')),
                          );

                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: Failed to reject collaboration')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text("Reject", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  void _showImageGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Stack(
            children: [
              PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(images[index]),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                itemCount: images.length,
                loadingBuilder: (context, event) => Center(
                  child: CircularProgressIndicator(),
                ),
                backgroundDecoration: BoxDecoration(
                  color: Colors.black,
                ),
                pageController: PageController(initialPage: initialIndex),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Set AppBar color to black
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
        title: Text(
          'Collaboration Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Set text color to white
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('collaboration posts')
            .where('is_collaboration', isEqualTo: true)
            .where('seller_id', isEqualTo: currentUserId)
            .where('verification_status', isEqualTo: 'unverified')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No pending collaboration requests'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final List<String> images = List<String>.from(data['images'] ?? []);

              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(data['user_profile_image']),
                      ),
                      title: Text(data['user_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['user_email'], style: TextStyle(color: Colors.grey)),
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
                    // Description and Location
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['description'], style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Location: ${data['location']}', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    // Approve/Reject Buttons
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _rejectCollaboration(context, doc),
                            child: Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await _firestore.collection('collaboration posts').doc(doc.id).update({
                                'verification_status': 'verified',
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Collaboration approved')),
                              );
                            },
                            child: Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
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
        },
      ),
    );
  }
}
