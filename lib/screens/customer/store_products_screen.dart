import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/colors.dart';
import 'product_details_screen.dart';

class StoreProductsScreen extends StatefulWidget {
  final String sellerId;
  final String storeName;

  const StoreProductsScreen({
    super.key,
    required this.sellerId,
    required this.storeName,
  });

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  List<dynamic> storeProducts = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchStoreProducts();
  }

  Future<void> fetchStoreProducts() async {
    print("Fetching products for sellerId: ${widget.sellerId}");
    final url =
        "http://beadaura-backend.onrender.com/get-products/${widget.sellerId}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          storeProducts = data['products'] ?? [];
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMessage = "Failed to fetch products: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "Something went wrong: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lavenderMedium,
        title: Text(widget.storeName),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : storeProducts.isEmpty
          ? const Center(child: Text("No products found"))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: storeProducts.length,
              itemBuilder: (context, index) {
                final product = storeProducts[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to ProductDetailsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: product),
                      ),
                    );
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
                          child:
                              (product['variants'] != null &&
                                  product['variants'].isNotEmpty &&
                                  product['variants'][0]['imageUrl'] != null)
                              ? Image.network(
                                  "http://beadaura-backend.onrender.com${product['variants'][0]['imageUrl']}",
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/placeholder.png',
                                  fit: BoxFit.cover,
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
    );
  }
}
