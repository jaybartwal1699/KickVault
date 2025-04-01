import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'CollaboratorPostScreen.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _hashtagController = TextEditingController();
  List<XFile>? _imageFiles = [];
  String userName = '';
  String userEmail = '';
  String user_profile_image = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
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
            user_profile_image = userDoc.get('profile_image') ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Pick images from the gallery
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFiles = pickedFiles;
      });
    }
  }

  // Upload the image to Firebase Storage
  Future<String> _uploadImageToStorage(File imageFile) async {
    try {
      // Get a reference to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;

      // Generate a unique file name based on the timestamp
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a reference to the 'posts_images' folder in Firebase Storage
      Reference ref = storage.ref().child("posts_images/$imageName");

      // Upload the file
      UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for the upload to complete and get the URL
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl; // Return the image URL
    } catch (e) {
      print("Error uploading image: $e");
      return ''; // Return an empty string if there's an error
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

  // Submit post data to Firestore
  void _submitPost() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Step 1: Upload all selected images to Firebase Storage and get their URLs
        List<String> imageUrls = [];
        for (var imageFile in _imageFiles!) {
          File file = File(imageFile.path);
          String imageUrl = await _uploadImageToStorage(file);
          if (imageUrl.isNotEmpty) {
            imageUrls.add(imageUrl);
          }
        }

        // Step 2: Save the post data in Firestore with an empty comments array
        final postRef = FirebaseFirestore.instance.collection('posts').doc();
        await postRef.set({
          'user_id': currentUser.uid,
          'user_name': userName,
          'user_email': userEmail,
          'user_profile_image': user_profile_image,
          'description': _descriptionController.text,
          'location': _locationController.text,
          'images': imageUrls, // Save the image URLs to Firestore
          'hashtags': _hashtagController.text.split(','),
          'created_at': FieldValue.serverTimestamp(),
          'likes': [], // Initialize 'likes' field as an empty array
          'comments': {}, // Initialize 'comments' field as an empty array
        });

        // Show success toast
        Fluttertoast.showToast(
          msg: "Post is live!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // After posting, navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error submitting post: $e');
    }
  }

  // Toggle like on a post
  void _toggleLike(String postId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();

      if (postSnapshot.exists) {
        List likes = List.from(postSnapshot['likes']);
        if (likes.contains(currentUser.uid)) {
          // Remove the user's ID if they already liked the post
          likes.remove(currentUser.uid);
        } else {
          // Add the user's ID to the likes array
          likes.add(currentUser.uid);
        }

        // Update the 'likes' field in Firestore
        await postRef.update({'likes': likes});
      }
    }
  }
  bool isCollabMode = false; // Track if in collaboration mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Default AppBar height
        child: Container(
          color: Colors.teal, // Set solid teal background color
          child: AppBar(
            backgroundColor: Colors.teal, // Ensure AppBar has the same solid background
            elevation: 0,
            title: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6), // Semi-transparent background
                borderRadius: BorderRadius.circular(20), // Rounded corners
              ),
              child: Text(
                isCollabMode ? "Collaborator Post" : "Create a Post",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            iconTheme: IconThemeData(color: Colors.white), // Change icon color for better contrast
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      isCollabMode = !isCollabMode;
                    });

                    if (isCollabMode) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CollaboratorPostScreen()),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: isCollabMode ? Colors.white : Colors.black54,
                    foregroundColor: isCollabMode ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(isCollabMode ? "Collab ON" : "Collab"),
                ),
              ),
            ],
          ),
        ),
      ),



      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info (Profile image + Name)
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(user_profile_image),
                    radius: 20,
                  ),
                  SizedBox(width: 10),
                  Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              SizedBox(height: 20),


              // Description text field
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                maxLines: 3,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Hashtags text field
              TextField(
                controller: _hashtagController,
                decoration: InputDecoration(
                  hintText: "Add hashtags (#) e.g. #fashion, #travel",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),

              // Location text field with current location button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: "Enter Location",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.my_location, color: Colors.black),
                    onPressed: _getCurrentLocation,
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Pick images button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.photo_library, color: Colors.white),
                  label: Text("Pick Images", style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Display selected images in a grid view
              _imageFiles != null && _imageFiles!.isNotEmpty
                  ? GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _imageFiles!.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_imageFiles![index].path),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              )
                  : Container(),
              SizedBox(height: 20),

              // Submit button
              Center(
                child: ElevatedButton(
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                  ),
                  child: Text("Post", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),



              ),

            ],
          ),
        ),
      ),
    );
  }
}
