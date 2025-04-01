import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'CustomerDrawer.dart';

class CustomerProfile extends StatefulWidget {
  const CustomerProfile({Key? key}) : super(key: key);

  @override
  _CustomerProfileState createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _picker = ImagePicker();

  Map<String, dynamic> userData = {
    'name': '',
    'email': '',
    'phone': '',
    'profile_image': '',
    'address': {
      'line1': '',
      'line2': '',
      'city': '',
      'state': '',
      'zipcode': '',
    }
  };

  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _isDataFetched = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userData = {
              'name': data['name'] ?? '',
              'email': data['email'] ?? '',
              'phone': data['phone'] ?? '',
              'profile_image': data['profile_image'] ?? '',
              'address': {
                'line1': data['address']?['line1'] ?? '',
                'line2': data['address']?['line2'] ?? '',
                'city': data['address']?['city'] ?? '',
                'state': data['address']?['state'] ?? '',
                'zipcode': data['address']?['zipcode'] ?? '',
              }
            };
            _isDataFetched = true;
          });
          print('Fetched User Data: $userData'); // Debug print
        } else {
          setState(() {
            _isDataFetched = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No user data found. Please fill in your details.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching user data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImage(File image) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${currentUser.uid}.jpg');
        await storageRef.putFile(image);
        String imageUrl = await storageRef.getDownloadURL();

        setState(() {
          userData['profile_image'] = imageUrl;
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'profile_image': imageUrl});
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateUserData() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);
      try {
        final formData = _formKey.currentState!.value;
        final User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          // Create the update data structure
          final updatedData = {
            'name': formData['name'],
            'email': formData['email'],
            'phone': formData['phone'],
            'address': {
              'line1': formData['addressLine1'],
              'line2': formData['addressLine2'],
              'city': formData['city'],
              'state': formData['state'],
              'zipcode': formData['zipcode'],
            },
          };

          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set(updatedData, SetOptions(merge: true));

          // Handle image upload if new image was picked
          if (_pickedImage != null) {
            await _uploadImage(_pickedImage!);
          }

          // Update local state
          setState(() {
            userData = {
              ...userData,
              ...updatedData,
            };
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _pickedImage != null
                  ? FileImage(_pickedImage!)
                  : (userData['profile_image']?.isNotEmpty == true
                  ? CachedNetworkImageProvider(userData['profile_image']!)
                  : null) as ImageProvider?,
              child: _pickedImage == null && userData['profile_image']?.isEmpty != false
                  ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).cardColor.withOpacity(0.7),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _pickImage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String name,
    required String label,
    required IconData icon,
    List<String? Function(String?)>? validators,
    TextInputType? keyboardType,
  }) {
    // Get initial value based on field name
    String initialValue = '';

    switch (name) {
      case 'name':
        initialValue = userData['name'] ?? '';
        break;
      case 'email':
        initialValue = userData['email'] ?? '';
        break;
      case 'phone':
        initialValue = userData['phone'] ?? '';
        break;
      case 'addressLine1':
        initialValue = userData['address']?['line1'] ?? '';
        break;
      case 'addressLine2':
        initialValue = userData['address']?['line2'] ?? '';
        break;
      case 'city':
        initialValue = userData['address']?['city'] ?? '';
        break;
      case 'state':
        initialValue = userData['address']?['state'] ?? '';
        break;
      case 'zipcode':
        initialValue = userData['address']?['zipcode'] ?? '';
        break;
      default:
        initialValue = '';
    }

    print('Field $name initial value: $initialValue'); // Debug print

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: FormBuilderTextField(
        name: name,
        initialValue: initialValue,
        enabled: _isDataFetched,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        validator: FormBuilderValidators.compose(
          validators ?? [FormBuilderValidators.required()],
        ),
        keyboardType: keyboardType,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    _isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Profile ',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.teal[900], // Solid color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: CustomerDrawer(currentScreen: 'Profile'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.tealAccent.withOpacity(0.3), // Light Teal Accent with transparency
              Colors.teal, // Solid Teal
            ],

          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileImage(),
                SizedBox(height: 24.0),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildFormField(
                          name: 'name',
                          label: 'Full Name',
                          icon: Icons.person,
                          validators: [
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(2),
                          ],
                        ),
                        _buildFormField(
                          name: 'email',
                          label: 'Email',
                          icon: Icons.email,
                          validators: [
                            FormBuilderValidators.required(),
                            FormBuilderValidators.email(),
                          ],
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _buildFormField(
                          name: 'phone',
                          label: 'Phone',
                          icon: Icons.phone,
                          validators: [
                            FormBuilderValidators.required(),
                            FormBuilderValidators.numeric(),
                          ],
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildFormField(
                          name: 'addressLine1',
                          label: 'Address Line 1',
                          icon: Icons.home,
                        ),
                        _buildFormField(
                          name: 'addressLine2',
                          label: 'Address Line 2',
                          icon: Icons.home,
                        ),
                        _buildFormField(
                          name: 'city',
                          label: 'City',
                          icon: Icons.location_city,
                        ),
                        _buildFormField(
                          name: 'state',
                          label: 'State',
                          icon: Icons.map,
                        ),
                        _buildFormField(
                          name: 'zipcode',
                          label: 'Zipcode',
                          icon: Icons.pin_drop,
                          validators: [
                            FormBuilderValidators.required(),
                            FormBuilderValidators.numeric(),
                          ],
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_isDataFetched
                        ? null
                        : _updateUserData,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                        backgroundColor: Colors.black,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,

                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}