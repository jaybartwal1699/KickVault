// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'PostCommentsScreen.dart';
// // import 'package:intl/intl.dart'; // Add this import for date formatting
// //
// // class SocialScreen extends StatefulWidget {
// //   const SocialScreen({super.key});
// //
// //   @override
// //   _SocialScreenState createState() => _SocialScreenState();
// // }
// //
// // class _SocialScreenState extends State<SocialScreen> {
// //   // Function to format timestamp
// //   String _formatTimestamp(Timestamp timestamp) {
// //     DateTime dateTime = timestamp.toDate();
// //     DateTime now = DateTime.now();
// //     Duration difference = now.difference(dateTime);
// //
// //     if (difference.inDays > 7) {
// //       // If more than 7 days, show the full date
// //       return DateFormat('MMM d, yyyy').format(dateTime);
// //     } else if (difference.inDays > 0) {
// //       // If more than 1 day but less than 7 days
// //       return '${difference.inDays}d ago';
// //     } else if (difference.inHours > 0) {
// //       // If more than 1 hour but less than 24 hours
// //       return '${difference.inHours}h ago';
// //     } else if (difference.inMinutes > 0) {
// //       // If more than 1 minute but less than 60 minutes
// //       return '${difference.inMinutes}m ago';
// //     } else {
// //       // If less than 1 minute
// //       return 'Just now';
// //     }
// //   }
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: const Text(
// //             "Hello There! Share your shoe collection here... 😊",
// //             style: TextStyle(fontSize: 16),
// //           ),
// //           duration: const Duration(seconds: 2),
// //           backgroundColor: Colors.teal,
// //           behavior: SnackBarBehavior.floating,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(10),
// //           ),
// //         ),
// //       );
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: Colors.teal[900],
// //         elevation: 0,
// //         title: Align(
// //           alignment: Alignment.bottomLeft,
// //           child: Text(
// //             "Social Feed",
// //             style: GoogleFonts.nunitoSans(
// //               fontWeight: FontWeight.w900,
// //               fontSize: 22,
// //               color: Colors.white,
// //             ),
// //           ),
// //         ),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.search, color: Colors.white),
// //             onPressed: () {
// //               // Search Action
// //             },
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.notifications, color: Colors.white),
// //             onPressed: () {
// //               // Notifications Action
// //             },
// //           ),
// //         ],
// //       ),
// //
// //       body: StreamBuilder<QuerySnapshot>(
// //         stream: FirebaseFirestore.instance
// //             .collection('posts')
// //             .orderBy('created_at', descending: true)
// //             .snapshots(),
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Center(child: CircularProgressIndicator());
// //           }
// //
// //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //             return const Center(child: Text("No posts available."));
// //           }
// //
// //           final posts = snapshot.data!.docs;
// //
// //           return ListView.builder(
// //             itemCount: posts.length,
// //             itemBuilder: (context, index) {
// //               final post = posts[index].data() as Map<String, dynamic>;
// //               final postId = posts[index].id;
// //
// //               final commentsMap = post['comments'] as Map<String, dynamic>? ?? {};
// //               final commentsList = commentsMap.entries.map((entry) {
// //                 final commentData = entry.value as Map<String, dynamic>;
// //                 return {
// //                   ...commentData,
// //                   'id': entry.key,
// //                 };
// //               }).toList();
// //
// //               commentsList.sort((a, b) {
// //                 final aTime = (a['created_at'] as Timestamp).toDate();
// //                 final bTime = (b['created_at'] as Timestamp).toDate();
// //                 return bTime.compareTo(aTime);
// //               });
// //
// //               return _buildPost(
// //                 context: context,
// //                 postId: postId,
// //                 username: post['user_name'] ?? 'Unknown User',
// //                 profileImageUrl: post['profile_image'] ?? '',
// //                 imageUrl: post['images'] != null && (post['images'] as List).isNotEmpty
// //                     ? post['images'][0]
// //                     : '',
// //                 description: post['description'] ?? '',
// //                 location: post['location'] != null && post['location'].isNotEmpty
// //                     ? 'Location: ${post['location']}'
// //                     : '', // Only show location if it exists
// //                 likes: List<String>.from(post['likes'] ?? []),
// //                 comments: commentsList,
// //                 createdAt: post['created_at'] as Timestamp,
// //               );
// //
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   Widget _buildPost({
// //     required BuildContext context,
// //     required String postId,
// //     required String username,
// //     required String profileImageUrl,
// //     required String imageUrl,
// //     required String description,
// //     required String location,
// //     required List<String> likes,
// //     required List<Map<String, dynamic>> comments,
// //     required Timestamp createdAt,
// //   }) {
// //     final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
// //     final hasLiked = likes.contains(currentUserId);
// //
// //     return Card(
// //       elevation: 5,
// //       margin: const EdgeInsets.all(10),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Row(
// //               children: [
// //                 CircleAvatar(
// //                   backgroundImage: NetworkImage(profileImageUrl),
// //                   radius: 20,
// //                   onBackgroundImageError: (_, __) => const Icon(
// //                     Icons.account_circle,
// //                     size: 40,
// //                   ),
// //                 ),
// //                 const SizedBox(width: 10),
// //                 Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       username,
// //                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
// //                     ),
// //                     if (location.isNotEmpty)
// //                       Container(
// //                         padding: const EdgeInsets.only(top: 4.0), // Add padding for spacing if necessary
// //                         child: Text(
// //                           location,
// //                           style: const TextStyle(fontSize: 11, color: Colors.black),
// //                         ),
// //                       )
// //
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //           if (imageUrl.isNotEmpty)
// //             Image.network(
// //               imageUrl,
// //               fit: BoxFit.cover,
// //               width: double.infinity,
// //               height: 300,
// //               errorBuilder: (context, error, stackTrace) => const Center(
// //                 child: Icon(Icons.error, color: Colors.red, size: 48),
// //               ),
// //             ),
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Text(
// //               description,
// //               style: const TextStyle(fontSize: 16),
// //             ),
// //           ),
// //           Padding(
// //             padding: const EdgeInsets.only(left: 8.0, right: 8.0),
// //             child: Text(
// //               _formatTimestamp(createdAt),
// //               style: const TextStyle(
// //                 fontSize: 12,
// //                 color: Colors.grey,
// //               ),
// //             ),
// //           ),
// //           const Divider(),
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceAround,
// //               children: [
// //                 Row(
// //                   children: [
// //                     IconButton(
// //                       onPressed: () => _toggleLike(postId, currentUserId, hasLiked),
// //                       icon: Icon(
// //                         hasLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
// //                         color: hasLiked ? Colors.teal : null,
// //                       ),
// //                     ),
// //                     Text('${likes.length}'),
// //                   ],
// //                 ),
// //                 Row(
// //                   children: [
// //                     IconButton(
// //                       onPressed: () {
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (context) => PostCommentsScreen(postId: postId),
// //                           ),
// //                         );
// //                       },
// //                       icon: const Icon(Icons.comment_outlined),
// //                     ),
// //                     Text('${comments.length}'),
// //                   ],
// //                 ),
// //                 IconButton(
// //                   onPressed: () {
// //                     // Share action
// //                   },
// //                   icon: const Icon(Icons.share),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           if (comments.isNotEmpty)
// //             Padding(
// //               padding: const EdgeInsets.all(8.0),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   ...comments.take(2).map((comment) => Padding(
// //                     padding: const EdgeInsets.only(bottom: 6.0),
// //                     child: Text(
// //                       '${comment['user_name']}: ${comment['comment']}',
// //                       style: const TextStyle(fontSize: 14),
// //                     ),
// //                   )),
// //                   if (comments.length > 2)
// //                     TextButton(
// //                       onPressed: () {
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (context) => PostCommentsScreen(postId: postId),
// //                           ),
// //                         );
// //                       },
// //                       child: Text('View all ${comments.length} comments'),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //
// //   Future<void> _toggleLike(String postId, String currentUserId, bool hasLiked) async {
// //     try {
// //       final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
// //
// //       if (hasLiked) {
// //         await postRef.update({
// //           'likes': FieldValue.arrayRemove([currentUserId]),
// //         });
// //       } else {
// //         await postRef.update({
// //           'likes': FieldValue.arrayUnion([currentUserId]),
// //         });
// //       }
// //     } catch (e) {
// //       print("Error toggling like: $e");
// //     }
// //   }
// // }
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'PostCommentsScreen.dart';
// import 'package:intl/intl.dart';
// import 'package:rxdart/rxdart.dart'; // For combining Firestore streams
//
// class SocialScreen extends StatefulWidget {
//   const SocialScreen({super.key});
//
//   @override
//   _SocialScreenState createState() => _SocialScreenState();
// }
//
// class _SocialScreenState extends State<SocialScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text(
//             "Hello There! Share your shoe collection here... 😊",
//             style: TextStyle(fontSize: 16),
//           ),
//           duration: const Duration(seconds: 2),
//           backgroundColor: Colors.teal,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//     });
//   }
//
//   // Function to format timestamp
//   String _formatTimestamp(Timestamp timestamp) {
//     DateTime dateTime = timestamp.toDate();
//     DateTime now = DateTime.now();
//     Duration difference = now.difference(dateTime);
//
//     if (difference.inDays > 7) {
//       return DateFormat('MMM d, yyyy').format(dateTime);
//     } else if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.teal[800],
//         elevation: 0,
//         title: Align(
//           alignment: Alignment.bottomLeft,
//           child: Text(
//             "Social Feed",
//             style: GoogleFonts.nunitoSans(
//               fontWeight: FontWeight.w900,
//               fontSize: 22,
//               color: Colors.white,
//             ),
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search, color: Colors.white),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white),
//             onPressed: () {},
//           ),
//         ],
//       ),
//
//       body: StreamBuilder<List<QueryDocumentSnapshot>>(
//         stream: _fetchCombinedPosts(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("No posts available."));
//           }
//
//           final posts = snapshot.data!;
//
//           return ListView.builder(
//             itemCount: posts.length,
//             itemBuilder: (context, index) {
//               final post = posts[index].data() as Map<String, dynamic>;
//               final postId = posts[index].id;
//               final collectionPath = posts[index].reference.parent.id;
//               final isCollaborationPost = collectionPath == 'collaboration posts' ||
//                   post['is_collaboration'] == true;
//
//               return _buildPost(
//                 context: context,
//                 postId: postId,
//                 username: post['user_name'] ?? 'Unknown User',
//                 profileImageUrl: post['user_profile_image'] ?? '',
//                 imageUrl: post['images'] != null && (post['images'] as List).isNotEmpty
//                     ? post['images'][0]
//                     : '',
//                 images: post['images'] ?? [],
//                 description: post['description'] ?? '',
//                 location: post['location'] ?? '',
//                 likes: List<String>.from(post['likes'] ?? []),
//                 comments: post['comments'] != null
//                     ? (post['comments'] is Map
//                     ? (post['comments'] as Map<String, dynamic>).values.toList()
//                     : post['comments'] as List)
//                     : [],
//                 createdAt: post['created_at'] as Timestamp,
//                 isCollaborationPost: isCollaborationPost,
//                 storeName: post['store_name'] ?? '',
//                 sellerId: post['seller_id'] ?? '',
//                 storeLogo: post['store_logo'] ?? '',
//                 verificationStatus: post['verification_status'] ?? '',
//                 collectionPath: collectionPath,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   // Fetch data from both collections
//   Stream<List<QueryDocumentSnapshot>> _fetchCombinedPosts() {
//     final postsStream = FirebaseFirestore.instance
//         .collection('posts')
//         .orderBy('created_at', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs);
//
//     final collaborationPostsStream = FirebaseFirestore.instance
//         .collection('collaboration posts')
//         .where('verification_status', isEqualTo: 'verified')
//         .orderBy('created_at', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs);
//
//     return Rx.combineLatest2(postsStream, collaborationPostsStream, (posts, collabPosts) {
//       final allPosts = [...posts, ...collabPosts];
//       allPosts.sort((a, b) {
//         final aTime = (a['created_at'] as Timestamp).toDate();
//         final bTime = (b['created_at'] as Timestamp).toDate();
//         return bTime.compareTo(aTime);
//       });
//       return allPosts;
//     });
//   }
//
//   // Build post UI
//   Widget _buildPost({
//     required BuildContext context,
//     required String postId,
//
//     required String username,
//     required String profileImageUrl,
//     required String imageUrl,
//     required String description,
//     required String location,
//     required List<String> likes,
//     required List<dynamic> images,
//     required List<dynamic> comments,
//     required Timestamp createdAt,
//     required bool isCollaborationPost,
//     required String storeName,
//     required String sellerId,
//     required String storeLogo,
//     required String verificationStatus,
//     required String collectionPath,
//   }) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
//     final hasLiked = likes.contains(currentUserId);
//
//     return Card(
//       elevation: 5,
//       margin: const EdgeInsets.all(10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   backgroundImage: profileImageUrl.isNotEmpty
//                       ? NetworkImage(profileImageUrl)
//                       : null,
//                   radius: 20,
//                   child: profileImageUrl.isEmpty ? const Icon(Icons.account_circle, size: 40) : null,
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             username,
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           if (isCollaborationPost && verificationStatus == 'verified')
//                             const Icon(Icons.verified, size: 16, color: Colors.blue),
//                         ],
//                       ),
//                       if (isCollaborationPost && storeName.isNotEmpty)
//                         Row(
//                           children: [
//                             if (storeLogo.isNotEmpty)
//                               Container(
//                                 width: 16,
//                                 height: 16,
//                                 margin: const EdgeInsets.only(right: 4),
//                                 child: Image.network(
//                                   storeLogo,
//                                   errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 16),
//                                 ),
//                               ),
//                             Text(
//                               storeName,
//                               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.teal),
//                             ),
//                           ],
//                         ),
//                       if (location.isNotEmpty)
//                         Container(
//                           padding: const EdgeInsets.only(top: 4.0),
//                           child: Text(
//                             location,
//                             style: const TextStyle(fontSize: 11, color: Colors.grey),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (images.isNotEmpty)
//             SizedBox(
//               height: 300,
//               child: Stack(
//                 children: [
//                   ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: images.length,
//                     itemBuilder: (context, imageIndex) {
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                         child: Image.network(
//                           images[imageIndex],
//                           fit: BoxFit.contain,
//                           width: MediaQuery.of(context).size.width - 40,
//                           height: 300,
//                           errorBuilder: (context, error, stackTrace) => const Center(
//                             child: Icon(Icons.error, color: Colors.red, size: 48),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                   if (images.length > 1)
//                     Positioned(
//                       top: 10,
//                       left: 10,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.black54,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '${images.length} images',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               description,
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Text(
//               _formatTimestamp(createdAt),
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ),
//           const Divider(),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 Row(
//                   children: [
//                     IconButton(
//                       onPressed: () => _toggleLike(postId, currentUserId, hasLiked, collectionPath),
//                       icon: Icon(
//                         hasLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
//                         color: hasLiked ? Colors.teal : null,
//                       ),
//                     ),
//                     Text('${likes.length}'),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     IconButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => PostCommentsScreen(
//                               postId: postId,
//                               isCollaborationPost: isCollaborationPost,
//                             ),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.comment_outlined),
//                     ),
//                     Text('${comments.length}'),
//                   ],
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     // Share action
//                   },
//                   icon: const Icon(Icons.share),
//                 ),
//               ],
//             ),
//           ),
//           if (comments.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ...comments.take(2).map((comment) {
//                     final commentText = comment is Map ?
//                     '${comment['user_name'] ?? 'Unknown'}: ${comment['comment'] ?? ''}' :
//                     comment.toString();
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 6.0),
//                       child: Text(
//                         commentText,
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     );
//                   }),
//                   if (comments.length > 2)
//                     TextButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => PostCommentsScreen(
//                               postId: postId,
//                               isCollaborationPost: isCollaborationPost,
//                             ),
//                           ),
//                         );
//                       },
//                       child: Text('View all ${comments.length} comments'),
//                     ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // Toggle like functionality
//   Future<void> _toggleLike(String postId, String currentUserId, bool hasLiked, String collectionPath) async {
//     try {
//       // Determine which collection to update based on the post type
//       final String collection = collectionPath == 'collaboration posts' ? 'collaboration posts' : 'posts';
//       final postRef = FirebaseFirestore.instance.collection(collection).doc(postId);
//
//       if (hasLiked) {
//         await postRef.update({
//           'likes': FieldValue.arrayRemove([currentUserId]),
//         });
//       } else {
//         await postRef.update({
//           'likes': FieldValue.arrayUnion([currentUserId]),
//         });
//       }
//     } catch (e) {
//       print("Error toggling like: $e");
//     }
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'PostCommentsScreen.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart'; // For combining Firestore streams

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  _SocialScreenState createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Hello There! Share your shoe collection here... 😊",
            style: TextStyle(fontSize: 16),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  // Function to format timestamp
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        elevation: 0,
        title: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            "Social Feed",
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _fetchCombinedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No posts available."));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id;
              final collectionPath = posts[index].reference.parent.id;
              final isCollaborationPost = collectionPath == 'collaboration posts' ||
                  post['is_collaboration'] == true;

              // Get the post owner's user ID
              final postUserId = post['user_id'] ?? '';

              return _buildPost(
                context: context,
                postId: postId,
                userId: postUserId,
                username: post['user_name'] ?? 'Unknown User',
                profileImageUrl: post['user_profile_image'] ?? '',
                imageUrl: post['images'] != null && (post['images'] as List).isNotEmpty
                    ? post['images'][0]
                    : '',
                images: post['images'] ?? [],
                description: post['description'] ?? '',
                location: post['location'] ?? '',
                likes: List<String>.from(post['likes'] ?? []),
                comments: post['comments'] != null
                    ? (post['comments'] is Map
                    ? (post['comments'] as Map<String, dynamic>).values.toList()
                    : post['comments'] as List)
                    : [],
                createdAt: post['created_at'] as Timestamp,
                isCollaborationPost: isCollaborationPost,
                storeName: post['store_name'] ?? '',
                sellerId: post['seller_id'] ?? '',
                storeLogo: post['store_logo'] ?? '',
                verificationStatus: post['verification_status'] ?? '',
                collectionPath: collectionPath,
              );
            },
          );
        },
      ),
    );
  }

  // Fetch data from both collections
  Stream<List<QueryDocumentSnapshot>> _fetchCombinedPosts() {
    final postsStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    final collaborationPostsStream = FirebaseFirestore.instance
        .collection('collaboration posts')
        .where('verification_status', isEqualTo: 'verified')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    return Rx.combineLatest2(postsStream, collaborationPostsStream, (posts, collabPosts) {
      final allPosts = [...posts, ...collabPosts];
      allPosts.sort((a, b) {
        final aTime = (a['created_at'] as Timestamp).toDate();
        final bTime = (b['created_at'] as Timestamp).toDate();
        return bTime.compareTo(aTime);
      });
      return allPosts;
    });
  }

  // Build post UI
  Widget _buildPost({
    required BuildContext context,
    required String postId,
    required String userId,
    required String username,
    required String profileImageUrl,
    required String imageUrl,
    required String description,
    required String location,
    required List<String> likes,
    required List<dynamic> images,
    required List<dynamic> comments,
    required Timestamp createdAt,
    required bool isCollaborationPost,
    required String storeName,
    required String sellerId,
    required String storeLogo,
    required String verificationStatus,
    required String collectionPath,
  }) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hasLiked = likes.contains(currentUserId);
    final isCurrentUserPost = userId == currentUserId;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  radius: 20,
                  child: profileImageUrl.isEmpty ? const Icon(Icons.account_circle, size: 40) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (isCollaborationPost && verificationStatus == 'verified')
                            const Icon(Icons.verified, size: 16, color: Colors.blue),
                        ],
                      ),
                      if (isCollaborationPost && storeName.isNotEmpty)
                        Row(
                          children: [
                            if (storeLogo.isNotEmpty)
                              Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.only(right: 4),
                                child: Image.network(
                                  storeLogo,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 16),
                                ),
                              ),
                            Text(
                              storeName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.teal),
                            ),
                          ],
                        ),
                      if (location.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            location,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                // Add delete option for current user's posts
                if (isCurrentUserPost)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context, postId, collectionPath),
                  ),
              ],
            ),
          ),
          if (images.isNotEmpty)
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, imageIndex) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Image.network(
                          images[imageIndex],
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width - 40,
                          height: 300,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.error, color: Colors.red, size: 48),
                          ),
                        ),
                      );
                    },
                  ),
                  if (images.length > 1)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${images.length} images',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _formatTimestamp(createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _toggleLike(postId, currentUserId, hasLiked, collectionPath),
                      icon: Icon(
                        hasLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                        color: hasLiked ? Colors.teal : null,
                      ),
                    ),
                    Text('${likes.length}'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostCommentsScreen(
                              postId: postId,
                              isCollaborationPost: isCollaborationPost,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.comment_outlined),
                    ),
                    Text('${comments.length}'),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    // Share action
                  },
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
          ),
          if (comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...comments.take(2).map((comment) {
                    final commentText = comment is Map ?
                    '${comment['user_name'] ?? 'Unknown'}: ${comment['comment'] ?? ''}' :
                    comment.toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        commentText,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }),
                  if (comments.length > 2)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostCommentsScreen(
                              postId: postId,
                              isCollaborationPost: isCollaborationPost,
                            ),
                          ),
                        );
                      },
                      child: Text('View all ${comments.length} comments'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String postId, String collectionPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePost(postId, collectionPath);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Delete post from Firestore
  Future<void> _deletePost(String postId, String collectionPath) async {
    try {
      // Determine which collection to delete from based on the post type
      final String collection = collectionPath == 'collaboration posts' ? 'collaboration posts' : 'posts';

      await FirebaseFirestore.instance.collection(collection).doc(postId).delete();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      print("Error deleting post: $e");
    }
  }

  // Toggle like functionality
  Future<void> _toggleLike(String postId, String currentUserId, bool hasLiked, String collectionPath) async {
    try {
      // Determine which collection to update based on the post type
      final String collection = collectionPath == 'collaboration posts' ? 'collaboration posts' : 'posts';
      final postRef = FirebaseFirestore.instance.collection(collection).doc(postId);

      if (hasLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
        });
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }
}