import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/colors.dart';
import 'store_products_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? store;
  bool storeLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStore();
  }

  Future<void> fetchStore() async {
    final sellerId = widget.product['sellerId'];
    if (sellerId == null) {
      setState(() => storeLoading = false);
      return;
    }

    try {
      final url = Uri.parse('http://192.168.1.7:3000/get-seller/$sellerId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          store = {
            '_id': sellerId,
            'name': data['shopName'] ?? data['name'] ?? 'Store',
          };
          storeLoading = false;
        });
      } else {
        setState(() => storeLoading = false);
        print('Failed to fetch store info: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => storeLoading = false);
      print('Error fetching store info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lavenderMedium,
        title: Text(product['productName'] ?? "Product"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey.shade200,
                child:
                    product['imageUrl'] != null &&
                        product['imageUrl'].toString().isNotEmpty
                    ? Image.network(
                        "http://192.168.1.7:3000${product['imageUrl']}",
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // Product Title & Price
              Text(
                product['productName'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Price: ${product['price'] ?? ''}",
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.lavenderDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Product Description
              Text(
                product['description'] ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // Store Info / Button
              storeLoading
                  ? const Center(child: CircularProgressIndicator())
                  : store != null
                  ? GestureDetector(
                      onTap: () {
                        print(
                          "Navigating to store with sellerId: ${widget.product['sellerId']}",
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreProductsScreen(
                              sellerId:
                                  widget.product['sellerId'], // MUST match DB
                              storeName: store?['name'] ?? 'Store',
                            ),
                          ),
                        );
                      },

                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Visit Store: ${store!['name']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lavenderDark,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        // Add to Cart Logic
                      },
                      child: const Text("Add to Cart"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lavenderMedium,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        // Order Now Logic
                      },
                      child: const Text("Order Now"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
