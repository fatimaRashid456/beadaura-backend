import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';
import 'search_screen.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart'; // Updated cart screen
import 'customer_profile_screen.dart';

// Categories list
List<String> categories = [
  "Bracelet",
  "Ring",
  "Necklace",
  "Earrings",
  "Anklet",
  "Custom",
];

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<dynamic> products = [];
  bool loading = true;
  int _selectedIndex = 0;
  String? _selectedCategory;
  String? userId; // logged-in user ID

  final String serverUrl = "http://beadaura-backend.onrender.com/get-products";

  @override
  void initState() {
    super.initState();
    loadUserId();
    fetchProducts();
  }

  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  Future<void> fetchProducts() async {
    try {
      var response = await http.get(Uri.parse(serverUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          products = data['products'] ?? [];
          products.sort((a, b) {
            DateTime dateA = DateTime.parse(a['createdAt']);
            DateTime dateB = DateTime.parse(b['createdAt']);
            return dateB.compareTo(dateA);
          });
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch products")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Home page with products
  Widget buildHomePage() {
    final displayedProducts = _selectedCategory == null
        ? products
        : products
              .where(
                (p) =>
                    (p['category'] ?? '').toString().toLowerCase() ==
                    _selectedCategory!.toLowerCase(),
              )
              .toList();

    return CustomScrollView(
      slivers: [
        // HEADER
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.only(
              top: 45,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.lavenderMedium,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome, Customer",
                  style: TextStyle(
                    fontSize: 22,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: 50,
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.lavenderDark),
                        SizedBox(width: 10),
                        Text(
                          "Search",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 5)),

        // CATEGORIES
        SliverToBoxAdapter(
          child: SizedBox(
            height: 33,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = isSelected
                          ? null
                          : category; // toggle
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.lavenderLight
                          : AppColors.lavenderDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // PRODUCTS GRID
        loading
            ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            : displayedProducts.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Text(
                    "No products available",
                    style: TextStyle(fontSize: 18, color: AppColors.black),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = displayedProducts[index];
                    return ProductCard(product: product);
                  }, childCount: displayedProducts.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),
      ],
    );
  }

  Widget buildCartPage() {
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CartScreen(userId: userId!);
  }

  @override
  Widget build(BuildContext context) {
    // Pages for bottom navigation
    List<Widget> pages = [
      buildHomePage(), // Home
      buildCartPage(), // Cart
      Container(), // Orders placeholder
      Container(), // Premium / Diamonds placeholder
      const CustomerProfileScreen(), // Profile placeholder
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.lavenderDark,
        selectedItemColor: AppColors.lavenderLight,
        unselectedItemColor: AppColors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.diamond), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }
}

// PRODUCT CARD
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final title = product['productName'] ?? '';
    final price = product['price']?.toString() ?? '';
    final imageUrl =
        (product['variants'] != null && product['variants'].isNotEmpty)
        ? product['variants'][0]['imageUrl'] ?? ''
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shadowColor: Colors.grey.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        "http://beadaura-backend.onrender.com$imageUrl",
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // TITLE + PRICE
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Price",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.lavenderDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          price,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.lavenderDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
