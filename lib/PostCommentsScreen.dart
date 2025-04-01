import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostCommentsScreen extends StatefulWidget {
  final String postId;
  final bool isCollaborationPost;

  const PostCommentsScreen({
    Key? key,
    required this.postId,
    this.isCollaborationPost = false,
  }) : super(key: key);

  @override
  _PostCommentsScreenState createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Determine which collection to query based on post type
    final String collectionPath = widget.isCollaborationPost ? 'collaboration posts' : 'posts';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Comments'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection(collectionPath).doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.exists == false) {
            return const Center(child: Text("Post not found."));
          }

          final post = snapshot.data!;
          final commentsData = post.data() is Map ? (post.data() as Map)['comments'] : null;

          // Handle different data types for comments (List or Map)
          List<Map<String, dynamic>> comments = [];

          if (commentsData is List) {
            comments = commentsData.map((comment) => comment as Map<String, dynamic>).toList();
          } else if (commentsData is Map) {
            comments = commentsData.entries.map((entry) {
              final comment = entry.value as Map<String, dynamic>;
              return {...comment, 'comment_id': entry.key};
            }).toList();
          }

          // Safe timestamp sorting with null check
          comments.sort((a, b) {
            final aTimestamp = a['created_at'] as Timestamp?;
            final bTimestamp = b['created_at'] as Timestamp?;

            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;

            return bTimestamp.compareTo(aTimestamp);
          });

          return Column(
            children: [
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text("No comments yet."))
                    : ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (comment['user_name'] as String?)?.isNotEmpty == true
                              ? (comment['user_name'] as String).substring(0, 1).toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(comment['user_name'] ?? 'Unknown User'),
                      subtitle: Text(comment['comment'] ?? ''),
                      trailing: Text(
                        _formatTimestamp(comment['created_at'] as Timestamp?),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        final commentText = _commentController.text.trim();
                        if (commentText.isNotEmpty) {
                          _addComment(widget.postId, commentText);
                          _commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final commentTime = timestamp.toDate();
    final difference = now.difference(commentTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${commentTime.day}/${commentTime.month}/${commentTime.year}';
    }
  }

  Future<void> _addComment(String postId, String commentText) async {
    if (currentUser == null) return;

    try {
      // First, get the current user's data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      final userName = userDoc.exists
          ? userDoc.get('name') ?? currentUser!.displayName ?? 'Unknown User'
          : currentUser!.displayName ?? 'Unknown User';

      // Determine which collection to update based on post type
      final String collectionPath = widget.isCollaborationPost ? 'collaboration posts' : 'posts';
      final postRef = FirebaseFirestore.instance.collection(collectionPath).doc(postId);

      // Create the comment data
      final commentData = {
        'user_id': currentUser!.uid,
        'user_name': userName,
        'comment': commentText,
        'created_at': FieldValue.serverTimestamp(),
      };

      // Generate a unique comment ID
      final commentId = FirebaseFirestore.instance.collection(collectionPath).doc().id;

      // Update the post's comments map with the new comment
      await postRef.update({
        'comments.$commentId': commentData,
      });
    } catch (e) {
      print("Error adding comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding comment. Please try again.')),
      );
    }
  }
}