import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPostManagementScreen extends StatefulWidget {
  const AdminPostManagementScreen({Key? key}) : super(key: key);

  @override
  _AdminPostManagementScreenState createState() => _AdminPostManagementScreenState();
}

class _AdminPostManagementScreenState extends State<AdminPostManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedPostType = 'posts';
  bool _isGridView = false;

  // Color palette
  final Color _primaryColor = Color(0xFF4A6CF7);
  final Color _secondaryColor = Color(0xFF6B7280);
  final Color _backgroundLight = Color(0xFFF3F4F6);
  final Color _textColor = Color(0xFF111827);

  Future<void> _deletePost(DocumentSnapshot post, String collection) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Deletion',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this post?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: _secondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('deleted_posts').doc(post.id).set({
                  ...post.data() as Map<String, dynamic>,
                  'original_collection': collection,
                  'deleted_at': FieldValue.serverTimestamp(),
                });

                await _firestore.collection(collection).doc(post.id).delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Post deleted successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting post: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewPostDetails(DocumentSnapshot post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Post Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _primaryColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post['images'] != null && (post['images'] as List).isNotEmpty)
                Center(
                  child: Container(
                    height: 250,
                    width: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(post['images'][0]),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _buildDetailRow('Description', post['description'] ?? 'No Description'),
              _buildDetailRow('Posted by', post['user_name'] ?? 'Unknown'),
              _buildDetailRow('Created At', _formatTimestamp(post['created_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
              style: GoogleFonts.inter(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: _secondaryColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
  }

  Widget _buildPostList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(_selectedPostType).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No posts found',
              style: GoogleFonts.inter(
                color: _secondaryColor,
                fontSize: 18,
              ),
            ),
          );
        }

        return _isGridView
            ? _buildGridView(posts)
            : _buildListView(posts);
      },
    );
  }

  Widget _buildGridView(List<DocumentSnapshot> posts) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        var post = posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildListView(List<DocumentSnapshot> posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        var post = posts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (post['images'] != null && (post['images'] as List).isNotEmpty)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(post['images'][0]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['description'] ?? 'No Description',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By: ${post['user_name'] ?? 'Unknown'}',
                          style: GoogleFonts.inter(
                            color: _secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.visibility, color: _primaryColor),
                        onPressed: () => _viewPostDetails(post),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePost(post, _selectedPostType),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostCard(DocumentSnapshot post) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post['images'] != null && (post['images'] as List).isNotEmpty)
              Center(
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(post['images'][0]),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              post['description'] ?? 'No Description',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'By: ${post['user_name'] ?? 'Unknown'}',
              style: GoogleFonts.inter(
                color: _secondaryColor,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewPostDetails(post),
                    icon: Icon(Icons.visibility, color: Colors.white, size: 18),
                    label: Text('View', style: GoogleFonts.inter(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deletePost(post, _selectedPostType),
                    icon: Icon(Icons.delete, color: Colors.white, size: 18),
                    label: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Post Management',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // View Toggle
          IconButton(
            icon: Icon(_isGridView ? Icons.grid_view : Icons.list, color: Colors.white),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),

          // Post Type Dropdown
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedPostType,
              dropdownColor: Colors.black,
              style: GoogleFonts.inter(color: Colors.white),
              items: [
                DropdownMenuItem(
                  value: 'posts',
                  child: Text('Regular Posts', style: GoogleFonts.inter(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'collaboration posts',
                  child: Text('Collaboration Posts', style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPostType = newValue;
                  });
                }
              },
              icon: Icon(Icons.filter_list, color: Colors.white),
              underline: Container(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildPostList(),
      ),
    );
  }
}