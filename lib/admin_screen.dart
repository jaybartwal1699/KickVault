import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kickvault/ComplaintManagementScreen.dart';
import 'package:kickvault/SellerManagementScreen.dart';

import 'package:intl/intl.dart';
import 'AdminManageOrdersScreen.dart';
import 'AddCategory.dart';
import 'AdminApproveProductsScreen.dart';
import 'AdminAssignDeliveryScreen.dart';
import 'AdminPostManagementScreen.dart';
import 'AdminSeller_Approve.dart';
import 'AdminVerifyDeliveryPartnersScreen.dart';
import 'Admin_Drawer.dart';
import 'ManageCategories.dart';
import 'login.dart';

// Seller Data Model with improved structure
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class SellerData {
  final String name;
  final String storeName;
  final int totalProducts;
  final double totalSales;
  final int totalOrders;

  const SellerData({
    required this.name,
    this.storeName = 'Unknown Store',
    this.totalProducts = 0,
    this.totalSales = 0.0,
    this.totalOrders = 0,
  });
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Dashboard Metrics
  int totalSellers = 0;
  int totalDeliveryPartners = 0;
  int codOrders = 0;
  int onlineOrders = 0;
  double totalRevenue = 0.0;
  Map<String, SellerData> sellerData = {};
  Map<DateTime, double> salesByDate = {};

  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAdminData(); // Fetch all data at once
    });
  }

  // Main data fetching method
  Future<void> _fetchAdminData() async {
    try {
      setState(() {
        errorMessage = null;
        isLoading = true;
      });

      // Fetch all necessary collections in parallel
      final usersSnapshot = FirebaseFirestore.instance
          .collection('users')
          .get();

      final sellerDetailsSnapshot = FirebaseFirestore.instance
          .collection('seller_details')
          .get();

      final ordersSnapshot = FirebaseFirestore.instance
          .collection('orders')
          .get();

      // Wait for all queries to complete
      final results = await Future.wait([
        usersSnapshot,
        sellerDetailsSnapshot,
        ordersSnapshot,
      ]);

      // Process users data
      final usersResult = results[0] as QuerySnapshot;
      final sellerDetails = results[1] as QuerySnapshot;
      final ordersResult = results[2] as QuerySnapshot;

      // Count sellers and delivery partners
      int sellers = 0;
      int deliveryPartners = 0;

      for (var doc in usersResult.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final role = userData['role'] as String? ?? '';

        if (role == 'seller') {
          sellers++;
        } else if (role == 'delivery_partner') {
          deliveryPartners++;
        }
      }

      // Process seller details
      Map<String, SellerData> sellerDataMap = {};

      for (var doc in sellerDetails.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['user_id'] as String? ?? '';

        if (userId.isEmpty) continue;

        // Extract store details
        String sellerName = data['name'] as String? ?? 'Unknown';
        String storeName = 'Unknown Store';

        // Correctly navigate nested maps
        if (data.containsKey('business_details') &&
            data['business_details'] is Map<String, dynamic> &&
            data['business_details'].containsKey('store_name')) {
          storeName = data['business_details']['store_name'] as String? ?? 'Unknown Store';
        }

        // Initialize seller data
        sellerDataMap[userId] = SellerData(
          name: sellerName,
          storeName: storeName,
        );
      }

      // Process orders data
      Map<String, double> sellerSales = {};
      Map<DateTime, double> salesDateMap = {};
      double revenue = 0.0;
      int codCount = 0;
      int onlineCount = 0;

      for (var doc in ordersResult.docs) {
        final orderData = doc.data() as Map<String, dynamic>;

        // Extract key order data
        final sellerId = orderData['seller_id'] as String? ?? '';
        final price = (orderData['price'] as num?)?.toDouble() ?? 0.0;
        final paymentMethod = orderData['payment_method'] as String? ?? '';
        final timestamp = orderData['created_at'] as Timestamp?;

        // Update revenue and payment counts
        revenue += price;

        if (paymentMethod.toLowerCase() == 'cod') {
          codCount++;
        } else {
          onlineCount++;
        }

        // Update seller sales
        if (sellerId.isNotEmpty) {
          sellerSales[sellerId] = (sellerSales[sellerId] ?? 0.0) + price;

          // Update seller order count in sellerDataMap
          if (sellerDataMap.containsKey(sellerId)) {
            final existingData = sellerDataMap[sellerId]!;
            sellerDataMap[sellerId] = SellerData(
              name: existingData.name,
              storeName: existingData.storeName,
              totalProducts: existingData.totalProducts,
              totalSales: existingData.totalSales + price,
              totalOrders: existingData.totalOrders + 1,
            );
          }
        }

        // Update sales by date
        if (timestamp != null) {
          final date = timestamp.toDate();
          final monthKey = DateTime(date.year, date.month);
          salesDateMap[monthKey] = (salesDateMap[monthKey] ?? 0.0) + price;
        }
      }

      // Integrate seller sales data with seller details
      sellerSales.forEach((sellerId, sales) {
        if (sellerDataMap.containsKey(sellerId)) {
          final existingData = sellerDataMap[sellerId]!;
          sellerDataMap[sellerId] = SellerData(
            name: existingData.name,
            storeName: existingData.storeName,
            totalProducts: existingData.totalProducts,
            totalSales: sales, // Override with accumulated sales
            totalOrders: existingData.totalOrders,
          );
        }
      });

      // Update state with all processed data
      setState(() {
        totalSellers = sellers;
        totalDeliveryPartners = deliveryPartners;
        sellerData = sellerDataMap;
        salesByDate = salesDateMap;
        codOrders = codCount;
        onlineOrders = onlineCount;
        totalRevenue = revenue;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load admin data: ${e.toString()}';
        isLoading = false;
        print('⚠️ Admin data fetch error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(

        appBar: AppBar(title: Text('Admin Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: _fetchAdminData,
                child: Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Prevent navigating back to login screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => AdminScreen()));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'Admin Dashboard',
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
        drawer: kIsWeb ? null : const Admin_Drawer(currentScreen: 'Admin Dashboard'),
        body: Row(
          children: [
            if (kIsWeb)
              const WebAdminSidebar(currentScreen: 'admin_screen'),
            Expanded(
              child: _buildDashboardContent(),
            ),

          ],

        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black12, Colors.white38],
        ),
      ),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 10),

            // Display web-only features note for mobile users
            if (!kIsWeb)
              _buildWebOnlyFeaturesNote(),

            const SizedBox(height: 20),
            _buildSummaryCards(),
            // Only show graphs when on web platform
            if (kIsWeb) ...[
              const SizedBox(height: 20),
              _buildSellerSalesGraph(),
              const SizedBox(height: 20),
              _buildMonthlySalesGraph(),
              const SizedBox(height: 20),
              _buildPaymentMethodsChart(),
            ],
            const SizedBox(height: 20),
            _buildAdminModules(),
          ],
        ),
      ),
    );
  }

// Add this new method to create the web-only features note
  Widget _buildWebOnlyFeaturesNote() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Some features (sales graphs, seller management, order management, and social feed management) are only available in the web version.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return const Text(
      "Welcome to Kick-vault Admin Dashboard!",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        _buildSummaryCard("Total Sellers", totalSellers.toString()),
        _buildSummaryCard("Total Delivery Partners", totalDeliveryPartners.toString()),
        _buildSummaryCard("COD Orders", codOrders.toString()),
        _buildSummaryCard("Online Orders", onlineOrders.toString()),
        _buildSummaryCard("Total Revenue", '₹${totalRevenue.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerSalesGraph() {
    if (sellerData.isEmpty) {
      return Center(child: Text("No seller sales data available"));
    }

    // Sort sellers by sales value
    List<MapEntry<String, SellerData>> sortedSellers = sellerData.entries.toList();
    sortedSellers.sort((a, b) => b.value.totalSales.compareTo(a.value.totalSales));

    // Take top 5 sellers only
    if (sortedSellers.length > 5) {
      sortedSellers = sortedSellers.take(5).toList();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Top Seller Sales",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(1)}K',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < sortedSellers.length) {
                            // Truncate long store names
                            String displayName = sortedSellers[index].value.storeName;
                            if (displayName.length > 10) {
                              displayName = displayName.substring(0, 7) + '...';
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Transform.rotate(
                                angle: 0.3, // ~15 degrees for slight angle
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 60,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  barGroups: List.generate(sortedSellers.length, (index) {
                    final sellerSale = sortedSellers[index].value.totalSales;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: sellerSale,
                          color: Colors.blue.shade700,
                          width: 20,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: sellerSale * 1.1,
                            color: Colors.transparent,
                          ),
                        )
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final seller = sortedSellers[group.x.toInt()].value;
                        String sellerName = seller.storeName;
                        String amount = '₹${NumberFormat('#,##,###').format(seller.totalSales)}';
                        String orders = '${seller.totalOrders} orders';
                        return BarTooltipItem(
                          '$sellerName\n$amount\n$orders',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  maxY: sortedSellers.isEmpty
                      ? 100
                      : sortedSellers.map((e) => e.value.totalSales).reduce((a, b) => a > b ? a : b) * 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Add a summary of total sales
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // Prevents overflow
                    child: Text(
                      "Total Sales: ₹${NumberFormat('#,##,###').format(totalRevenue)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis, // Handles long text
                    ),
                  ),
                  SizedBox(width: 8), // Adds space between texts
                  Expanded(
                    child: Text(
                      "Top Seller: ${sortedSellers.isEmpty ? 'None' : sortedSellers.first.value.storeName}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis, // Handles long text
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySalesGraph() {
    if (salesByDate.isEmpty) {
      return Center(child: Text("No monthly sales data available"));
    }

    // Sort dates in chronological order
    List<DateTime> sortedDates = salesByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Monthly Sales Trend",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(sortedDates.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          salesByDate[sortedDates[index]] ?? 0.0,
                        );
                      }),
                      isCurved: true,
                      color: Colors.green.shade600,
                      barWidth: 4,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= sortedDates.length) return Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM yyyy').format(sortedDates[index]),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text('₹${(value / 1000).toStringAsFixed(1)}K');
                        },
                        reservedSize: 50,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(

                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = sortedDates[spot.x.toInt()];
                          final formattedDate = DateFormat('MMMM yyyy').format(date);
                          final value = NumberFormat('₹#,##,###').format(spot.y);
                          return LineTooltipItem(
                            '$formattedDate\n$value',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Add monthly trend summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Average Monthly Sales: \n₹${NumberFormat('#,##,###').format(salesByDate.values.reduce((a, b) => a + b) / salesByDate.length)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New payment methods chart
  Widget _buildPaymentMethodsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Methods",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.blue,
                            value: onlineOrders.toDouble(),
                            title: 'Online',
                            radius: 80,
                            titleStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: codOrders.toDouble(),
                            title: 'COD',
                            radius: 80,
                            titleStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Online', Colors.blue,
                            '${onlineOrders} (${(onlineOrders / (onlineOrders + codOrders) * 100).toStringAsFixed(1)}%)'),
                        const SizedBox(height: 16),
                        _buildLegendItem('COD', Colors.orange,
                            '${codOrders} (${(codOrders / (onlineOrders + codOrders) * 100).toStringAsFixed(1)}%)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminModules() {
    return Column(
      children: [
        _buildAdminModule(
            title: "Seller Approvals",
            icon: Icons.person_search,
            route: const AdminSeller_Approve()
        ),
        _buildAdminModule(
            title: "Approve Products",
            icon: Icons.check_circle,
            route: AdminApproveProductsScreen()
        ),
        _buildAdminModule(
            title: "Manage Categories",
            icon: Icons.category,
            route: const ManageCategories()
        ),
        _buildAdminModule(
            title: "Add Category",
            icon: Icons.add_box,
            route: const AddCategory()
        ),
        _buildAdminModule(
            title: "Verify Delivery Partners",
            icon: Icons.manage_history_sharp,
            route: AdminVerifyDeliveryPartnersScreen()
        ),
        _buildAdminModule(
            title: "Transit Orders",
            icon: Icons.local_shipping,
            route: AdminAssignDeliveryScreen()
        ),
        _buildAdminModule(
            title: "Manage Orders",
            icon: Icons.bookmark_border,
            route: AdminManageOrdersScreen(),
            webOnly: true
        ),
        _buildAdminModule(
            title: "View Sellers",
            icon: Icons.man_2_sharp,
            route: SellerManagementScreen(),
            webOnly: true
        ),
        _buildAdminModule(
            title: "Manage Social Feeds",
            icon: Icons.signpost,
            route: AdminPostManagementScreen(),
            webOnly: true
        ),
        _buildAdminModule(
            title: "Manage Complaint",
            icon: Icons.event_note,
            route: ComplaintManagementScreen(),
            webOnly: true
        ),
      ],
    );
  }

  Widget _buildAdminModule({
    required String title,
    required IconData icon,
    required Widget route,
    bool webOnly = false
  }) {
    // Skip rendering this module if it's web-only and we're not on web
    if (webOnly && !kIsWeb) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () =>
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => route),
            ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 50, color: Colors.black),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Existing WebAdminSidebar class remains unchanged
class WebAdminSidebar extends StatelessWidget {
  final String currentScreen;

  const WebAdminSidebar({
    Key? key,
    required this.currentScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      color: Colors.black.withOpacity(0.9), // Sidebar background color
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSidebarItem(
            context,
            title: "Admin Dashboard",
            icon: Icons.dashboard,
            screen: AdminScreen(),
            isSelected: currentScreen == 'Admin Dashboard',
          ),
          _buildSidebarItem(
            context,
            title: "Seller Approvals",
            icon: Icons.person_search,
            screen: AdminSeller_Approve(),
            isSelected: currentScreen == 'Seller Approval',
          ),
          _buildSidebarItem(
            context,
            title: "Approve Products",
            icon: Icons.check_circle,
            screen: AdminApproveProductsScreen(),
            isSelected: currentScreen == 'Approve Products',
          ),
          _buildSidebarItem(
            context,
            title: "Manage Categories",
            icon: Icons.category,
            screen: ManageCategories(),
            isSelected: currentScreen == 'Manage Category',
          ),
          _buildSidebarItem(
            context,
            title: "Add Category",
            icon: Icons.add_box,
            screen: AddCategory(),
            isSelected: currentScreen == 'Add New Category',
          ),
          _buildSidebarItem(
            context,
            title: "Manage Orders",
            icon: Icons.shopping_cart,
            screen: AdminManageOrdersScreen(),
            isSelected: currentScreen == 'Manage Orders',
          ),

          _buildSidebarItem(
            context,
            title: "Verify Delivery Partners",
            icon: Icons.manage_history_sharp,
            screen: AdminVerifyDeliveryPartnersScreen(),
            isSelected: currentScreen == 'Verify Delivery Partners',
          ),
          _buildSidebarItem(
            context,
            title: "Transit Orders",
            icon: Icons.local_shipping,
            screen: AdminAssignDeliveryScreen(),
            isSelected: currentScreen == 'Transit Orders',
          ),
          const Divider(color: Colors.white54), // Separator line
          _buildSidebarItem(
            context,
            title: "Logout",
            icon: Icons.logout,
            screen: LoginScreen(),
            iconColor: Colors.red,
            textColor: Colors.red,
            isSelected: false, // Logout is never "selected"
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Widget screen,
        Color iconColor = Colors.white,
        Color textColor = Colors.white,
        bool isSelected = false,
      }) {
    // Create the background color for the selected item
    final Color backgroundColor = isSelected
        ? Colors.white.withOpacity(0.2)
        : Colors.transparent;

    // Make text and icon more prominent when selected
    final Color activeIconColor = isSelected ? Colors.white : iconColor;
    final Color activeTextColor = isSelected ? Colors.white : textColor;
    final FontWeight fontWeight = isSelected ? FontWeight.bold : FontWeight.normal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: activeTextColor,
            fontWeight: fontWeight,
          ),
        ),
        leading: Icon(icon, color: activeIconColor),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}



//
// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'AddCategory.dart';
// import 'AdminApproveProductsScreen.dart';
// import 'AdminSeller_Approve.dart';
// import 'Admin_Drawer.dart';
// import 'ManageCategories.dart';
//
// class AdminScreen extends StatefulWidget {
//   const AdminScreen({super.key});
//
//   @override
//   _AdminScreenState createState() => _AdminScreenState();
// }
//
// class _AdminScreenState extends State<AdminScreen> {
//   int _selectedIndex = 0; // Track selected tab
//   final List<Widget> _pages = [
//     AdminApproveProductsScreen(),
//     AdminSeller_Approve(),
//     ManageCategories(),
//     AddCategory(),
//   ];
//
//   // Function to handle bottom navigation item selection
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(kToolbarHeight),
//         child: ClipRect(
//           child: Stack(
//             children: [
//               // Linear Gradient with additional colors: dark blue and light blue
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Color(0xFFC3A5E7), Color(0xFF9F84C4), Color(0xFF7A53A9),  // Light blue color
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 ),
//               ),
//               // BackdropFilter to add glass effect
//               BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//                 child: Container(
//                   color: Colors.black.withOpacity(0), // Ensure no color overlay
//                   child: AppBar(
//                     title: const Text('Admin DashBoard'),
//                     backgroundColor: Colors.blue.withOpacity(0.1), // Adjust transparency
//                     elevation: 0,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       drawer: const Admin_Drawer(currentScreen: 'Admin Screen'),
//       body: _pages[_selectedIndex],  // Display the selected page based on the index
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,  // Highlight the selected tab
//         onTap: _onItemTapped,  // Call the function when a tab is tapped
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.check_circle),
//             label: 'Approve Products',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_search),
//             label: 'Seller Approvals',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.category),
//             label: 'Manage Categories',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_box),
//             label: 'Add Category',
//           ),
//         ],
//         backgroundColor: Colors.blueGrey.withOpacity(0.1),
//         selectedItemColor: Colors.blueAccent,
//         unselectedItemColor: Colors.white,
//       ),
//     );
//   }
// }
