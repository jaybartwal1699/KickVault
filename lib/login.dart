import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Add web client ID for web platform
    clientId: kIsWeb ? 'YOUR_WEB_CLIENT_ID_HERE' : null,
  );

  // Email regex pattern
  final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );
  @override
  void initState() {
    super.initState();
    // Prefill email field for web users
    if (kIsWeb) {
      _emailController.text = 'admin@kickvault.com';
    }
  }

  String? _emailError;
  String? _passwordError;
  bool isLoading = false;
  bool isGoogleLoading = false;

  // Login method with validation
  Future<void> loginUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Reset previous error messages
    setState(() {
      _emailError = null;
      _passwordError = null;
      isLoading = true;
    });

    // Validate email
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email address.';
        isLoading = false;
      });
      return;
    }
    if (!_emailRegExp.hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address.';
        isLoading = false;
      });
      return;
    }

    // Validate password
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Please enter your password.';
        isLoading = false;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters long.';
        isLoading = false;
      });
      return;
    }

    try {
      // Authenticate the user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('User authentication failed.');
      }

      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found in Firestore.');
      }

      String role = userDoc['role'];
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'seller') {
        Navigator.pushReplacementNamed(context, '/seller');
      } else if (role == 'delivery_partner') {
        Navigator.pushReplacementNamed(context, '/delivery');
      } else {
        Navigator.pushReplacementNamed(context, '/customer');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        setState(() {
          _passwordError = 'Incorrect password. Please try again.';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
              message: 'Sign-in aborted', code: 'ERROR_ABORTED_BY_USER');
        }
        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      throw FirebaseAuthException(
          message: 'Google sign-in failed: $e', code: 'SIGN_IN_FAILED');
    }
  }

  // Handles Google Login and User Navigation
  void handleGoogleLogin() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      UserCredential userCredential = await signInWithGoogle();
      await navigateUser(userCredential.user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google login failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isGoogleLoading = false;
      });
    }
  }

  Future<void> navigateUser(User? user) async {
    if (user == null) return;

    DocumentSnapshot userDoc =
    await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      throw Exception('User document not found in Firestore.');
    }

    String role = userDoc['role'];
    Map<String, String> roleRoutes = {
      'admin': '/admin',
      'seller': '/seller',
      'delivery_partner': '/delivery',
      'customer': '/customer'
    };

    Navigator.pushReplacementNamed(context, roleRoutes[role] ?? '/customer');
  }

  Future<void> sendPasswordResetEmail() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }
    if (!_emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset email sent! Check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> browseAsGuest() async {
    try {
      await _auth.signInAnonymously();
      Navigator.pushReplacementNamed(context, '/customer');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing guest mode: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;

    // Adjust layout based on platform and screen size
    final bool isWideScreen = kIsWeb && size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? size.width * 0.3 : 16.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/images/KicK Vault.png',
                  height: isWideScreen ? 280 : 228,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: isWideScreen ? 32 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Email TextField with web-specific styling
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
                  // Add hover effect for web
                  focusedBorder: kIsWeb
                      ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Colors.green, width: 2),
                  )
                      : null,
                ),
              ),
              if (_emailError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _emailError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              // Password TextField with web-specific styling
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
                  // Add hover effect for web
                  focusedBorder: kIsWeb
                      ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Colors.green, width: 2),
                  )
                      : null,
                ),
              ),
              if (_passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _passwordError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16.0),
              // Login buttons with responsive layout
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: isWideScreen ? size.width * 0.15 : size.width * 0.4,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginUser, // Disable button when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.login, size: 20, color: Colors.white),
                            SizedBox(width: 10),
                            Text("Login", style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: isWideScreen ? size.width * 0.15 : size.width * 0.4,
                      child: ElevatedButton(
                        onPressed: isGoogleLoading ? null : handleGoogleLogin, // Disable button when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isGoogleLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.google, size: 20, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text("Google", style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Guest user button with web-specific width
              Container(
                width: isWideScreen ? size.width * 0.3 : double.infinity,
                child: ElevatedButton(
                  onPressed: browseAsGuest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Guest user",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Register and forgot password links
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/register'),
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: MouseRegion(
                  cursor: kIsWeb
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: sendPasswordResetEmail,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
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




// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//
//   // Email regex pattern
//   final RegExp _emailRegExp = RegExp(
//     r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
//   );
//
//   String? _emailError;
//   String? _passwordError;
//
//   // Login method with validation
//   Future<void> loginUser() async {
//     String email = _emailController.text.trim();
//     String password = _passwordController.text.trim();
//
//     // Reset previous error messages
//     setState(() {
//       _emailError = null;
//       _passwordError = null;
//     });
//
//     // Validate email
//     if (email.isEmpty) {
//       setState(() {
//         _emailError = 'Please enter your email address.';
//       });
//       return;
//     }
//     if (!_emailRegExp.hasMatch(email)) {
//       setState(() {
//         _emailError = 'Please enter a valid email address.';
//       });
//       return;
//     }
//
//     // Validate password
//     if (password.isEmpty) {
//       setState(() {
//         _passwordError = 'Please enter your password.';
//       });
//       return;
//     }
//     if (password.length < 6) {
//       setState(() {
//         _passwordError = 'Password must be at least 6 characters long.';
//       });
//       return;
//     }
//
//     try {
//       // Authenticate the user
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // Check if userCredential.user is null
//       if (userCredential.user == null) {
//         throw Exception('User authentication failed.');
//       }
//
//       // Fetch the user document from Firestore
//       DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
//
//       // Check if the user document exists
//       if (!userDoc.exists) {
//         throw Exception('User document not found in Firestore.');
//       }
//
//       // Retrieve the user role
//       String role = userDoc['role'];
//       if (role == 'admin') {
//         Navigator.pushReplacementNamed(context, '/admin');
//       } else if (role == 'seller') {
//         Navigator.pushReplacementNamed(context, '/seller');
//       } else {
//         Navigator.pushReplacementNamed(context, '/customer');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Login failed: ${e.toString()}')),
//       );
//     }
//   }
//
//   Future<UserCredential> signInWithGoogle() async {
//     // Start the Google Sign-In process
//     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//     if (googleUser == null) {
//       // The user canceled the sign-in, handle this case
//       throw FirebaseAuthException(message: 'Sign-in aborted', code: '');
//     }
//
//     // Obtain the authentication details from the request
//     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//     // Create a new credential for Firebase authentication
//     final OAuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );
//
//     // Sign in to Firebase using the Google credential
//     return await _auth.signInWithCredential(credential);
//   }
//
//   // Send password reset email with validation
//   Future<void> sendPasswordResetEmail() async {
//     String email = _emailController.text.trim();
//
//     if (email.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter your email address.')),
//       );
//       return;
//     }
//     if (!_emailRegExp.hasMatch(email)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a valid email address.')),
//       );
//       return;
//     }
//
//     try {
//       await _auth.sendPasswordResetEmail(email: email);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }
//   Future<void> browseAsGuest() async {
//     try {
//       // Sign in anonymously with Firebase
//       await _auth.signInAnonymously();
//       // Navigate to customer screen
//       Navigator.pushReplacementNamed(context, '/customer');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error accessing guest mode: ${e.toString()}')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color.fromRGBO(0, 0, 0, 100), // Dark background color
//
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const SizedBox(height: 20),
//             Center(
//               child: Image.asset(
//                 'assets/images/KicK Vault.png',
//                 height: 228,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: Text(
//                 "Welcome Back!",
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white.withOpacity(0.9),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             TextField(
//               controller: _emailController,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.email, color: Colors.white),
//                 hintText: "Email",
//                 hintStyle: const TextStyle(color: Colors.grey),
//                 filled: true,
//                 fillColor: const Color(0xFF1E1E1E),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             if (_emailError != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: Text(
//                   _emailError!,
//                   style: TextStyle(color: Colors.red, fontSize: 12),
//                 ),
//               ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.lock, color: Colors.white),
//                 hintText: "Password",
//                 hintStyle: const TextStyle(color: Colors.grey),
//                 filled: true,
//                 fillColor: const Color(0xFF1E1E1E),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             if (_passwordError != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: Text(
//                   _passwordError!,
//                   style: TextStyle(color: Colors.red, fontSize: 12),
//                 ),
//               ),
//             const SizedBox(height: 16.0),
//             Container(
//               width: double.infinity, // Ensures it takes up full width
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between buttons
//                 children: [
//                   Container(
//                     width: MediaQuery.of(context).size.width * 0.4, // Adjust width for each button
//                     child: ElevatedButton(
//                       onPressed: loginUser,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: const [
//                           Icon(
//                             Icons.login,
//                             size: 20,
//                             color: Colors.white, // Set the icon color to white
//                           ),
//
//                           SizedBox(width: 10),
//                           Text(
//                             "Login",
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10), // Space between the buttons
//                   Container(
//                     width: MediaQuery.of(context).size.width * 0.4,
//                     child: ElevatedButton(
//                       onPressed: () async {
//                         try {
//                           UserCredential userCredential = await signInWithGoogle();
//                           User? user = userCredential.user;
//
//                           if (user != null) {
//                             DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
//
//                             if (!userDoc.exists) {
//                               throw Exception('User document not found in Firestore.');
//                             }
//
//                             String role = userDoc['role'];
//                             if (role == 'admin') {
//                               Navigator.pushReplacementNamed(context, '/admin');
//                             } else if (role == 'seller') {
//                               Navigator.pushReplacementNamed(context, '/seller');
//                             } else {
//                               Navigator.pushReplacementNamed(context, '/customer');
//                             }
//                           }
//                         } catch (e) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text('Google login failed: ${e.toString()}')),
//                           );
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green, // Google blue color
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             FontAwesomeIcons.google, // Use the Google icon from FontAwesome
//                             size: 20,
//                             color: Colors.white, // Set the icon color to white
//                           ),
//                           const SizedBox(width: 10),
//                           const Text(
//                             "Google",
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: browseAsGuest,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               child: const Text(
//                 "Guest user",
//                 style: TextStyle(fontSize: 18),
//               ),
//             ),
//             const SizedBox(height: 10),
//
//
//
//             TextButton(
//               onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
//               child: const Text(
//                 "Don't have an account? Register",
//                 style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Align(
//               alignment: Alignment.center,
//               child: GestureDetector(
//                 onTap: sendPasswordResetEmail,
//                 child: const Text(
//                   "Forgot Password?",
//                   style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
