import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'seller_drawer.dart';

class SellerSalesDashboard extends StatefulWidget {
  @override
  _SellerSalesDashboardState createState() => _SellerSalesDashboardState();
}

class _SellerSalesDashboardState extends State<SellerSalesDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalProductsSold = 0;
  double totalEarnings = 0;
  int totalOrders = 0;
  int totalCustomers = 0;
  Map<String, int> categorySales = {};
  Map<String, String> categoryNames = {};

  @override
  void initState() {
    super.initState();
    fetchSalesData();
  }

  Future<void> fetchSalesData() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String sellerId = user.uid;
    QuerySnapshot ordersSnapshot = await _firestore
        .collection('orders')
        .where('seller_id', isEqualTo: sellerId)
        .where('order_status', isEqualTo: 'Delivered')
        .get();

    int productsSold = 0;
    double earnings = 0;
    int ordersCount = ordersSnapshot.docs.length;
    Set<String> customers = {};
    Map<String, int> categoryCount = {};

    for (var doc in ordersSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      productsSold++;
      earnings += (data['price'] as num).toDouble();
      customers.add(data['user_id']);

      String categoryId = data['category_id'] ?? "Unknown";
      categoryCount[categoryId] = (categoryCount[categoryId] ?? 0) + 1;
    }

    // Fetch category names
    for (var categoryId in categoryCount.keys) {
      var categoryDoc = await _firestore.collection('Categories').doc(categoryId).get();
      if (categoryDoc.exists) {
        categoryNames[categoryId] = categoryDoc['name'] ?? 'Unknown Category';
      }
    }

    setState(() {
      totalProductsSold = productsSold;
      totalEarnings = earnings;
      totalOrders = ordersCount;
      totalCustomers = customers.length;
      categorySales = categoryCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales & Data Analysis \nDashboard',style: TextStyle(fontSize: 18),),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      //
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DataTable(
              columns: [
                DataColumn(label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                DataRow(cells: [DataCell(Text('Total Products Sold')), DataCell(Text('$totalProductsSold'))]),
                DataRow(cells: [DataCell(Text('Total Earnings')), DataCell(Text('₹$totalEarnings'))]),
                DataRow(cells: [DataCell(Text('Total Orders')), DataCell(Text('$totalOrders'))]),
                DataRow(cells: [DataCell(Text('Total Customers')), DataCell(Text('$totalCustomers'))]),
              ],
            ),
            SizedBox(height: 20),
            Text('Category-wise Sales:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: categorySales.entries.map((entry) {
                    return BarChartGroupData(
                      x: categoryNames.containsKey(entry.key) ? categoryNames[entry.key]!.hashCode : 0,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.blue,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(categoryNames.entries.firstWhere(
                                  (element) => element.value.hashCode == value.toInt(),
                              orElse: () => MapEntry("", "")).value);
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
