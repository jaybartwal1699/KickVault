import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kickvault/ManageCategories.dart';
import 'Admin_Drawer.dart';
import 'admin_screen.dart';

class AddCategory extends StatefulWidget {
  const AddCategory({Key? key}) : super(key: key);

  @override
  _AddCategoryState createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  Future<void> _addCategory() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);
      try {
        final formData = _formKey.currentState!.value;

        // Create new category document
        await FirebaseFirestore.instance.collection('Categories').add({
          'name': formData['name'],
          'description': formData['description'],
          'created_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reset form after successful addition
        _formKey.currentState!.reset();
      } catch (e) {
        print('Error adding category: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding category: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Styled section header similar to AdminVerifyDeliveryPartnersScreen
  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Add Categories',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),

      // Show Drawer on Mobile, no drawer on Web
      drawer: kIsWeb ? null : const Admin_Drawer(currentScreen: 'Add New Category'),

      // For web, use Row layout with sidebar
      body: kIsWeb
          ? _buildWebLayout(context) // Web layout
          : _buildMobileLayout(context), // Mobile layout
    );
  }

  // Web layout with sidebar
  Widget _buildWebLayout(BuildContext context) {
    return Row(
      children: [
        // Web Sidebar with current screen highlighted
        const WebAdminSidebar(currentScreen: 'Add New Category'),

        // Main content area
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  // Mobile layout (just the main content)
  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: Colors.grey[50], // Light gray background for better aesthetics
      child: _buildMainContent(),
    );
  }

  // Main content area
  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Category',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add new categories for products in your store',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(thickness: 1),

          // Form content in a scrollable container
          Expanded(
            child: SingleChildScrollView(
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Category Information'),

                            const SizedBox(height: 16),

                            // Category Name Field
                            FormBuilderTextField(
                              name: 'name',
                              decoration: InputDecoration(
                                labelText: 'Category Name',
                                labelStyle: TextStyle(color: Colors.grey[700]),
                                hintText: 'Enter category name',
                                prefixIcon: const Icon(Icons.category, color: Colors.black54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.black54, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(errorText: 'Category name is required'),
                                FormBuilderValidators.minLength(2, errorText: 'Name must be at least 2 characters'),
                              ]),
                            ),

                            const SizedBox(height: 24),

                            // Category Description Field
                            FormBuilderTextField(
                              name: 'description',
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle: TextStyle(color: Colors.grey[700]),
                                hintText: 'Enter category description',
                                prefixIcon: const Icon(Icons.description, color: Colors.black54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.black54, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                                alignLabelWithHint: true,
                              ),
                              keyboardType: TextInputType.multiline,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(errorText: 'Description is required'),
                                FormBuilderValidators.minLength(10, errorText: 'Description must be at least 10 characters'),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Information and guidelines card
                    Card(
                      color: Colors.blue[50],
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Guidelines for Categories',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Categories should be clear and specific\n'
                                  '• Avoid creating duplicate categories\n'
                                  '• Use concise but descriptive names\n'
                                  '• Provide a comprehensive description to help users understand the category',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ManageCategories()),
                      );
                    },
                    icon: const Icon(Icons.list, color: Colors.black87),
                    label: const Text('Manage Categories'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black54),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addCategory,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      _isLoading ? 'Adding...' : 'Add Category',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}