import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kickvault/seller_screen.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'Seller_Drawer.dart';

class SellerFormData {
  String storeName;
  String storeDescription;
  String businessType;
  String bankAccountNumber;
  String bankName;
  String paymentMethod;
  String taxNumber;
  String businessPhone;
  List<String> selectedCategories;
  bool agreesToTerms;
  File? govtId;
  File? addressProof;
  File? storeLogo;

  SellerFormData({
    this.storeName = '',
    this.storeDescription = '',
    this.businessType = 'Sole Proprietorship',
    this.bankAccountNumber = '',
    this.bankName = '',
    this.paymentMethod = 'Bank Transfer',
    this.taxNumber = '',
    this.businessPhone = '',
    this.selectedCategories = const [],
    this.agreesToTerms = false,
    this.govtId,
    this.addressProof,
    this.storeLogo,
  });
}

mixin FormValidationMixin {
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[\d\s-]+$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? validateBankAccount(String? value) {
    if (value == null || value.isEmpty) return 'Bank account number is required';
    if (value.length < 8) return 'Account number is too short';
    return null;
  }

  String? validateTaxNumber(String? value) {
    if (value == null || value.isEmpty) return 'Tax number is required';
    // Add your tax number validation logic
    return null;
  }
}

class SellerRegistrationForm extends StatefulWidget {
  const SellerRegistrationForm({Key? key}) : super(key: key);

  @override
  _SellerRegistrationFormState createState() => _SellerRegistrationFormState();
}

class _SellerRegistrationFormState extends State<SellerRegistrationForm> with FormValidationMixin {


  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isSubmitting = false;
  late SellerFormData formData;
  String userName = '';
  String userEmail = '';


  static const maxFileSize = 5 * 1024 * 1024; // 5MB
  static const allowedFileTypes = ['jpg', 'jpeg', 'png', 'pdf'];

  // Form data
  File? _govtId;
  File? _addressProof;
  File? _storeLogo;
  String _storeName = '';
  String _storeDescription = '';
  String _businessType = 'Sole Proprietorship';
  String _bankAccountNumber = '';
  String _bankName = '';
  String _paymentMethod = 'Bank Transfer';
  bool _agreesToTerms = false;
  String _taxNumber = '';
  List<String> _selectedCategories = [];
  String _businessPhone = '';

  final List<String> _businessTypes = [
    'Sole Proprietorship',
    'Partnership',
    'Corporation',
    'LLC'
  ];

  final List<String> _paymentMethods = [
    'Bank Transfer',
    'PayPal',
    'Stripe',
    'Razor Pay'
  ];

  final List<String> _productCategories = [
    'Sports Shoes',
    'Running Shoes',
    'Walking show',
    'Gym Shoes',
    'Training Shoe',
    'Sneakers',
    'Casual'
  ];


  @override
  @override
  void initState() {
    super.initState();
    formData = SellerFormData();
    fetchUserData();
  }
  Future<bool> _fetchAddressStatus() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists || !userDoc.data().toString().contains('address')) {
      return false; // If no address field exists, return false
    }

    var address = userDoc['address'] as Map<String, dynamic>?;

    return address != null &&
        (address['line1'] ?? '').trim().isNotEmpty &&
        (address['line2'] ?? '').trim().isNotEmpty &&
        (address['city'] ?? '').trim().isNotEmpty &&
        (address['state'] ?? '').trim().isNotEmpty &&
        (address['zipcode'] ?? '').trim().isNotEmpty;
  }



  Future<void> fetchUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        setState(() {
          userName = userDoc['name'] ?? 'No Name'; // Updated field key
          userEmail = userDoc['email'] ?? 'No Email'; // Updated field key
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }




  Future<void> _pickImage(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedFileTypes,
      );

      if (result != null && result.files.isNotEmpty &&
          result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Verify the file exists
        if (!await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(
                  'Selected file does not exist or cannot be accessed')),
            );
          }
          return;
        }

        final size = await file.length();
        if (size > maxFileSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('File size should be less than 5MB')),
            );
          }
          return;
        }

        setState(() {
          switch (type) {
            case 'govtId':
              formData.govtId = file;
              _govtId = file; // Update both state variables
              break;
            case 'addressProof':
              formData.addressProof = file;
              _addressProof = file; // Update both state variables
              break;
            case 'storeLogo':
              formData.storeLogo = file;
              _storeLogo = file; // Update both state variables
              break;
          }
        });
      }
    } catch (e) {
      print('Error in _pickImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }


  Future<String> _uploadFile(File file, String path) async {
    try {
      final fileName = '${DateTime
          .now()
          .millisecondsSinceEpoch}_${path
          .split('/')
          .last}';
      final ref = FirebaseStorage.instance.ref().child('$path/$fileName');

      final metadata = SettableMetadata(
        contentType: file.path.toLowerCase().endsWith('.pdf')
            ? 'application/pdf'
            : 'image/jpeg',
        customMetadata: {
          'uploaded_by': FirebaseAuth.instance.currentUser?.uid ?? 'unknown'
        },
      );

      final uploadTask = ref.putFile(file, metadata);

      // Show upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) *
            100;
        // You could update a progress indicator here
        print('Upload progress: $progress%');
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('File upload error: $e');
      rethrow; // Rethrow to handle in _submitForm
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !_agreesToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields and accept terms')),
      );
      return;
    }

    setState(() => isSubmitting = true); // Show loading indicator

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      _formKey.currentState!.save(); // Save form state

      // Upload required documents
      final futures = <Future<String>>[];
      if (_govtId != null) futures.add(
          _uploadFile(_govtId!, 'seller_documents/govt_ids'));
      if (_addressProof != null) futures.add(
          _uploadFile(_addressProof!, 'seller_documents/address_proofs'));
      if (_storeLogo != null) futures.add(
          _uploadFile(_storeLogo!, 'seller_documents/store_logos'));

      final urls = await Future.wait(futures);
      int urlIndex = 0;

      // Prepare seller data
      final sellerData = {
        'name': userName,
        'email': userEmail,
        'verification': {
          'govt_id_url': _govtId != null ? urls[urlIndex++] : '',
          'address_proof_url': _addressProof != null ? urls[urlIndex++] : '',
          'verification_status': 'pending',
        },
        'business_details': {
          'store_name': _storeName,
          'store_description': _storeDescription,
          'business_type': _businessType,
        },
        'banking_details': {
          'bank_account_number': _bankAccountNumber,
          'bank_name': _bankName,
          'payment_method': _paymentMethod,
        },
        'compliance': {
          'agrees_to_terms': _agreesToTerms,
          'tax_number': _taxNumber,
        },
        'store_profile': {
          'logo_url': _storeLogo != null ? urls[urlIndex] : '',
          'categories': _selectedCategories,
        },
        'contact': {
          'business_email': userEmail,
          'business_phone': _businessPhone,
        },
        'created_at': FieldValue.serverTimestamp(),
        'user_id': user.uid,
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('seller_details').doc(
          user.uid).set(sellerData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Registration submitted successfully!',
              style: TextStyle(color: Colors.black), // Black text
            ),
            backgroundColor: Colors.green, // Green background
            behavior: SnackBarBehavior.floating, // Makes it float above UI
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            duration: const Duration(seconds: 3), // Show for 3 seconds
          ),
        );


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => SellerScreen()), // Navigate to SellerScreen
        );
      }
    } catch (e) {
      print('Error in _submitForm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false); // Stop loading indicator
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black, // Set AppBar color to black
        iconTheme: IconThemeData(color: Colors.white), // Set drawer icon color to white
        title: Text(
          'Seller Registration ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Set text color to white
          ),
        ),
      ),

      drawer: SellerDrawer(currentScreen: 'detail form'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildFormContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return const Center(child: Text("User data not found"));
        }

        var userDoc = snapshot.data!;
        var address = userDoc['address'] as Map<String, dynamic>?;

        // Check if all address fields exist AND are not empty
        bool isAddressComplete = address != null &&
            address.containsKey('line1') && (address['line1'] ?? '').trim().isNotEmpty &&
            address.containsKey('line2') && (address['line2'] ?? '').trim().isNotEmpty &&
            address.containsKey('city') && (address['city'] ?? '').trim().isNotEmpty &&
            address.containsKey('state') && (address['state'] ?? '').trim().isNotEmpty &&
            address.containsKey('zipcode') && (address['zipcode'] ?? '').trim().isNotEmpty;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${userDoc['name'] ?? 'No Name'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userDoc['email'] ?? 'No Email',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, // Makes the button take full width
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditSellerAddress()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAddressComplete ? Colors.green : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14), // Slightly increased padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isAddressComplete ? 'Address Filled' : 'Fill Address Immediately',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

  }



  Widget _buildFormContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100, // Light yellow background for attention
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.orange.shade700, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      "Important Notice",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: "If you need to update any seller information, please complete the Seller Registration Form fully and submit it.\n"
                            "Wait for confirmation and ensure ",
                      ),
                      TextSpan(
                        text: "address details are filled in advance",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: " to avoid delays in registration.",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => SellerRegistrationForm()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                    ),
                    child: const Text(
                      "Update Now",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildFormSection(
            'Verification Documents',
            [
              _buildImageUploadCard(
                'Government ID',
                'Upload a clear photo or PDF of your government-issued ID',
                _govtId,
                    () => _pickImage('govtId'),
                Icons.badge,
              ),
              const SizedBox(height: 16),
              _buildImageUploadCard(
                'Address Proof',
                'Upload an image or PDF document proving your address',
                _addressProof,
                    () => _pickImage('addressProof'),
                Icons.home,
              ),
            ],
          ),

          _buildFormSection(
            'Business Information',
            [
              _buildInputField(
                'Store Name',
                Icons.store,
                    (value) => _storeName = value!,
              ),
              _buildInputField(
                'Store Description',
                Icons.description,
                    (value) => _storeDescription = value!,
                maxLines: 3,
              ),
              _buildCustomDropdown(
                'Business Type',
                _businessTypes,
                _businessType,
                    (value) => setState(() => _businessType = value!),
              ),
            ],
          ),
          _buildFormSection(
            'Banking Details',
            [
              _buildInputField(
                'Bank Account Number',
                Icons.account_balance,
                    (value) => _bankAccountNumber = value!,
                isSecure: true,
              ),
              _buildInputField(
                'Bank Name',
                Icons.account_balance_wallet,
                    (value) => _bankName = value!,
              ),
              _buildCustomDropdown(
                'Payment Method',
                _paymentMethods,
                _paymentMethod,
                    (value) => setState(() => _paymentMethod = value!),
              ),
            ],
          ),
          _buildFormSection(
            'Store Profile',
            [
              _buildImageUploadCard(
                'Store Logo',
                'Upload your store logo',
                _storeLogo,
                    () => _pickImage('storeLogo'),
                Icons.image,
              ),
              const SizedBox(height: 16),
              _buildCategoriesGrid(),
            ],
          ),
          _buildFormSection(
            'Additional Information',
            [
              _buildInputField(
                'Business Phone',
                Icons.phone,
                    (value) => _businessPhone = value!,
                keyboardType: TextInputType.phone,
              ),
              _buildInputField(
                'Tax Number',
                Icons.receipt_long,
                    (value) => _taxNumber = value!,
              ),
              _buildTermsCheckbox(),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<bool>(
            future: _fetchAddressStatus(), // Fetch address status
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator()); // Show loading while fetching
              }

              bool isAddressComplete = snapshot.data ?? false; // Default to false if null

              return _buildSubmitButton(isAddressComplete); // ✅ Pass address status
            },
          ), // ✅ Pass the required argument
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImageUploadCard(String title,
      String subtitle,
      File? file,
      VoidCallback onTap,
      IconData icon,) {
    bool isPdf = file != null && file.path.toLowerCase().endsWith('.pdf');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: file != null
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPdf) ...[
                const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
                const SizedBox(height: 8),
                const Text(
                  'PDF Uploaded',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await OpenFile.open(file.path);
                      if (result.type != ResultType.done) {
                        throw Exception(result.message);
                      }
                    } catch (e) {
                      // Handle error opening the file
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error opening PDF: $e')),
                        );
                      }
                    }
                  },
                  child: Text(
                    'View PDF', style: TextStyle(color: Colors.black),),
                ),
              ] else
                ...[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.error, color: Colors.red[300]),
                          );
                        },
                      ),
                    ),
                  ),
                ],
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label,
      IconData icon,
      Function(String?) onSaved, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        bool isSecure = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        obscureText: isSecure,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildCustomDropdown(String label,
      List<String> items,
      String value,
      Function(String?) onChanged,) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Categories',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _productCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                selectedColor: Colors.green[100],
                checkmarkColor: Colors.green,
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: CheckboxListTile(
        value: _agreesToTerms,
        onChanged: (value) => setState(() => _agreesToTerms = value!),
        title: const Text(
          'I agree to the terms and conditions',
          style: TextStyle(fontSize: 14),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }


  Widget _buildSubmitButton(bool isAddressComplete) {
    return ElevatedButton(
      onPressed: (isSubmitting || !isAddressComplete) ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isSubmitting
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
        "Submit Registration",
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }




}


class EditSellerAddress extends StatefulWidget {
  @override
  _EditSellerAddressState createState() => _EditSellerAddressState();
}

class _EditSellerAddressState extends State<EditSellerAddress> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _line1Controller = TextEditingController();
  final TextEditingController _line2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipcodeController = TextEditingController();

  bool isLoading = true;
  String userName = "";
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    _fetchSellerAddress();
  }

  Future<void> _fetchSellerAddress() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        var address = data['address'] as Map<String, dynamic>?;

        setState(() {
          userName = data['name'] ?? 'No Name';
          userEmail = data['email'] ?? 'No Email';
          if (address != null) {
            _line1Controller.text = address['line1'] ?? '';
            _line2Controller.text = address['line2'] ?? '';
            _cityController.text = address['city'] ?? '';
            _stateController.text = address['state'] ?? '';
            _zipcodeController.text = address['zipcode'] ?? '';
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'address': {
          'line1': _line1Controller.text.trim(),
          'line2': _line2Controller.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zipcode': _zipcodeController.text.trim(),
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      print('Error updating address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update address: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Address',
          style: TextStyle(
            color: Colors.white, // Set text color to white
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildUserInfo(),
              const SizedBox(height: 10),
              _buildTextField('Address Line 1', _line1Controller),
              _buildTextField('Address Line 2', _line2Controller),
              _buildTextField('City', _cityController),
              _buildTextField('State', _stateController),
              _buildTextField('Zipcode', _zipcodeController, keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Address', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editing Address for:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(userEmail, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Please enter $label';
          return null;
        },
      ),
    );
  }
}


