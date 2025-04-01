import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ComplaintManagementScreen extends StatefulWidget {
  const ComplaintManagementScreen({Key? key}) : super(key: key);

  @override
  State<ComplaintManagementScreen> createState() => _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends State<ComplaintManagementScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;
  Map<String, dynamic>? selectedComplaint;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> fetchComplaints() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('created_at', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedComplaints = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      setState(() {
        complaints = loadedComplaints;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching complaints: $error')),
      );
    }
  }

  Future<void> updateStatus(String complaintId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('complaints').doc(complaintId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );

      fetchComplaints();

      if (selectedComplaint != null && selectedComplaint!['id'] == complaintId) {
        setState(() {
          selectedComplaint!['status'] = newStatus;
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $error')),
      );
    }
  }

  Future<void> addMessage(String complaintId, String message) async {
    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    try {
      // Create a new subcollection for messages if it doesn't exist
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .collection('messages')
          .add({
        'text': message,
        'created_at': FieldValue.serverTimestamp(),
        'admin_user': true, // Indicates this message is from admin
      });

      // Update the main complaint document
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
        'updated_at': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message added successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding message: $error')),
      );
    }
  }

  void selectComplaint(Map<String, dynamic> complaint) {
    setState(() {
      selectedComplaint = complaint;
    });
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    if (timestamp is Timestamp) {
      final DateTime dateTime = timestamp.toDate();
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    }

    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Admin Complaint Management',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
        children: [
          // Complaints List (Left panel)
          Container(
            width: 350,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blueGrey[700],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Complaints',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: fetchComplaints,
                        tooltip: 'Refresh complaints',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: complaints.isEmpty
                      ? const Center(child: Text('No complaints found'))
                      : ListView.builder(
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = complaints[index];
                      final isSelected = selectedComplaint != null &&
                          selectedComplaint!['id'] == complaint['id'];

                      return Container(
                        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                        child: ListTile(
                          title: Text(
                            complaint['user_name'] ?? 'Unknown User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order: ${complaint['order_id'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatTimestamp(complaint['created_at']),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: complaint['status'] == 'Open'
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: complaint['status'] == 'Open'
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            child: Text(
                              complaint['status'] ?? 'Unknown',
                              style: TextStyle(
                                color: complaint['status'] == 'Open'
                                    ? Colors.red
                                    : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => selectComplaint(complaint),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Complaint Details (Right panel)
          Expanded(
            child: selectedComplaint == null
                ? const Center(
              child: Text(
                'Select a complaint to view details',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
                : Column(
              children: [
                // Complaint header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blueGrey[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Complaint from ${selectedComplaint!['user_name'] ?? 'Unknown User'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Status: ',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedComplaint!['status'] == 'Open'
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selectedComplaint!['status'] == 'Open'
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                child: Text(
                                  selectedComplaint!['status'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: selectedComplaint!['status'] == 'Open'
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (selectedComplaint!['status'] == 'Open')
                                ElevatedButton.icon(
                                  onPressed: () => updateStatus(
                                    selectedComplaint!['id'],
                                    'Closed',
                                  ),
                                  icon: const Icon(Icons.check_circle,color: Colors.white,),
                                  label: const Text('Close Complaint'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: () => updateStatus(
                                    selectedComplaint!['id'],
                                    'Open',
                                  ),
                                  icon: const Icon(Icons.error,color: Colors.white,),
                                  label: const Text('Reopen Complaint'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _detailItem(
                            'Email',
                            selectedComplaint!['user_email'] ?? 'N/A',
                          ),
                          _detailItem(
                            'User ID',
                            selectedComplaint!['user_id'] ?? 'N/A',
                          ),
                          _detailItem(
                            'Order ID',
                            selectedComplaint!['order_id'] ?? 'N/A',
                          ),
                          _detailItem(
                            'Created',
                            formatTimestamp(selectedComplaint!['created_at']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Complaint content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complaint Text:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            selectedComplaint!['complaint_text'] ?? 'No complaint text provided',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (selectedComplaint!['ai_summary'] != null) ...[
                          const Text(
                            'AI Summary:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              selectedComplaint!['ai_summary'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Messages section (would usually be a stream from Firestore)
                        const Text(
                          'Messages:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Messages would be loaded from Firestore
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('complaints')
                              .doc(selectedComplaint!['id'])
                              .collection('messages')
                              .orderBy('created_at', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error loading messages: ${snapshot.error}'),
                              );
                            }

                            final messages = snapshot.data?.docs ?? [];

                            if (messages.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index].data() as Map<String, dynamic>;
                                final isAdmin = message['admin_user'] == true;

                                return Align(
                                  alignment: isAdmin
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                                    ),
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isAdmin
                                          ? Colors.blue[100]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isAdmin
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['text'] ?? '',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${isAdmin ? "Admin" : "Customer"} • ${formatTimestamp(message['created_at'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Message input area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () => addMessage(
                          selectedComplaint!['id'],
                          _messageController.text,
                        ),
                        icon: const Icon(Icons.send),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}