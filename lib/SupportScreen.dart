import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'CustomerDrawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _queryController = TextEditingController();
  List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  bool _showComplaintForm = false;
  String? _selectedOrderId;
  final TextEditingController _complaintController = TextEditingController();

  // Replace with your actual Gemini API key
  static const String _apiKey = 'AIzaSyBlN8ScLeqpArs98xoVkyQ0B8gXPUnYcW0'; // Replace with your key

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-pro-exp-03-25',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 65536,
        responseMimeType: 'text/plain',
      ),
    );
    _chat = _model.startChat(history: []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialQuery();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _complaintController.dispose();
    super.dispose();
  }

  // Fetch comprehensive context from multiple collections
  Future<String> _fetchUserContext({String? specificOrderId}) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return "No user logged in.";

      String context = "";

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.exists ? userDoc.data() : null;
      context += "Customer Info:\n";
      context += "- Name: ${userData?['name'] ?? 'Unknown'}\n";
      context += "- Email: ${userData?['email'] ?? 'Unknown'}\n";
      context += "- Phone: ${userData?['phone'] ?? 'Not provided'}\n\n";

      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: currentUser.uid)
          .orderBy('created_at', descending: true)
          .limit(specificOrderId == null ? 3 : 1)
          .get();
      final orders = ordersQuery.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList();

      if (orders.isEmpty) {
        context += "Orders: No orders found.\n";
      } else {
        context += "Orders:\n";
        int index = 1;
        for (var order in orders) {
          if (specificOrderId == null || order['id'] == specificOrderId) {
            String orderId = order['id'];
            context += "${specificOrderId == null ? '$index. ' : ''}Order ID: $orderId\n";

            // Fetch product details from Products collection using product_id
            final productId = order['product_id'];
            String productName = 'Unknown';
            String color = order['color'] ?? 'N/A';
            String size = order['size'] ?? 'N/A';
            double price = order['price']?.toDouble() ?? 0.0;

            if (productId != null) {
              final productDoc = await FirebaseFirestore.instance
                  .collection('Products')
                  .doc(productId)
                  .get();
              if (productDoc.exists) {
                final productData = productDoc.data();
                productName = productData?['name'] ?? 'Unknown';
                price = productData?['price']?.toDouble() ?? price;

                final colors = productData?['colors'] as List<dynamic>? ?? [];
                final matchingColor = colors.firstWhere(
                      (c) => c['colorName'].toString().toLowerCase() == color.toLowerCase(),
                  orElse: () => null,
                );
                if (matchingColor != null) {
                  color = matchingColor['colorName'];
                }
              }
            }

            context += "  Product: $productName ($color, Size $size)\n";
            context += "  Price: ₹${price.toStringAsFixed(2)}\n";
            context += "  Status: ${order['order_status'] ?? 'Unknown'}\n";
            context += "  Order Date: ${order['created_at']?.toDate().toString() ?? 'Unknown'}\n";
            context += "  Shipping Address: ${order['shipping_address']?['line1'] ?? ''}, "
                "${order['shipping_address']?['city'] ?? ''}, ${order['shipping_address']?['state'] ?? ''}\n";

            final sellerId = order['seller_id'];
            if (sellerId != null) {
              final sellerDoc = await FirebaseFirestore.instance
                  .collection('seller_details')
                  .doc(sellerId)
                  .get();
              final sellerData = sellerDoc.exists ? sellerDoc.data() : {};
              context += "  Seller Info:\n";
              context += "    Store Name: ${sellerData?['business_details']?['store_name'] ?? 'Unknown'}\n";
              context += "    Seller Name: ${sellerData?['name'] ?? 'Unknown'}\n";
              context += "    Business Email: ${sellerData?['contact']?['business_email'] ?? 'Unknown'}\n";
            }

            final pickupDoc = await FirebaseFirestore.instance
                .collection('orders_pickup')
                .doc(orderId)
                .get();
            if (pickupDoc.exists) {
              final pickupData = pickupDoc.data();
              final deliveryPartnerId = pickupData?['delivery_partner_id'];
              if (deliveryPartnerId != null) {
                final dpDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(deliveryPartnerId)
                    .get();
                final dpData = dpDoc.exists ? dpDoc.data() : {};
                context += "  Delivery Partner:\n";
                context += "    Name: ${dpData?['name'] ?? 'Unknown'}\n";
                context += "    Pickup Status: ${pickupData?['pickup_status'] ?? 'Pending'}\n";
              } else {
                context += "  Delivery Partner: Not assigned yet.\n";
              }
            } else {
              context += "  Delivery Partner: Not assigned yet.\n";
            }
            context += "\n";
            if (specificOrderId == null) index++;
          }
        }
      }

      return context;
    } catch (e) {
      print('Error fetching context: $e');
      return "Error fetching user data: $e";
    }
  }

  // Send initial query to show last 3 orders
  Future<void> _sendInitialQuery() async {
    setState(() {
      _isLoading = true;
      _chatHistory.add({"role": "ai", "message": "•• Typing"});
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      final userName = userDoc.exists && userDoc.data() != null ? userDoc.data()!['name'] ?? 'User' : 'User';

      final context = await _fetchUserContext();
      final message = "Context:\n$context\n\nUser Query: Show me my last 3 orders with options to chat about them.";
      final content = Content.text(message);

      final response = await _chat.sendMessage(content);
      String formattedResponse = "Okay, $userName, here are your last 3 orders based on the information provided. You can click the chat link next to each order to discuss it specifically:\n\n" +
          _formatAIResponse(response.text ?? "No orders found.") +
          "\n\nSelect an order to chat about it:\n[1] for Order 1\n[2] for Order 2\n[3] for Order 3";

      setState(() {
        _chatHistory.removeLast();
        _chatHistory.add({"role": "ai", "message": formattedResponse});
      });
    } catch (e) {
      setState(() {
        _chatHistory.removeLast();
        _chatHistory.add({"role": "ai", "message": "Error: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Send query to Gemini API
  Future<void> _sendQueryToAI() async {
    if (_queryController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _chatHistory.add({"role": "user", "message": _queryController.text});
      _chatHistory.add({"role": "ai", "message": "•• Typing"});
    });

    try {
      String context;
      String query = _queryController.text.trim();

      // Check if this is a command to file a complaint
      if (query.toLowerCase().contains("file complaint") ||
          query.toLowerCase().contains("register complaint") ||
          query.toLowerCase().contains("submit complaint")) {

        _chatHistory.removeLast();
        _chatHistory.add({"role": "ai", "message": "I'll help you file a complaint. Please select the order you want to file a complaint about."});
        setState(() {
          _isLoading = false;
        });
        _showOrderSelectionDialog();
        return;
      }

      if (RegExp(r'^[1-3]$').hasMatch(query)) {
        final orderIndex = int.parse(query) - 1;
        final recentOrders = (await FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('created_at', descending: true)
            .limit(3)
            .get())
            .docs;
        if (orderIndex < recentOrders.length) {
          context = await _fetchUserContext(specificOrderId: recentOrders[orderIndex].id);
        } else {
          context = "Invalid order selection.";
        }
      } else {
        context = await _fetchUserContext();
      }

      final message = "Context:\n$context\n\nUser Query: $query";
      final content = Content.text(message);

      final response = await _chat.sendMessage(content);
      String formattedResponse = _formatAIResponse(response.text ?? "No response from AI.");

      // Add complaint option to AI response
      formattedResponse += "\n\n[File a Complaint] if you're having issues with your order.";

      setState(() {
        _chatHistory.removeLast();
        _chatHistory.add({"role": "ai", "message": formattedResponse});
      });
    } catch (e) {
      setState(() {
        _chatHistory.removeLast();
        _chatHistory.add({"role": "ai", "message": "Error: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
        _queryController.clear();
      });
    }
  }

  // Format AI response
  String _formatAIResponse(String response) {
    String cleanedResponse = response.replaceAll(RegExp(r'\*{2,3}'), '');
    List<String> lines = cleanedResponse.split('\n');
    String formatted = '';
    int orderCount = 0;
    for (var line in lines) {
      if (line.trim().isNotEmpty) {
        if (line.trim().startsWith(RegExp(r'^\d+\.\s*Order ID:'))) {
          orderCount++;
          formatted += '$line\n';
        } else if (orderCount > 0) {
          formatted += '$line\n';
          if (line.trim().startsWith('Delivery Partner:') || line.trim().isEmpty) {
            formatted += '[Chat about this order]\n';
            orderCount = 0;
          }
        } else {
          formatted += '$line\n';
        }
      }
    }
    return formatted.trim();
  }

  // Navigate to blank CustomerCareExecutiveChatScreen
  void _navigateToCustomerCareChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerCareExecutiveChatScreen()),
    );
  }

  // Show dialog to select an order for complaint
  Future<void> _showOrderSelectionDialog() async {
    final recentOrders = (await FirebaseFirestore.instance
        .collection('orders')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('created_at', descending: true)
        .limit(5)
        .get())
        .docs;

    if (recentOrders.isEmpty) {
      setState(() {
        _chatHistory.add({"role": "ai", "message": "You don't have any orders to file a complaint about."});
      });
      return;
    }

    List<Map<String, dynamic>> orderList = [];
    for (var orderDoc in recentOrders) {
      final order = orderDoc.data();
      final productId = order['product_id'];
      String productName = 'Unknown';

      if (productId != null) {
        final productDoc = await FirebaseFirestore.instance
            .collection('Products')
            .doc(productId)
            .get();
        if (productDoc.exists) {
          productName = productDoc.data()?['name'] ?? 'Unknown';
        }
      }

      orderList.add({
        'id': orderDoc.id,
        'product': productName,
        'date': order['created_at']?.toDate().toString() ?? 'Unknown',
        'status': order['order_status'] ?? 'Unknown'
      });
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Order for Complaint'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(orderList[index]['product']),
                subtitle: Text('Order ID: ${orderList[index]['id']}\nStatus: ${orderList[index]['status']}'),
                onTap: () {
                  setState(() {
                    _selectedOrderId = orderList[index]['id'];
                  });
                  Navigator.pop(context);
                  _showComplaintFormDialog();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Show complaint form dialog
  void _showComplaintFormDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File a Complaint'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: $_selectedOrderId',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _complaintController,
                  decoration: InputDecoration(
                    labelText: 'Describe your issue',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitComplaint();
                },
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[900],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Submit complaint to Firestore
  Future<void> _submitComplaint() async {
    if (_complaintController.text.trim().isEmpty || _selectedOrderId == null) return;

    setState(() {
      _isLoading = true;
      _chatHistory.add({"role": "user", "message": "I want to file a complaint about order: $_selectedOrderId\n\n${_complaintController.text}"});
      _chatHistory.add({"role": "ai", "message": "•• Processing your complaint"});
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("No user logged in");

      // Get user and order details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.exists ? userDoc.data() : null;

      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(_selectedOrderId)
          .get();
      final orderData = orderDoc.exists ? orderDoc.data() : null;

      // Create AI summary of the complaint
      final context = "Order Details:\nOrder ID: $_selectedOrderId\n"
          "Product: ${orderData?['product_id'] ?? 'Unknown'}\n"
          "Status: ${orderData?['order_status'] ?? 'Unknown'}\n"
          "User Description of Issue: ${_complaintController.text}\n\n"
          "Task: Create a concise summary of this complaint for our database (max 100 words).";

      final content = Content.text(context);
      final response = await _chat.sendMessage(content);
      final aiSummary = response.text ?? "Complaint about order $_selectedOrderId";

      // Register complaint in Firestore
      final complaintId = await FirebaseFirestore.instance.collection('complaints').add({
        'user_id': currentUser.uid,
        'user_name': userData?['name'] ?? 'Unknown',
        'user_email': userData?['email'] ?? 'Unknown',
        'order_id': _selectedOrderId,
        'complaint_text': _complaintController.text,
        'ai_summary': aiSummary,
        'status': 'Open',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'assigned_to': null
      });

      // Generate AI response for the user
      final userResponsePrompt = "Context: A user has filed a complaint about order $_selectedOrderId with the following description:\n\n"
          "${_complaintController.text}\n\n"
          "Task: Create a helpful and empathetic response acknowledging their complaint, inform them that their complaint has been registered with ID: ${complaintId.id}, "
          "and let them know that a customer service representative will contact them within 24 hours. "
          "Include a brief sentence about what might have happened based on their description without admitting fault.";

      final userResponseContent = Content.text(userResponsePrompt);
      final userResponse = await _chat.sendMessage(userResponseContent);

      setState(() {
        _chatHistory.removeLast();
        _chatHistory.add({
          "role": "ai",
          "message": userResponse.text ??
              "Thank you for submitting your complaint. Your complaint has been registered with ID: ${complaintId.id}. A customer service representative will contact you within 24 hours to address your issue."
        });
      });

      _complaintController.clear();
      _selectedOrderId = null;
    } catch (e) {
      setState(() {
        _chatHistory.removeLast();
        _chatHistory.add({"role": "ai", "message": "Error filing complaint: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '      AI Support   ',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: CustomerDrawer(currentScreen: 'Support'),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: Colors.teal.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToCustomerCareChat,
                    icon: Icon(Icons.support_agent, color: Colors.white),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Chat Customer Executive",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "+91 123-456-7890",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[900],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showOrderSelectionDialog(),
                    icon: Icon(Icons.report_problem, color: Colors.white),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "File Complaint",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "Report an issue",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isUser = message['role'] == 'user';
                List<String> lines = message['message']!.split('\n');
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.teal : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines.asMap().entries.map((entry) {
                        int lineIndex = entry.key;
                        String line = entry.value;
                        final orderMatch = RegExp(r'(\d+)\.\s*Order ID:\s*(\w+)').firstMatch(line);
                        final chatLinkMatch = RegExp(r'\[Chat about this order\]').firstMatch(line);
                        final complaintLinkMatch = RegExp(r'\[File a Complaint\]').firstMatch(line);

                        if (orderMatch != null && !isUser) {
                          return Text(
                            line,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else if (chatLinkMatch != null && !isUser) {
                          final orderNumber = RegExp(r'(\d+)\.\s*Order ID:').firstMatch(lines[lineIndex - 5])?.group(1);
                          return GestureDetector(
                            onTap: () {
                              if (orderNumber != null) {
                                _queryController.text = orderNumber;
                                _sendQueryToAI();
                              }
                            },
                            child: Text(
                              line,
                              style: TextStyle(
                                color: Colors.teal[900],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );
                        } else if (complaintLinkMatch != null && !isUser) {
                          return GestureDetector(
                            onTap: () {
                              _showOrderSelectionDialog();
                            },
                            child: Text(
                              line,
                              style: TextStyle(
                                color: Colors.red[800],
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        } else if (line.startsWith('Select an order to chat about it:')) {
                          return Text(
                            line,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else if (RegExp(r'^\[\d+\]').hasMatch(line)) {
                          final orderNumber = RegExp(r'^\[(\d+)\]').firstMatch(line)?.group(1);
                          return GestureDetector(
                            onTap: () {
                              if (orderNumber != null) {
                                _queryController.text = orderNumber;
                                _sendQueryToAI();
                              }
                            },
                            child: Text(
                              line,
                              style: TextStyle(
                                color: Colors.teal[900],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );
                        } else {
                          return Text(
                            line,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                            ),
                          );
                        }
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: 'Ask anything about your orders or file a complaint...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: _isLoading
                      ? CircularProgressIndicator(color: Colors.teal[900])
                      : Icon(Icons.send, color: Colors.teal[900]),
                  onPressed: _isLoading ? null : _sendQueryToAI,
                  disabledColor: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class CustomerCareExecutiveChatScreen extends StatefulWidget {
  const CustomerCareExecutiveChatScreen({super.key});

  @override
  _CustomerCareExecutiveChatScreenState createState() => _CustomerCareExecutiveChatScreenState();
}

class _CustomerCareExecutiveChatScreenState extends State<CustomerCareExecutiveChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _chatHistory = [
    {"role": "system", "message": "Connecting to Support…"},
  ];
  bool _isLoading = false;

  // Animation for the "Connecting to Support…" dots
  late AnimationController _animationController;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _dotAnimation = IntTween(begin: 1, end: 3).animate(_animationController);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Simulate sending a message (for now, just echo the user's message)
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _chatHistory.add({"role": "user", "message": _messageController.text});
    });

    // Simulate a response (for now, echo the message)
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _chatHistory.add({"role": "system", "message": "Support: Your message - ${_messageController.text}"});
        _isLoading = false;
        _messageController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Care Chat',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[900],
        iconTheme: const IconThemeData(color: Colors.white), // Set back arrow color to white
      ),
      body: Column(
        children: [
          // Chat Section
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isUser = message['role'] == 'user';
                final isSystem = message['role'] == 'system';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.teal
                          : isSystem
                          ? Colors.grey.shade300
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            message['message']!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        if (isSystem && index == 0) // Add animation to "Connecting to Support…" message
                          AnimatedBuilder(
                            animation: _dotAnimation,
                            builder: (context, child) {
                              return Text(
                                ' •' * _dotAnimation.value,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Input Section
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: _isLoading
                      ? CircularProgressIndicator(color: Colors.teal[900])
                      : Icon(Icons.send, color: Colors.teal[900]),
                  onPressed: _isLoading ? null : _sendMessage,
                  disabledColor: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}