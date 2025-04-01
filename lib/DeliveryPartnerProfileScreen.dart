import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'DeliveryPartnerDrawer.dart';

class DeliveryPartnerProfileScreen extends StatefulWidget {
  @override
  _DeliveryPartnerProfileScreenState createState() => _DeliveryPartnerProfileScreenState();
}

class _DeliveryPartnerProfileScreenState extends State<DeliveryPartnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _line1Controller = TextEditingController();
  final TextEditingController _line2Controller = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipcodeController = TextEditingController();
  File? _selectedImage;
  String? _documentImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    DocumentSnapshot docDetail = await FirebaseFirestore.instance.collection('Delivery_partner_detail').doc(uid).get();

    if (userDoc.exists) {
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        if (data['address'] != null) {
          _cityController.text = data['address']['city'] ?? '';
          _line1Controller.text = data['address']['line1'] ?? '';
          _line2Controller.text = data['address']['line2'] ?? '';
          _stateController.text = data['address']['state'] ?? '';
          _zipcodeController.text = data['address']['zipcode'] ?? '';
        }
      }
    }

    if (docDetail.exists) {
      Map<String, dynamic>? docData = docDetail.data() as Map<String, dynamic>?;
      if (docData != null) {
        _documentImageUrl = docData['document_image'];
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image, String uid) async {
    Reference storageRef = FirebaseStorage.instance.ref().child('delivery_docs/$uid.jpg');
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String? imageUrl = _documentImageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!, uid);
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': {
          'city': _cityController.text,
          'line1': _line1Controller.text,
          'line2': _line2Controller.text,
          'state': _stateController.text,
          'zipcode': _zipcodeController.text,
        },

      });

      if (imageUrl != null) {
        await FirebaseFirestore.instance.collection('Delivery_partner_detail').doc(uid).set({
          'uid': uid,
          'document_image': imageUrl,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Profile      ',
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
      drawer: const DeliveryPartnerDrawer(currentScreen: 'profile'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person, color: Colors.orange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone, color: Colors.orange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
                    ),
                    SizedBox(height: 20),
                    Text('Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    SizedBox(height: 10),
                    TextFormField(controller: _line1Controller, decoration: InputDecoration(labelText: 'Address Line 1', border: OutlineInputBorder())),
                    SizedBox(height: 10),
                    TextFormField(controller: _line2Controller, decoration: InputDecoration(labelText: 'Address Line 2', border: OutlineInputBorder())),
                    SizedBox(height: 10),
                    TextFormField(controller: _cityController, decoration: InputDecoration(labelText: 'City', border: OutlineInputBorder())),
                    SizedBox(height: 10),
                    TextFormField(controller: _stateController, decoration: InputDecoration(labelText: 'State', border: OutlineInputBorder())),
                    SizedBox(height: 10),
                    TextFormField(controller: _zipcodeController, decoration: InputDecoration(labelText: 'Zipcode', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          _documentImageUrl != null ? Image.network(_documentImageUrl!, height: 100) : (_selectedImage != null ? Image.file(_selectedImage!, height: 100) : Text('No document selected')),
                          ElevatedButton(onPressed: _pickImage, child: Text('Upload Government ID'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveProfile, child: Text('Save Profile', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
