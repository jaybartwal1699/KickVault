import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'CustomerDrawer.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'About Screen     ',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.teal[900], // Solid color
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      drawer: CustomerDrawer(currentScreen: 'AboutScreen'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "KickVault",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                "Your Ultimate Destination for Buying & Selling Shoes",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Project Objectives:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 10),
            Column(
              children: [
                InfoCard("User-Friendly Shopping Experience", "Allow users to browse and buy shoes easily."),
                InfoCard("Seller and Product Management", "Multiple sellers can list and manage their products, with an admin panel for control."),
                InfoCard("Community Engagement", "A social screen lets users display and interact with shoe collections."),
                InfoCard("Secure and Scalable Platform", "Ensures secure transactions and scalability for future growth."),
              ],
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Colors.teal.shade50,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "KickVault provides a seamless shopping experience with secure authentication and a responsive design for all devices.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Support & Contact Information:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("For assistance, please contact us:", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    Text("• Email: support@kickvault.com", style: TextStyle(fontSize: 16)),
                    Text("• Phone: +91 953 707 6012", style: TextStyle(fontSize: 16)),
                    Text("• Website: www.kickvault.com", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  InfoCard(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 5),
            Text(description, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}