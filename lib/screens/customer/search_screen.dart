import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    loadRecentSearches();
  }

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  Future<void> saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentSearches', recentSearches);
  }

  void performSearch(String query) {
    if (query.isEmpty) return;

    recentSearches.remove(query);
    recentSearches.insert(0, query);

    if (recentSearches.length > 10) {
      recentSearches = recentSearches.sublist(0, 10);
    }

    saveRecentSearches();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lavenderMedium,
        title: TextField(
          controller: searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search products...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          onSubmitted: performSearch,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: recentSearches.isEmpty
            ? const Center(
                child: Text(
                  "Start typing to search...",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recent Searches",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: recentSearches
                        .map(
                          (e) => ActionChip(
                            label: Text(e),
                            onPressed: () => performSearch(e),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  bool loading = true;
  String? errorMessage;

  final String serverUrl = "http://192.168.1.7:3000/get-products";

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(serverUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('products')) {
          allProducts = data['products'] ?? [];
          filterProducts(widget.query);
        } else {
          setState(() {
            loading = false;
            filteredProducts = [];
            errorMessage = "No products found";
          });
        }
      } else {
        setState(() {
          loading = false;
          errorMessage =
              "Failed to fetch products. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "Error fetching products: $e";
      });
    }
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = allProducts;
        loading = false;
      });
      return;
    }

    final lowerQuery = query.toLowerCase().trim();
    final queryWords = lowerQuery.split(RegExp(r'\s+'));

    setState(() {
      filteredProducts = allProducts.where((product) {
        final name = (product['productName'] ?? '').toLowerCase();
        final desc = (product['description'] ?? '').toLowerCase();
        return queryWords.any(
          (word) => name.contains(word) || desc.contains(word),
        );
      }).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lavenderMedium,
        title: Text("Results for '${widget.query}'"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Text(errorMessage!, style: const TextStyle(fontSize: 16)),
            )
          : filteredProducts.isEmpty
          ? const Center(
              child: Text("No products found", style: TextStyle(fontSize: 18)),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigate to product details
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (_) {
                                String imageUrl = product['imageUrl'] ?? "";

                                // FIX URL
                                if (imageUrl.startsWith("/uploads")) {
                                  imageUrl = "http://192.168.1.7:3000$imageUrl";
                                }

                                print("LOADING IMAGE: $imageUrl");

                                return imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
                                    : Image.asset(
                                        'assets/images/placeholder.png',
                                        fit: BoxFit.cover,
                                      );
                              },
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['productName'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${product['price'] ?? ''}",
                                  style: const TextStyle(
                                    color: AppColors.lavenderDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
