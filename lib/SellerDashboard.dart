import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'Seller_Drawer.dart';
import 'StockManagementScreen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  _SellerDashboardState createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  late String _sellerId;
  bool _isLoading = true;

  // Seller data
  Map<String, dynamic> _sellerDetails = {};

  // Dashboard metrics
  double _totalSales = 0.0;
  int _totalProductsSold = 0;
  double _averageOrderValue = 0.0;
  int _lowStockItems = 0;
  int _outOfStockItems = 0;

  // Chart data
  List<Map<String, dynamic>> _monthlySalesData = [];
  List<Map<String, dynamic>> _categoryData = [];

  // Lists for orders and products
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _getCurrentSellerId();
  }

  Future<void> _getCurrentSellerId() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        _sellerId = user.uid;
        await _fetchSellerData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting user ID: $e')),
      );
    }
  }

  Future<void> _fetchSellerData() async {
    try {
      // Fetch seller details
      DocumentSnapshot sellerDoc = await _firestore.collection('seller_details').doc(_sellerId).get();

      if (sellerDoc.exists) {
        _sellerDetails = sellerDoc.data() as Map<String, dynamic>;
      }

      // Fetch orders for this seller
      QuerySnapshot orderSnapshot = await _firestore.collection('orders')
          .where('seller_id', isEqualTo: _sellerId)
          .get();

      _orders = orderSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Calculate sales metrics
      _calculateSalesMetrics();

      // Fetch products for this seller
      QuerySnapshot productSnapshot = await _firestore.collection('Products')
          .where('seller_id', isEqualTo: _sellerId)
          .get();

      _products = productSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Calculate inventory metrics
      _calculateInventoryMetrics();

      // Generate chart data
      _generateChartData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  void _calculateSalesMetrics() {
    if (_orders.isEmpty) {
      _totalSales = 0.0;
      _totalProductsSold = 0;
      _averageOrderValue = 0.0;
      return;
    }

    double total = 0.0;
    for (var order in _orders) {
      if (order.containsKey('price') && order['price'] != null) {
        total += (order['price'] as num).toDouble();
      }
    }

    _totalSales = total;
    _totalProductsSold = _orders.length;
    _averageOrderValue = _totalProductsSold > 0 ? _totalSales / _totalProductsSold : 0.0;
  }

  void _calculateInventoryMetrics() {
    int lowStock = 0;
    int outOfStock = 0;

    for (var product in _products) {
      int totalStock = 0;

      if (product.containsKey('colors') && product['colors'] is List) {
        for (var color in product['colors']) {
          if (color is Map && color.containsKey('sizes') && color['sizes'] is List) {
            for (var size in color['sizes']) {
              if (size is Map && size.containsKey('stock')) {
                totalStock += (size['stock'] as num).toInt();
              }
            }
          }
        }
      }

      if (totalStock <= 0) {
        outOfStock++;
      } else if (totalStock < 10) {
        lowStock++;
      }
    }

    _lowStockItems = lowStock;
    _outOfStockItems = outOfStock;
  }

  int getTotalStock(Map<String, dynamic> product) {
    int totalStock = 0;

    if (product.containsKey('colors') && product['colors'] is List) {
      for (var color in product['colors']) {
        if (color is Map && color.containsKey('sizes') && color['sizes'] is List) {
          for (var size in color['sizes']) {
            if (size is Map && size.containsKey('stock')) {
              totalStock += (size['stock'] as num).toInt();
            }
          }
        }
      }
    }
    return totalStock;
  }



  void _generateChartData() {
    // Generate monthly sales data
    Map<String, double> monthlySales = {};

    for (var order in _orders) {
      if (order.containsKey('created_at') && order['created_at'] != null) {
        Timestamp createdAt = order['created_at'] as Timestamp;
        DateTime orderDate = createdAt.toDate();
        String monthYear = DateFormat('MMM yyyy').format(orderDate);

        double price = 0.0;
        if (order.containsKey('price') && order['price'] != null) {
          price = (order['price'] as num).toDouble();
        }

        if (monthlySales.containsKey(monthYear)) {
          monthlySales[monthYear] = monthlySales[monthYear]! + price;
        } else {
          monthlySales[monthYear] = price;
        }
      }
    }

    _monthlySalesData = monthlySales.entries.map((entry) {
      return {
        'month': entry.key,
        'sales': entry.value,
      };
    }).toList();

    // Sort by date
    _monthlySalesData.sort((a, b) {
      DateTime dateA = DateFormat('MMM yyyy').parse(a['month']);
      DateTime dateB = DateFormat('MMM yyyy').parse(b['month']);
      return dateA.compareTo(dateB);
    });

    // Limit to last 6 months
    if (_monthlySalesData.length > 6) {
      _monthlySalesData = _monthlySalesData.sublist(_monthlySalesData.length - 6);
    }

    // Generate category data
    Map<String, int> categories = {};

    for (var product in _products) {
      if (product.containsKey('category_id') && product['category_id'] != null) {
        String categoryId = product['category_id'] as String;

        if (categories.containsKey(categoryId)) {
          categories[categoryId] = categories[categoryId]! + 1;
        } else {
          categories[categoryId] = 1;
        }
      } else if (product.containsKey('store_profile') &&
          product['store_profile'] != null &&
          product['store_profile'].containsKey('categories')) {
        List<dynamic> productCategories = product['store_profile']['categories'];
        for (var category in productCategories) {
          String categoryName = category as String;

          if (categories.containsKey(categoryName)) {
            categories[categoryName] = categories[categoryName]! + 1;
          } else {
            categories[categoryName] = 1;
          }
        }
      }
    }

    _categoryData = categories.entries.map((entry) {
      return {
        'name': entry.key,
        'value': entry.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black, // Set AppBar color to black
          iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
          title: Text(
            'Sells Data ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white, // Set text color to white
            ),
          ),
        ),


        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    String storeName = _sellerDetails.containsKey('business_details') &&
        _sellerDetails['business_details'] != null &&
        _sellerDetails['business_details'].containsKey('store_name') ?
    _sellerDetails['business_details']['store_name'] : 'My Store';

    String sellerName = _sellerDetails.containsKey('name') ?
    _sellerDetails['name'] :
    (_sellerDetails.containsKey('contact') &&
        _sellerDetails['contact'] != null &&
        _sellerDetails['contact'].containsKey('name') ?
    _sellerDetails['contact']['name'] : 'Seller');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Set AppBar color to black
        iconTheme: const IconThemeData(color: Colors.white), // Set drawer icon color to white
        title: Text(
          '$storeName -Sells Data', // Combine storeName with 'Sells Data'
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Set text color to white
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white), // Set icon color to white
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchSellerData();
            },
          ),
        ],
      ),


      body: RefreshIndicator(
        onRefresh: _fetchSellerData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $sellerName',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900
                ),
              ),
              const SizedBox(height: 24.0),

              // Key Metrics
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMetricCard(
                    title: 'Total Sales',
                    value: currencyFormat.format(_totalSales),
                    icon: Icons.monetization_on,
                    color: Colors.blue,
                  ),
                  _buildMetricCard(
                    title: 'Products Sold',
                    value: _totalProductsSold.toString(),
                    icon: Icons.shopping_bag,
                    color: Colors.green,
                  ),
                  _buildMetricCard(
                    title: 'Avg. Order Value',
                    value: currencyFormat.format(_averageOrderValue),
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                  _buildMetricCard(
                    title: 'Low Stock Alert',
                    value: getLowStockSummary(), // Call a function that generates the summary
                    icon: Icons.inventory,
                    color: Colors.orange, // Change to Red if out-of-stock exists
                  ),

                ],
              ),

              const SizedBox(height: 24.0),

              // Monthly Sales Chart
              _buildSectionHeader('Monthly Sales'),
              const SizedBox(height: 8.0),
              Container(
                height: 250.0,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _monthlySalesData.isEmpty
                    ? const Center(child: Text('No sales data available'))
                    : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _monthlySalesData.map((data) => data['sales'] as double).reduce((max, value) => max > value ? max : value) * 1.2,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < _monthlySalesData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _monthlySalesData[value.toInt()]['month'].toString().substring(0, 3),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '₹${(value / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: _monthlySalesData.map((data) => data['sales'] as double).reduce((max, value) => max > value ? max : value) / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: List.generate(
                      _monthlySalesData.length,
                          (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: _monthlySalesData[index]['sales'] as double,
                            color: Colors.blue,
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // Recent Orders
              _buildSectionHeader('Recent Orders'),
              const SizedBox(height: 8.0),
              _orders.isEmpty
                  ? _buildEmptyState('No orders yet')
                  : Column(
                children: _orders
                    .sublist(0, _orders.length > 5 ? 5 : _orders.length)
                    .map((order) => _buildOrderCard(order))
                    .toList(),
              ),

              if (_orders.length > 5)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: TextButton(
                    onPressed: () {
                      // Navigate to all orders screen
                    },
                    child: const Text('View all orders →'),
                  ),
                ),

              const SizedBox(height: 24.0),

              // Inventory Management
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Inventory Management'),
                  const SizedBox(height: 12.0), // Adds space after the header
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>  StockManagementScreen(),
                          fullscreenDialog: true, // Optional: Opens as a full-screen dialog
                        ),
                      );

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Manage Stock'),
                  ),

                ],
              ),

              const SizedBox(height: 8.0),
              _products.isEmpty
                  ? _buildEmptyState('No products yet')
                  : Column(
                children: _products
                    .sublist(0, _products.length > 5 ? 5 : _products.length)
                    .map((product) => _buildProductCard(product))
                    .toList(),
              ),

              if (_products.length > 5)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: TextButton(
                    onPressed: () {
                      // Navigate to all products screen
                    },
                    child: const Text('View all products →'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  String getLowStockSummary() {
    List<String> lowStockList = [];

    for (var product in _products) {
      if (product.containsKey('colors') && product['colors'] is List) {
        for (var color in product['colors']) {
          if (color is Map && color.containsKey('sizes') && color['sizes'] is List) {
            for (var size in color['sizes']) {
              if (size is Map && size.containsKey('stock')) {
                int sizeStock = (size['stock'] as num).toInt();
                if (sizeStock < 10) {
                  lowStockList.add("${color['colorName']} (Size ${size['size']}) - ${sizeStock <= 0 ? 'Out of stock' : 'Low stock'}");
                }
              }
            }
          }
        }
      }
    }

    return lowStockList.isNotEmpty ? lowStockList.join("\n") : "All sizes in stock"; // Shows list or default message
  }


  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.0,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    String orderStatus = order.containsKey('order_status') ? order['order_status'] : 'Processing';
    String paymentStatus = order.containsKey('payment_status') ? order['payment_status'] : 'Unknown';
    double price = order.containsKey('price') ? (order['price'] as num).toDouble() : 0.0;
    String productName = order.containsKey('product_name') ? order['product_name'] : 'Product';

    DateTime? createdAt;
    if (order.containsKey('created_at') && order['created_at'] != null) {
      createdAt = (order['created_at'] as Timestamp).toDate();
    }

    Color statusColor;
    switch (orderStatus.toLowerCase()) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2, // Allows some flexibility
                      softWrap: true,
                    ),
                    const SizedBox(height: 4.0),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Order #${order['id'].toString().substring(0, 8)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      currencyFormat.format(price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    paymentStatus,
                    style: TextStyle(
                      color: paymentStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14.0,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        createdAt != null
                            ? DateFormat('MMM d, yyyy').format(createdAt)
                            : 'Unknown date',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  orderStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildProductCard(Map<String, dynamic> product) {
    String name = product.containsKey('name') ? product['name'] : 'Product';
    double price = 0.0;
    if (product.containsKey('price') && product['price'] != null) {
      price = (product['price'] as num).toDouble();
    }

    int stock = 0;
    if (product.containsKey('stock') && product['stock'] != null) {
      stock = (product['stock'] as num).toInt();
    } else if (product.containsKey('metadata') &&
        product['metadata'] != null &&
        product['metadata'].containsKey('totalStock')) {
      stock = (product['metadata']['totalStock'] as num).toInt();
    }

    int discount = 0;
    if (product.containsKey('discount') && product['discount'] != null) {
      discount = (product['discount'] as num).toInt();
    }

    String status = product.containsKey('status') ? product['status'] : 'inactive';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns top of columns
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Price: ${currencyFormat.format(price)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end, // Aligns stock info to the right
                children: [
                  Text(
                    "Stock: ${getTotalStock(product)}",
                    style: TextStyle(
                      color: getTotalStock(product) <= 0 ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5), // Spacing before color-wise stock info

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end, // Aligns color stock status
                    children: (product['colors'] as List).map<Widget>((color) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 3.0), // Add spacing
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end, // Aligns text
                          children: [
                            Text(
                              '${color['colorName']}:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            // Iterate over sizes within each color
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: (color['sizes'] as List).map<Widget>((size) {
                                int sizeStock = (size['stock'] as num).toInt();
                                return Row(
                                  mainAxisSize: MainAxisSize.min, // Keeps row compact inside Column
                                  children: [
                                    Text(
                                      'Size ${size['size']} - ',
                                      style: TextStyle(fontSize: 12.0),
                                    ),
                                    Text(
                                      sizeStock <= 0
                                          ? 'Out of stock'
                                          : sizeStock < 10
                                          ? 'Low stock'
                                          : 'In stock',
                                      style: TextStyle(
                                        color: sizeStock <= 0
                                            ? Colors.red
                                            : sizeStock < 10
                                            ? Colors.orange
                                            : Colors.green,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discount: $discount%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: status.toLowerCase() == 'active'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status.toLowerCase() == 'active' ? Colors.green : Colors.grey,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox,
              size: 48.0,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16.0),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}