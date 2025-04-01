import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'DeliveryPartnerDrawer.dart'; // Ensure this file exists

class OrdersToDeliverScreen extends StatefulWidget {
  @override
  _OrdersToDeliverScreenState createState() => _OrdersToDeliverScreenState();
}

class _OrdersToDeliverScreenState extends State<OrdersToDeliverScreen> {
  String? deliveryPartnerId;
  Map<String, dynamic>? deliveryPartnerDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDeliveryPartnerDetails();
  }

  Future<void> fetchDeliveryPartnerDetails() async {
    try {
      String? userUid = FirebaseAuth.instance.currentUser?.uid;
      if (userUid == null) {
        print('Error: No logged-in user found.');
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
      if (userDoc.exists) {
        setState(() {
          deliveryPartnerId = userUid;
          deliveryPartnerDetails = userDoc.data() as Map<String, dynamic>;
        });
      } else {
        print('Error: No delivery partner found in Firestore.');
      }
    } catch (e) {
      print('Error fetching delivery partner details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Orders To Deliver',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.orange.withOpacity(1),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
      ),
      drawer: DeliveryPartnerDrawer(currentScreen: 'Orders to Deliver'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Section 1: Orders from Seller to Storage
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'From Seller to Storage 📦',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: buildOrdersStream('orders_pickup', ['pending', 'picked'], true),
          ),

          // Section 2: Orders from Storage to Customer
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'From Storage to Customer 🚚',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: buildOrdersStream('final_delivery', ['Out for Delivery', 'Out for Delivery and Handed to Delivery Boy'], false),
          ),
        ],
      ),
    );
  }

  // 🔹 Pickup Orders Card

  Widget buildPickupCard(String orderId, Map<String, dynamic> orderData, String pickupStatus) {
    String sellerId = orderData['seller_id'] ?? 'N/A';
    Map<String, dynamic>? sellerAddress = orderData['seller_details']?['address'];

    String address = sellerAddress != null
        ? "${sellerAddress['line1'] ?? ''}, ${sellerAddress['line2'] ?? ''}, ${sellerAddress['city'] ?? ''}, ${sellerAddress['state'] ?? ''} - ${sellerAddress['zipcode'] ?? ''}"
        : "N/A";

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('seller_details').doc(sellerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text("❌ Error fetching seller details");
        }

        Map<String, dynamic>? sellerData = snapshot.data!.data() as Map<String, dynamic>?;
        String sellerName = sellerData?['name'] ?? 'N/A';
        String sellerPhone = sellerData?['contact']?['business_phone'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🆔 Order ID: $orderId', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),

                // ✅ Seller Information Section
                Text('🏢 Seller Name:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sellerName),
                const SizedBox(height: 8),

                Text('📍 Seller Address:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(address),
                const SizedBox(height: 8),

                Text('📞 Seller Phone:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sellerPhone),
                const Divider(),

                /// 🔹 **Show Action Button Based on Status**
                if (pickupStatus == 'pending')
                  buildButton(orderId, 'Pick Up', Colors.orange, markAsPicked),

                if (pickupStatus == 'picked')
                  buildButton(orderId, 'Drop to Storage', Colors.blue, dropOnGodown),


              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Final Delivery Orders Card

  // 🔹 Stream Builder for Orders (Pickup & Final Delivery)
  Widget buildOrdersStream(String collection, List<String> statuses, bool isPickup) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('delivery_partner_id', isEqualTo: deliveryPartnerId)
          .where(isPickup ? 'pickup_status' : 'delivery_status', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text('No assigned deliveries.'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderData = orders[index].data() as Map<String, dynamic>;
            String orderId = orderData['order_id'];
            String status = isPickup ? orderData['pickup_status'] : orderData['delivery_status'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (orderSnapshot.hasError) {
                  return Center(child: Text('Error: ${orderSnapshot.error}'));
                }
                if (!orderSnapshot.hasData || !orderSnapshot.data!.exists) {
                  return const Center(child: Text('Order details not found.'));
                }

                Map<String, dynamic>? orderDetails = orderSnapshot.data?.data() as Map<String, dynamic>?;

                if (orderDetails == null) {
                  return const Center(child: Text('Invalid order data.'));
                }

                return isPickup
                    ? buildPickupCard(orderId, orderDetails, status)
                    : buildFinalDeliveryCard(orderId, orderDetails['product_id'], status);

              },
            );
          },
        );
      },
    );
  }

  Widget buildFinalDeliveryCard(String orderId, String productId, String deliveryStatus) {
    TextEditingController pinController = TextEditingController(); // Controller for PIN input

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!orderSnapshot.hasData || !orderSnapshot.data!.exists) {
          return const Center(child: Text('❌ Order details not found.'));
        }

        Map<String, dynamic> orderDetails = orderSnapshot.data!.data() as Map<String, dynamic>;

        // ✅ Extract order data
        String customerName = orderDetails['shipping_address']['name'] ?? 'N/A';
        String customerPhone = orderDetails['shipping_address']['phone'] ?? 'N/A';
        String customerAddress = "${orderDetails['shipping_address']['line1']}, "
            "${orderDetails['shipping_address']['line2']}, "
            "${orderDetails['shipping_address']['city']}, "
            "${orderDetails['shipping_address']['state']} - ${orderDetails['shipping_address']['zipcode']}";
        String color = orderDetails['color'] ?? 'N/A';
        String size = orderDetails['size'] ?? 'N/A';
        String orderPin = orderDetails['order_pin'] ?? ''; // ✅ Fetch PIN from order
        String orderStatus = orderDetails['order_status'] ?? 'Unknown';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🆔 Order ID: $orderId', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('🔖 Product ID: $productId'),
                Text('🎨 Color: $color'),
                Text('📏 Size: $size'),
                const Divider(),
                Text('👤 Customer Name:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(customerName),
                const SizedBox(height: 8),
                Text('📍 Customer Address:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(customerAddress),
                const SizedBox(height: 8),
                Text('📞 Customer Phone:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(customerPhone),
                const Divider(),

                /// 🔹 **Show "Pick Up" Button Before PIN Verification**
                if (orderStatus == 'Ready to Deliver')
                  ElevatedButton(
                    onPressed: () => markAsOutForDelivery(orderId),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Pick Up',style: TextStyle(color: Colors.white),),
                  ),

                /// 🔹 **Show PIN Verification Button for Final Delivery**
                if (orderStatus == 'Out for Delivery and Handed to Delivery Boy')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔑 Enter Delivery PIN:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          counterText: '',
                          hintText: 'Enter 6-digit PIN',
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (pinController.text.trim() == orderPin) {
                            markAsFinalDelivered(orderId);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ Incorrect PIN. Please try again!')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Handed to Customer'),
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



// 🔹 Order Card Builder
  Widget buildOrderCard(String orderId, Map<String, dynamic> orderData, String status, Map<String, List<dynamic>> buttonActions) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${orderData['product_name'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Size: ${orderData['size'] ?? 'N/A'} | Color: ${orderData['color'] ?? 'N/A'}'),
            Text('Price: ₹${orderData['price']?.toStringAsFixed(2) ?? '0.00'}'),
            const Divider(),
            if (buttonActions.containsKey(status))
              buildButton(orderId, buttonActions[status]![0], buttonActions[status]![1], buttonActions[status]![2]),
          ],
        ),
      ),
    );
  }

// 🔹 Button Builder
  Widget buildButton(String orderId, String text, Color color, Function(String) onPressed) {
    return ElevatedButton(
      onPressed: () => onPressed(orderId),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(text),
    );
  }

  // ✅ Mark order as "Out for Delivery and Handed to Delivery Boy"
  // Future<void> markAsOutForDelivery(String orderId) async {
  //   try {
  //     await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
  //       'order_status': 'Out for Delivery and Handed to Delivery Boy',
  //       'updated_at': Timestamp.now(),
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Order is now Out for Delivery!')),
  //     );
  //
  //     setState(() {}); // Refresh UI
  //   } catch (e) {
  //     print('❌ Error updating order status: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   }
  // }

// ✅ Mark order as "Delivered" after PIN verification
//   Future<void> markAsFinalDelivered(String orderId) async {
//     try {
//       FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//       // ✅ Step 1: Fetch order details
//       DocumentSnapshot orderSnapshot = await firestore.collection('orders').doc(orderId).get();
//
//       if (!orderSnapshot.exists) {
//         print('❌ Error: Order not found!');
//         return;
//       }
//
//       Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;
//       String productId = orderData['product_id'].trim();
//       String selectedColor = orderData['color'].trim().toLowerCase();
//       String selectedSize = orderData['size'].trim();
//
//       // ✅ Step 2: Update order status in Firestore
//       await firestore.collection('orders').doc(orderId).update({
//         'order_status': 'Delivered',
//         'payment_status': 'Paid',
//       });
//
//       // ✅ Step 3: Update `final_delivery`
//       await firestore.collection('final_delivery').doc(orderId).update({
//         'delivery_status': 'Delivered',
//       });
//
//       // ✅ Step 4: Reduce stock in `Products`
//       DocumentReference productRef = firestore.collection('Products').doc(productId);
//
//       await firestore.runTransaction((transaction) async {
//         DocumentSnapshot productSnapshot = await transaction.get(productRef);
//
//         if (!productSnapshot.exists) {
//           print('❌ Error: Product not found!');
//           return;
//         }
//
//         Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
//         List<dynamic> colorsList = List.from(productData['colors']);
//         int totalStock = productData['metadata'] != null ? productData['metadata']['totalStock'] ?? 0 : 0;
//
//         int colorIndex = colorsList.indexWhere(
//                 (c) => c['colorName'].trim().toLowerCase() == selectedColor);
//
//         if (colorIndex != -1) {
//           List<dynamic> sizesList = List.from(colorsList[colorIndex]['sizes']);
//
//           int sizeIndex = sizesList.indexWhere((s) => s['size'].trim() == selectedSize);
//           if (sizeIndex != -1) {
//             int currentStock = sizesList[sizeIndex]['stock'];
//
//             if (currentStock > 0) {
//               sizesList[sizeIndex]['stock'] -= 1;
//               totalStock -= 1;
//
//               colorsList[colorIndex]['sizes'] = sizesList;
//
//               transaction.update(productRef, {
//                 'colors': colorsList,
//                 'metadata.totalStock': totalStock,
//               });
//
//               print('✅ Stock updated! New stock: ${sizesList[sizeIndex]['stock']}');
//             } else {
//               print('⚠️ Error: Stock is already 0 for this size!');
//             }
//           } else {
//             print('⚠️ Error: Size not found!');
//           }
//         } else {
//           print('⚠️ Error: Color not found!');
//         }
//       });
//
//       // ✅ Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order delivered, payment completed, and stock updated!')),
//       );
//
//       setState(() {}); // Refresh UI
//     } catch (e) {
//       print('❌ Error updating order: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

  // ✅ Mark order as "Out for Delivery and Handed to Delivery Boy"
  Future<void> markAsOutForDelivery(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'order_status': 'Out for Delivery and Handed to Delivery Boy',
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order is now Out for Delivery!')),
      );

      setState(() {}); // Refresh UI
    } catch (e) {
      print('❌ Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

// ✅ Mark order as "Delivered" after PIN verification
  Future<void> markAsFinalDelivered(String orderId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // ✅ Step 1: Fetch order details
      DocumentSnapshot orderSnapshot = await firestore.collection('orders').doc(orderId).get();

      if (!orderSnapshot.exists) {
        print('❌ Error: Order not found!');
        return;
      }

      Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;
      String productId = orderData['product_id'].trim();
      String selectedColor = orderData['color'].trim().toLowerCase();
      String selectedSize = orderData['size'].trim();

      // ✅ Step 2: Update order status in Firestore
      await firestore.collection('orders').doc(orderId).update({
        'order_status': 'Delivered',
        'payment_status': 'Paid',
      });

      // ✅ Step 3: Update `final_delivery`
      await firestore.collection('final_delivery').doc(orderId).update({
        'delivery_status': 'Delivered',
      });

      // ✅ Step 4: Reduce stock in `Products`
      DocumentReference productRef = firestore.collection('Products').doc(productId);

      await firestore.runTransaction((transaction) async {
        DocumentSnapshot productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          print('❌ Error: Product not found!');
          return;
        }

        Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
        List<dynamic> colorsList = List.from(productData['colors']);
        int totalStock = productData['metadata'] != null ? productData['metadata']['totalStock'] ?? 0 : 0;

        int colorIndex = colorsList.indexWhere(
                (c) => c['colorName'].trim().toLowerCase() == selectedColor);

        if (colorIndex != -1) {
          List<dynamic> sizesList = List.from(colorsList[colorIndex]['sizes']);

          int sizeIndex = sizesList.indexWhere((s) => s['size'].trim() == selectedSize);
          if (sizeIndex != -1) {
            int currentStock = sizesList[sizeIndex]['stock'];

            if (currentStock > 0) {
              sizesList[sizeIndex]['stock'] -= 1;
              totalStock -= 1;

              colorsList[colorIndex]['sizes'] = sizesList;

              transaction.update(productRef, {
                'colors': colorsList,
                'metadata.totalStock': totalStock,
              });

              print('✅ Stock updated! New stock: ${sizesList[sizeIndex]['stock']}');
            } else {
              print('⚠️ Error: Stock is already 0 for this size!');
            }
          } else {
            print('⚠️ Error: Size not found!');
          }
        } else {
          print('⚠️ Error: Color not found!');
        }
      });

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order delivered, payment completed, and stock updated!')),
      );

      setState(() {}); // Refresh UI
    } catch (e) {
      print('❌ Error updating order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }




  // 🔹 Firestore Updates
  Future<void> markAsDelivered(String orderId) async {
    await updateFirestore(orderId, 'orders_pickup', 'pickup_status', 'picked', 'orders', 'order_status', 'Shipped');
  }

  Future<void> dropOnGodown(String orderId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      print('🔹 dropOnGodown() called for Order ID: $orderId');

      // ✅ Step 1: Update order status in 'orders' collection
      await firestore.collection('orders').doc(orderId).update({
        'order_status': 'Shipped',  // Original code set this to "Shipped"
      });

      print('✅ Updated order_status to "Shipped" for Order ID: $orderId');

      // ✅ Step 2: Update pickup status in 'orders_pickup' collection
      await firestore.collection('orders_pickup').doc(orderId).update({
        'pickup_status': 'completed',
      });

      print('✅ Updated pickup_status to "completed" in orders_pickup');

      // ✅ Step 3: Move order to 'final_delivery' collection
      DocumentReference finalDeliveryRef = firestore.collection('final_delivery').doc(orderId);

      await finalDeliveryRef.set({
        'order_id': orderId,
        'delivery_status': 'Out for Delivery',
        'assigned_at': Timestamp.now(),
        'delivery_partner_id': null, // Admin will assign this
      });

      print('✅ Order successfully added to final_delivery collection');

      // ✅ Step 4: Refresh UI
      setState(() {});

    } catch (e) {
      print('❌ Error in dropOnGodown: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }






  Future<void> markAsPickedForDelivery(String orderId) async {
    await updateFirestore(orderId, 'final_delivery', 'delivery_status', 'Out for Delivery and Handed to Delivery Boy');
  }

  // Future<void> markAsFinalDelivered(String orderId) async {
  //   try {
  //     FirebaseFirestore firestore = FirebaseFirestore.instance;
  //
  //     // ✅ Step 1: Fetch order details from `orders` using orderId
  //     DocumentSnapshot orderSnapshot = await firestore.collection('orders').doc(orderId).get();
  //
  //     if (!orderSnapshot.exists) {
  //       print('❌ Error: Order not found!');
  //       return;
  //     }
  //
  //     Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;
  //     String productId = orderData['product_id'].trim();  // Ensure it's trimmed
  //     String selectedColor = orderData['color'].trim().toLowerCase();
  //     String selectedSize = orderData['size'].trim();
  //
  //     print('📌 Debug: Order ID: $orderId, Product ID: $productId, Color: $selectedColor, Size: $selectedSize');
  //
  //     // ✅ Step 2: Update `delivery_status` in `final_delivery`
  //     await firestore.collection('final_delivery').doc(orderId).update({
  //       'delivery_status': 'Delivered',
  //     });
  //
  //     // ✅ Step 3: Update `order_status` and `payment_status` in `orders`
  //     await firestore.collection('orders').doc(orderId).update({
  //       'order_status': 'Delivered',
  //       'payment_status': 'Paid',
  //     });
  //
  //     // ✅ Step 4: Fetch product details to update stock
  //     DocumentReference productRef = firestore.collection('Products').doc(productId);
  //
  //     await firestore.runTransaction((transaction) async {
  //       DocumentSnapshot productSnapshot = await transaction.get(productRef);
  //
  //       if (!productSnapshot.exists) {
  //         print('❌ Error: Product not found in Products collection!');
  //         return;
  //       }
  //
  //       Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
  //       List<dynamic> colorsList = List.from(productData['colors']); // Clone colors array
  //       int totalStock = productData['metadata'] != null ? productData['metadata']['totalStock'] ?? 0 : 0;
  //
  //       // 🔍 Find the correct color entry
  //       int colorIndex = colorsList.indexWhere(
  //               (c) => c['colorName'].trim().toLowerCase() == selectedColor
  //       );
  //
  //       if (colorIndex != -1) {
  //         List<dynamic> sizesList = List.from(colorsList[colorIndex]['sizes']); // Clone sizes array
  //
  //         // 🔍 Find the correct size entry
  //         int sizeIndex = sizesList.indexWhere((s) => s['size'].trim() == selectedSize);
  //         if (sizeIndex != -1) {
  //           int currentStock = sizesList[sizeIndex]['stock'];
  //
  //           if (currentStock > 0) {
  //             sizesList[sizeIndex]['stock'] -= 1; // ✅ Reduce stock by 1
  //             totalStock -= 1; // ✅ Reduce totalStock count
  //
  //             // ✅ Update the color array with the new sizes list
  //             colorsList[colorIndex]['sizes'] = sizesList;
  //
  //             // ✅ Step 5: Update Firestore with reduced stock
  //             transaction.update(productRef, {
  //               'colors': colorsList, // Full colors array updated
  //               'metadata.totalStock': totalStock, // ✅ Update total stock
  //             });
  //
  //             print('✅ Stock updated successfully! New stock: ${sizesList[sizeIndex]['stock']}');
  //           } else {
  //             print('⚠️ Error: Stock is already 0 for this size!');
  //           }
  //         } else {
  //           print('⚠️ Error: Size not found!');
  //         }
  //       } else {
  //         print('⚠️ Error: Color not found!');
  //       }
  //     });
  //
  //     // ✅ Show success message
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Order delivered, payment completed, and stock updated!')),
  //     );
  //
  //     // ✅ Refresh UI
  //     setState(() {});
  //   } catch (e) {
  //     print('❌ Error updating delivery, payment, and stock: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   }
  // }




  Future<void> updateFirestore(String orderId, String collection, String field, String newValue, [String? secondCollection, String? secondField, String? secondValue]) async {
    await FirebaseFirestore.instance.collection(collection).doc(orderId).update({field: newValue});
    if (secondCollection != null && secondField != null && secondValue != null) {
      await FirebaseFirestore.instance.collection(secondCollection).doc(orderId).update({secondField: secondValue});
    }
    setState(() {});
  }

  Future<void> markAsPicked(String orderId) async {
    await FirebaseFirestore.instance
        .collection('orders_pickup')
        .doc(orderId)
        .update({'pickup_status': 'picked'});

    setState(() {}); // Refresh UI
  }

  Future<void> markAsCompleted(String orderId) async {
    await FirebaseFirestore.instance
        .collection('orders_pickup')
        .doc(orderId)
        .update({'pickup_status': 'completed'});

    setState(() {}); // Refresh UI
  }

}
