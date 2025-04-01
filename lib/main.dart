import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Import Google Fonts
import 'DeliveryPartnerScreen.dart';
import 'admin_screen.dart';
import 'customer_screen.dart';
import 'firebase_options.dart';
import 'seller_screen.dart';
import 'register.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with FirebaseOptions
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firebase App Check for Web
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_KEY'),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kick Vault',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoSansTextTheme(), // ✅ Apply Poppins globally
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminScreen(),
        '/customer': (context) => const CustomerScreen(),
        '/seller': (context) => const SellerScreen(),
        '/login': (context) => const LoginScreen(),
        '/delivery': (context) => const DeliveryPartnerScreen(),
      },
    );
  }
}


