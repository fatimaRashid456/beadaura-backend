import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  final String userId;
  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    final url = Uri.parse(
      "http://beadaura-backend.onrender.com/cart/${widget.userId}",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cartItems = data['cartItems'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> deleteFromCart(String cartItemId) async {
    try {
      final url = Uri.parse(
        "http://beadaura-backend.onrender.com/delete-cart-item/$cartItemId",
      );
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          cartItems.removeWhere((item) => item['_id'] == cartItemId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Item removed from cart")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to remove item")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Method to build product image
  Widget buildProductImage(Map<String, dynamic>? product) {
    if (product == null) {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      );
    }

    final imageUrl =
        (product['variants'] != null && product['variants'].isNotEmpty)
        ? product['variants'][0]['imageUrl'] ?? ''
        : '';

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        bottomLeft: Radius.circular(12),
      ),
      child: SizedBox(
        width: 100,
        height: 100,
        child: imageUrl.isNotEmpty
            ? Image.network(
                "http://beadaura-backend.onrender.com$imageUrl",
                fit: BoxFit.cover,
                color: product['outOfStock'] == true ? Colors.grey : null,
                colorBlendMode: product['outOfStock'] == true
                    ? BlendMode.saturation
                    : null,
              )
            : Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lavenderMedium,
        title: const Text("Cart"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartItems[index];
                final product = cartItem['product'];

                return GestureDetector(
                  onTap: product['outOfStock'] == true
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                  child: Card(
                    color: product['outOfStock'] == true
                        ? Colors.grey.shade300
                        : Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.grey.shade300,
                    child: Row(
                      children: [
                        // Product Image
                        buildProductImage(product),
                        const SizedBox(width: 12),
                        // Product Info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['productName'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: product['outOfStock'] == true
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  product['outOfStock'] == true
                                      ? "Out of Stock"
                                      : "₹${product['price'] ?? ''}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.lavenderDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Delete button
                        IconButton(
                          onPressed: () {
                            deleteFromCart(cartItem['_id']);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
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
