import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String? selectedCategoryId;
  String? selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140),
        child: Container(
          color: Colors.teal,
          child: SafeArea(
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 56,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _isSearching = false;
                                  });
                                },
                              )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _isSearching = value.isNotEmpty;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filters Row
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Categories')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)));
                              }
                              var categories = snapshot.data!.docs;
                              return DropdownButtonHideUnderline(
                                child: ButtonTheme(
                                  alignedDropdown: true,
                                  child: DropdownButton<String>(
                                    hint: Text('Category'),
                                    value: selectedCategoryId,
                                    isExpanded: true,
                                    icon: Icon(Icons.arrow_drop_down),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCategoryId = value;
                                      });
                                    },
                                    items: categories.map((category) {
                                      var data =
                                      category.data() as Map<String, dynamic>;
                                      return DropdownMenuItem(
                                        value: category.id,
                                        child:
                                        Text(data['name'] ?? 'Unknown'),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton<String>(
                                hint: Text('Gender'),
                                value: selectedGender,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down),
                                onChanged: (value) {
                                  setState(() {
                                    selectedGender = value;
                                  });
                                },
                                items: [
                                  DropdownMenuItem(
                                      value: "unisex", child: Text("Unisex")),
                                  DropdownMenuItem(
                                      value: "men", child: Text("Men")),
                                  DropdownMenuItem(
                                      value: "women", child: Text("Women")),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (!_isSearching && selectedCategoryId == null && selectedGender == null) {
      return Center(
          child: Text('Start typing or select filters to search products'));
    }

    Query query = FirebaseFirestore.instance
        .collection('Products')
        .where('status', isEqualTo: 'active');

    if (selectedCategoryId != null) {
      query = query.where('category_id', isEqualTo: selectedCategoryId);
    }

    if (selectedGender != null) {
      query = query.where('details.gender', isEqualTo: selectedGender);
    }

    if (_searchQuery.isNotEmpty) {
      query = query
          .orderBy('name')
          .startAt([_searchQuery]).endAt([_searchQuery + '\uf8ff']);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No products found'));
        }

        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var product = snapshot.data!.docs[index];
            var data = product.data() as Map<String, dynamic>;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to product detail screen
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Image.network(
                            data['images'][0],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.error),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Unnamed Product',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '₹${(data['discountedPrice'] ?? data['price']).toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              if (data['hasDiscount'] == true)
                                Text(
                                  '₹${(data['price'] ?? 0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Colors: ${(data['colors'] as List?)?.length ?? 0}',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}