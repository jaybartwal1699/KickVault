import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserComplaintsScreen extends StatefulWidget {
  const UserComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<UserComplaintsScreen> createState() => _UserComplaintsScreenState();
}

class _UserComplaintsScreenState extends State<UserComplaintsScreen> {
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? selectedOrderId;
  bool isSubmittingComplaint = false;
  bool isLoadingOrders = true;
  bool isSubmittingMessage = false;
  List<Map<String, dynamic>> orders = [];
  Map<String, dynamic>? selectedComplaint;

  @override
  void initState() {
    super.initState();
    fetchUserOrders();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> fetchUserOrders() async {
    setState(() {
      isLoadingOrders = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: currentUser.uid)
            .orderBy('created_at', descending: true)
            .get();

        setState(() {
          orders = ordersSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          isLoadingOrders = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingOrders = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching orders: $e')),
      );
    }
  }

  Future<void> submitComplaint() async {
    if (_complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your complaint')),
      );
      return;
    }

    if (selectedOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an order')),
      );
      return;
    }

    setState(() {
      isSubmittingComplaint = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get user info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final userData = userDoc.data() as Map<String, dynamic>;

        // Create complaint
        final docRef = await FirebaseFirestore.instance.collection('complaints').add({
          'user_id': currentUser.uid,
          'user_name': userData['name'] ?? 'Unknown User',
          'user_email': userData['email'] ?? '',
          'order_id': selectedOrderId,
          'complaint_text': _complaintController.text,
          'status': 'Open',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Clear form
        _complaintController.clear();
        setState(() {
          selectedOrderId = null;
          isSubmittingComplaint = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully')),
        );
      }
    } catch (e) {
      setState(() {
        isSubmittingComplaint = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting complaint: $e')),
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

    setState(() {
      isSubmittingMessage = true;
    });

    try {
      // Add message to complaint
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .collection('messages')
          .add({
        'text': message,
        'created_at': FieldValue.serverTimestamp(),
        'admin_user': false, // Indicates this message is from customer
      });

      // Update the complaint timestamp
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
        'updated_at': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      setState(() {
        isSubmittingMessage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );
    } catch (e) {
      setState(() {
        isSubmittingMessage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  void viewComplaint(Map<String, dynamic> complaint) {
    setState(() {
      selectedComplaint = complaint;
    });

    // Navigate to complaint detail screen on mobile
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintDetailScreen(
          complaint: complaint,
          orders: orders,
          onSendMessage: (String message) => addMessage(complaint['id'], message),
          formatTimestamp: formatTimestamp,
          getOrderDetails: getOrderDetails,
        ),
      ),
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    if (timestamp is Timestamp) {
      final DateTime dateTime = timestamp.toDate();
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    }

    return timestamp.toString();
  }

  String getOrderDetails(String orderId) {
    // Try to find the order in the orders list
    final orderIndex = orders.indexWhere((order) => order['id'] == orderId);

    // If order is found
    if (orderIndex != -1) {
      final order = orders[orderIndex];

      // Get the important details
      final productName = order['product_name'] ?? 'Unknown Product';
      final size = order['size'] ?? 'N/A';
      final color = order['color'] ?? 'N/A';
      final price = order['price'] != null ? '₹${order['price'].toStringAsFixed(2)}' : 'N/A';
      final status = order['order_status'] ?? 'N/A';

      // Format and return the important details
      return '$productName • Size: $size • Color: $color • $status • $price';
    }

    // If order isn't found in the cached orders list, try fetching it
    return 'Order details not available';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Complaints',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.teal[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('updated_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading complaints: ${snapshot.error}'),
            );
          }

          final complaints = snapshot.data?.docs ?? [];

          return Column(
            children: [
              // Create new complaint section
              ExpansionTile(
                title: const Text(
                  'Create New Complaint',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                leading: const Icon(Icons.add_circle, color: Colors.teal),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Order:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (isLoadingOrders)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: selectedOrderId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            hint: const Text('Select Order'),
                            isExpanded: true, // Prevent overflow in dropdown
                            items: orders.map((order) {
                              return DropdownMenuItem<String>(
                                value: order['id'],
                                child: Text(
                                  'Order #${order['id'].substring(0, min(8, order['id'].length))} - ${formatTimestamp(order['created_at'])}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedOrderId = value;
                              });
                            },
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Complaint Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _complaintController,
                          decoration: InputDecoration(
                            hintText: 'Describe your issue...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmittingComplaint
                                ? null
                                : submitComplaint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: isSubmittingComplaint
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Submit Complaint',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Existing complaints list
              Expanded(
                child: complaints.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No complaints yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new complaint using the form above',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  itemCount: complaints.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final complaint = complaints[index].data() as Map<String, dynamic>;
                    complaint['id'] = complaints[index].id;

                    return ListTile(
                      title: Text(
                        '#${complaint['order_id']?.substring(0, min(8, complaint['order_id']?.length ?? 0)) ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint['complaint_text'] ?? 'No details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            formatTimestamp(complaint['updated_at']),
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
                      onTap: () => viewComplaint(complaint),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Separate screen for complaint details (mobile view)
class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final List<Map<String, dynamic>> orders;
  final Function(String) onSendMessage;
  final Function(dynamic) formatTimestamp;
  final Function(String) getOrderDetails;

  const ComplaintDetailScreen({
    Key? key,
    required this.complaint,
    required this.orders,
    required this.onSendMessage,
    required this.formatTimestamp,
    required this.getOrderDetails,
  }) : super(key: key);

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool isSubmittingMessage = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complaint #${widget.complaint['id'].substring(0, min(8, widget.complaint['id'].length))}',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.teal[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: widget.complaint['status'] == 'Open'
                  ? Colors.red.withOpacity(0.2)
                  : widget.complaint['status'] == 'Closed'
                  ? Colors.red.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.complaint['status'] == 'Open'
                    ? Colors.red
                    : widget.complaint['status'] == 'Closed'
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            child: Text(
              widget.complaint['status'] ?? 'Unknown',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        ],
      ),
      body: Column(
        children: [
          // Order details header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order ID',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('complaints')
                                .doc(widget.complaint['id'])
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Loading...');
                              }

                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }

                              final complaintData = snapshot.data?.data() as Map<String, dynamic>?;
                              final orderId = complaintData?['order_id'] ?? 'N/A';

                              return Text(
                                orderId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.formatTimestamp(widget.complaint['created_at']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('complaints')
                          .doc(widget.complaint['id'])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Loading...');
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        final complaintData = snapshot.data?.data() as Map<String, dynamic>?;
                        final orderId = complaintData?['order_id'] ?? '';

                        return Text(
                          widget.getOrderDetails(orderId),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Complaint content and messages
          Expanded(
            child: Column(
              children: [
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
                            widget.complaint['complaint_text'] ?? 'No complaint text provided',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Messages section
                        const Text(
                          'Messages:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('complaints')
                              .doc(widget.complaint['id'])
                              .collection('messages')
                              .orderBy('created_at', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
                                  'No messages yet. Add a message below to communicate with support.',
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
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                                    ),
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isAdmin
                                          ? Colors.blue[100]
                                          : Colors.teal[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isAdmin
                                          ? CrossAxisAlignment.start
                                          : CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          message['text'] ?? '',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${isAdmin ? "Support" : "You"} • ${widget.formatTimestamp(message['created_at'])}',
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

                // Message input area (only visible for open complaints)
                if (widget.complaint['status'] == 'Open')
                  Container(
                    padding: const EdgeInsets.all(12),
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
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: isSubmittingMessage
                              ? null
                              : () {
                            setState(() {
                              isSubmittingMessage = true;
                            });
                            widget.onSendMessage(_messageController.text).then((_) {
                              setState(() {
                                isSubmittingMessage = false;
                                _messageController.clear();
                              });
                            }).catchError((e) {
                              setState(() {
                                isSubmittingMessage = false;
                              });
                            });
                          },
                          icon: isSubmittingMessage
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.send),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Complaint closed message
                if (widget.complaint['status'] == 'Closed')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'This complaint has been closed. If you need further assistance, please create a new complaint.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to avoid index out of range errors
int min(int a, int b) {
  return a < b ? a : b;
}