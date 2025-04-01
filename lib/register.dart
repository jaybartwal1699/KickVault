import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedRole = "customer"; // Default role

  // Email regex pattern
  final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _phoneError;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In canceled");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if the user document already exists
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Create new user document if it doesn't exist
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'role': _selectedRole,
            'profile_image': user.photoURL ?? '',
            'address': {
              'line1': '',
              'line2': '',
              'city': '',
              'state': '',
              'zipcode': '',
            },
            'created_at': FieldValue.serverTimestamp(),
            'favorites': [],
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-in successful!')),
          );
        }

        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-in failed: $e')),
      );
    }
  }



  Future<void> registerUser() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String phone = _phoneController.text.trim();

    // Reset previous error messages
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _phoneError = null;
    });

    // Validate fields
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Please enter your name.';
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email address.';
      });
      return;
    }
    if (!_emailRegExp.hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Please enter your password.';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters long.';
      });
      return;
    }

    if (phone.isEmpty) {
      setState(() {
        _phoneError = 'Please enter your phone number.';
      });
      return;
    }
    if (phone.length < 10) {
      setState(() {
        _phoneError = 'Phone number must be at least 10 digits.';
      });
      return;
    }

    try {
      // Create user with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': _selectedRole,
        'profile_image': '',
        'address': {
          'line1': '',
          'line2': '',
          'city': '',
          'state': '',
          'zipcode': '',
        },
        'created_at': FieldValue.serverTimestamp(),
        'favorites': [],
        'is_verified':'false',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212), // AppBar color
        elevation: 0,
        toolbarHeight: 5, // Make the AppBar smaller (default is 56)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Create an Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person, color: Colors.white),
                hintText: "Full Name",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _nameError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email, color: Colors.white),
                hintText: "Email",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_emailError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _emailError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock, color: Colors.white),
                hintText: "Password",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_passwordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _passwordError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, color: Colors.white),
                hintText: "Phone",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_phoneError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _phoneError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              "Select Role:",
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            DropdownButton<String>(
              value: _selectedRole,
              dropdownColor: const Color(0xFF1E1E1E), // Dropdown background color
              style: const TextStyle(color: Colors.white), // Dropdown item text color
              items: const [
                DropdownMenuItem(
                  value: "customer",
                  child: Text("Customer"),
                ),
                DropdownMenuItem(
                  value: "seller",
                  child: Text("Seller"),
                ),
                // DropdownMenuItem(    //Admin commented
                //   value: "admin",
                //   child: Text("Admin"),
                // ),
                DropdownMenuItem(
                  value: "delivery_partner",
                  child: Text("Delivery Partner"),
                )
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    height: 24.0,
                    width: 24.0,
                  ),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 16), // Adds spacing between elements

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "OR",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 16), // Adds spacing between elements

                ElevatedButton(
                  onPressed: registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text(
                "Already have an account? Login",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
