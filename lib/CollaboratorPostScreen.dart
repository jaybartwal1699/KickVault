import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CollaboratorPostScreen extends StatefulWidget {
  @override
  _CollaboratorPostScreenState createState() => _CollaboratorPostScreenState();
}

class _CollaboratorPostScreenState extends State<CollaboratorPostScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  List<XFile>? _imageFiles = [];
  String userName = '';
  String userEmail = '';
  String profileImage = '';

  // Seller selection variables
  List<Map<String, dynamic>> sellers = [];
  Map<String, dynamic>? selectedSeller;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchSellers();
  }

  // Fetch user data from Firestore
  Future<void> fetchUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc.get('name') ?? '';
            userEmail = userDoc.get('email') ?? '';
            profileImage = userDoc.get('profile_image') ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Fetch sellers from Firestore
  Future<void> fetchSellers() async {
    try {
      final QuerySnapshot sellerSnapshot = await FirebaseFirestore.instance
          .collection('seller_details')
          .get();

      setState(() {
        sellers = sellerSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'store_name': data['business_details']?['store_name'] ?? '',
            'logo_url': data['store_profile']?['logo_url'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching sellers: $e');
    }
  }

  // Pick images from gallery
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFiles = pickedFiles;
      });
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImageToStorage(File imageFile) async {
    try {
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child("collaboration_posts/$imageName");
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      Fluttertoast.showToast(msg: "Error uploading image: $e");
      return '';
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are permanently denied.')),
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check if GeocodingPlatform is available and safely get the location name
      final geocoding = GeocodingPlatform.instance;
      if (geocoding != null) {
        List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Set the location name in the text field
          _locationController.text = '${place.name}, ${place.locality}, ${place.country}';

          // Show the location name in a snackbar
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Current Location: ${place.name}, ${place.locality}, ${place.country}'),
          //   ),
          // );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geocoding is unavailable.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Submit collaboration post
  Future<void> _submitCollaborationPost() async {
    if (selectedSeller == null) {
      Fluttertoast.showToast(msg: "Please select a seller");
      return;
    }

    if (_imageFiles!.isEmpty) {
      Fluttertoast.showToast(msg: "Please select at least one image");
      return;
    }

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Upload images
        List<String> imageUrls = [];
        for (var imageFile in _imageFiles!) {
          String imageUrl = await _uploadImageToStorage(File(imageFile.path));
          if (imageUrl.isNotEmpty) {
            imageUrls.add(imageUrl);
          }
        }

        // Create collaboration post
        await FirebaseFirestore.instance.collection('collaboration posts').add({
          'user_id': currentUser.uid,
          'user_name': userName,
          'user_email': userEmail,
          'user_profile_image': profileImage,
          'seller_id': selectedSeller!['id'],
          'seller_name': selectedSeller!['name'],
          'store_name': selectedSeller!['store_name'],
          'store_logo': selectedSeller!['logo_url'],
          'description': _descriptionController.text,
          'location': _locationController.text,
          'images': imageUrls,
          'created_at': FieldValue.serverTimestamp(),
          'is_collaboration': true,
          'verification_status': 'unverified',
          'likes': [],
          'comments': {},
        });

        Fluttertoast.showToast(
          msg: "Collaboration post submitted for verification!",
          backgroundColor: Colors.yellow,
        );

        Navigator.pop(context);
      }
    } catch (e) {
      print('Error submitting collaboration post: $e');
      Fluttertoast.showToast(
        msg: "Error creating post. Please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding inside the container
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6), // Solid background color for the container
            borderRadius: BorderRadius.circular(20), // Rounded edges
          ),
          child:  Text(
            'Create Collaboration Post',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.teal,// Dark teal background color
        foregroundColor: Colors.black, // Color of the AppBar icons
        elevation: 1, // Set elevation for shadow effect
      ),



      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(profileImage),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 20),

            // Seller selection dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                hint: Text("Select Seller for Collaboration"),
                value: selectedSeller,
                items: sellers.map((seller) {
                  return DropdownMenuItem(
                    value: seller,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.transparent, // Ensure no background color
                          backgroundImage: seller['logo_url'] != null && seller['logo_url'].isNotEmpty
                              ? NetworkImage(seller['logo_url'])
                              : null,
                          child: seller['logo_url'] == null || seller['logo_url'].isEmpty
                              ? Icon(Icons.store, size: 15, color: Colors.grey) // Fallback icon
                              : null,
                        ),
                        SizedBox(width: 8),
                        Expanded( // Ensure text does not overflow
                          child: Text(
                            seller['store_name'],
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis, // Prevents text overflow
                          ),
                        ),
                      ],
                    ),

                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSeller = value;
                  });
                },
              ),
            ),
            SizedBox(height: 20),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: "Write your post description...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),

            // Location
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: "Add location",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: _getCurrentLocation,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Image picker
            Container(
              alignment: Alignment.center, // Ensures the button is centered properly
              padding: EdgeInsets.symmetric(vertical: 10), // Adds spacing
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: Icon(Icons.photo_library, color: Colors.white),
                label: Text("Add Photos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24), // Better button sizing
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  elevation: 4, // Adds a shadow for better UI
                ),
              ),
            ),

            SizedBox(height: 10),

            // Selected images
            if (_imageFiles!.isNotEmpty)
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Image.file(
                        File(_imageFiles![index].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitCollaborationPost,
                child: Text("Submit Collaboration Post"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}